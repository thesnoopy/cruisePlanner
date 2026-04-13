import '../../models/documents/document_record.dart';
import '../../models/documents/document_sync_analysis_result.dart';
import '../../models/documents/document_sync_execution_result.dart';
import '../../settings/webdav_settings.dart';
import '../../store/document_store.dart';
import 'document_file_store.dart';
import 'document_remote_store.dart';
import 'document_sync_orchestration_service.dart';

class DocumentSyncExecutionService {
  DocumentSyncExecutionService({
    DocumentStore? documentStore,
    DocumentFileStore? documentFileStore,
    required DocumentRemoteStore remoteStore,
    DocumentSyncOrchestrationService? orchestrationService,
  })  : _documentStore = documentStore ?? DocumentStore(),
        _documentFileStore = documentFileStore ?? DocumentFileStore(),
        _remoteStore = remoteStore,
        _orchestrationService =
            orchestrationService ??
            DocumentSyncOrchestrationService(
              documentStore: documentStore,
              documentFileStore: documentFileStore,
              remoteStore: remoteStore,
            );

  factory DocumentSyncExecutionService.fromSettings({
    DocumentStore? documentStore,
    DocumentFileStore? documentFileStore,
    required WebDavSettings settings,
    DocumentSyncOrchestrationService? orchestrationService,
  }) {
    final remoteStore = DocumentRemoteStore(settings);
    return DocumentSyncExecutionService(
      documentStore: documentStore,
      documentFileStore: documentFileStore,
      remoteStore: remoteStore,
      orchestrationService: orchestrationService,
    );
  }

  final DocumentStore _documentStore;
  final DocumentFileStore _documentFileStore;
  final DocumentRemoteStore _remoteStore;
  final DocumentSyncOrchestrationService _orchestrationService;

  Future<DocumentSyncExecutionResult> executePhase3Actions() async {
    try {
      final analysis = await _orchestrationService.analyze();
      return _executeAnalyzedPhase3Actions(analysis);
    } catch (error) {
      return DocumentSyncExecutionResult(
        analysis: null,
        analysisErrorMessage: error.toString(),
        completedUploadDocumentIds: const <String>[],
        completedDownloadDocumentIds: const <String>[],
        failures: const <DocumentSyncExecutionFailure>[],
      );
    }
  }

  Future<DocumentSyncExecutionResult> _executeAnalyzedPhase3Actions(
    DocumentSyncAnalysisResult analysis,
  ) async {
    final completedUploadDocumentIds = <String>[];
    final completedDownloadDocumentIds = <String>[];
    final failures = <DocumentSyncExecutionFailure>[];
    final remoteMetadataById = <String, DocumentRecord>{};
    var canExecuteUploads = true;

    if (analysis.syncPlan.uploads.isNotEmpty) {
      try {
        final remoteDocuments = await _remoteStore.readDocuments();
        for (final document in remoteDocuments) {
          remoteMetadataById[document.id] = document;
        }
      } catch (error) {
        canExecuteUploads = false;
        for (final upload in analysis.syncPlan.uploads) {
          failures.add(
            DocumentSyncExecutionFailure(
              documentId: upload.documentId,
              action: DocumentSyncExecutionAction.upload,
              errorMessage: error.toString(),
            ),
          );
        }
      }
    }

    if (canExecuteUploads) {
      for (final upload in analysis.syncPlan.uploads) {
        try {
          final localFile = await _documentFileStore.resolveAbsoluteFile(
            upload.localRecord.localRelativePath,
          );
          await _remoteStore.uploadDocumentFile(
            document: upload.localRecord,
            localFile: localFile,
          );

          remoteMetadataById[upload.documentId] = upload.localRecord;
          await _remoteStore.writeDocuments(
            _sortDocuments(remoteMetadataById.values),
          );
          completedUploadDocumentIds.add(upload.documentId);
        } catch (error) {
          failures.add(
            DocumentSyncExecutionFailure(
              documentId: upload.documentId,
              action: DocumentSyncExecutionAction.upload,
              errorMessage: error.toString(),
            ),
          );
        }
      }
    }

    for (final download in analysis.syncPlan.downloads) {
      try {
        final destinationFile = await _documentFileStore.resolveAbsoluteFile(
          download.remoteRecord.localRelativePath,
        );
        await _remoteStore.downloadDocumentFile(
          document: download.remoteRecord,
          destinationFile: destinationFile,
        );

        await _documentStore.saveDocument(download.remoteRecord);
        completedDownloadDocumentIds.add(download.documentId);
      } catch (error) {
        failures.add(
          DocumentSyncExecutionFailure(
            documentId: download.documentId,
            action: DocumentSyncExecutionAction.download,
            errorMessage: error.toString(),
          ),
        );
      }
    }

    return DocumentSyncExecutionResult(
      analysis: analysis,
      analysisErrorMessage: null,
      completedUploadDocumentIds: List<String>.unmodifiable(
        completedUploadDocumentIds,
      ),
      completedDownloadDocumentIds: List<String>.unmodifiable(
        completedDownloadDocumentIds,
      ),
      failures: List<DocumentSyncExecutionFailure>.unmodifiable(failures),
    );
  }

  List<DocumentRecord> _sortDocuments(Iterable<DocumentRecord> documents) {
    final sorted = documents.toList(growable: false)
      ..sort((left, right) {
        final updatedAtComparison = right.updatedAt.compareTo(left.updatedAt);
        if (updatedAtComparison != 0) {
          return updatedAtComparison;
        }

        return left.id.compareTo(right.id);
      });
    return List<DocumentRecord>.unmodifiable(sorted);
  }
}
