import 'dart:io';

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
        completedLocalFileRecoveryDocumentIds: const <String>[],
        failures: const <DocumentSyncExecutionFailure>[],
      );
    }
  }

  Future<DocumentSyncExecutionResult> executePhase4LocalFileRecoveries() async {
    try {
      final analysis = await _orchestrationService.analyze();
      return _executeAnalyzedPhase4LocalFileRecoveries(analysis);
    } catch (error) {
      return DocumentSyncExecutionResult(
        analysis: null,
        analysisErrorMessage: error.toString(),
        completedUploadDocumentIds: const <String>[],
        completedDownloadDocumentIds: const <String>[],
        completedLocalFileRecoveryDocumentIds: const <String>[],
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
    await _executeUploads(
      analysis: analysis,
      completedUploadDocumentIds: completedUploadDocumentIds,
      failures: failures,
    );
    await _executeDownloads(
      analysis: analysis,
      completedDownloadDocumentIds: completedDownloadDocumentIds,
      failures: failures,
    );

    return DocumentSyncExecutionResult(
      analysis: analysis,
      analysisErrorMessage: null,
      completedUploadDocumentIds: List<String>.unmodifiable(
        completedUploadDocumentIds,
      ),
      completedDownloadDocumentIds: List<String>.unmodifiable(
        completedDownloadDocumentIds,
      ),
      completedLocalFileRecoveryDocumentIds: const <String>[],
      failures: List<DocumentSyncExecutionFailure>.unmodifiable(failures),
    );
  }

  Future<DocumentSyncExecutionResult> _executeAnalyzedPhase4LocalFileRecoveries(
    DocumentSyncAnalysisResult analysis,
  ) async {
    final completedLocalFileRecoveryDocumentIds = <String>[];
    final failures = <DocumentSyncExecutionFailure>[];
    await _executeLocalFileRecoveries(
      analysis: analysis,
      completedLocalFileRecoveryDocumentIds:
          completedLocalFileRecoveryDocumentIds,
      failures: failures,
    );

    return DocumentSyncExecutionResult(
      analysis: analysis,
      analysisErrorMessage: null,
      completedUploadDocumentIds: const <String>[],
      completedDownloadDocumentIds: const <String>[],
      completedLocalFileRecoveryDocumentIds: List<String>.unmodifiable(
        completedLocalFileRecoveryDocumentIds,
      ),
      failures: List<DocumentSyncExecutionFailure>.unmodifiable(failures),
    );
  }

  Future<void> _executeUploads({
    required DocumentSyncAnalysisResult analysis,
    required List<String> completedUploadDocumentIds,
    required List<DocumentSyncExecutionFailure> failures,
  }) async {
    if (analysis.syncPlan.uploads.isEmpty) {
      return;
    }

    final remoteMetadataById = await _loadRemoteMetadataById(
      analysis: analysis,
      failures: failures,
    );
    if (remoteMetadataById == null) {
      return;
    }

    final successfullyUploadedRecords = <DocumentRecord>[];

    for (final upload in analysis.syncPlan.uploads) {
      try {
        final localFile = await _documentFileStore.resolveAbsoluteFile(
          upload.localRecord.localRelativePath,
        );
        await _remoteStore.uploadDocumentFile(
          document: upload.localRecord,
          localFile: localFile,
        );
        successfullyUploadedRecords.add(upload.localRecord);
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

    if (successfullyUploadedRecords.isEmpty) {
      return;
    }

    for (final document in successfullyUploadedRecords) {
      remoteMetadataById[document.id] = document;
    }

    try {
      await _remoteStore.writeDocuments(_sortDocuments(remoteMetadataById.values));
      completedUploadDocumentIds.addAll(
        successfullyUploadedRecords.map((document) => document.id),
      );
    } catch (error) {
      _addCommitFailures(
        documentIds: successfullyUploadedRecords.map((document) => document.id),
        action: DocumentSyncExecutionAction.upload,
        errorMessage: error.toString(),
        failures: failures,
      );
    }
  }

  Future<void> _executeDownloads({
    required DocumentSyncAnalysisResult analysis,
    required List<String> completedDownloadDocumentIds,
    required List<DocumentSyncExecutionFailure> failures,
  }) async {
    if (analysis.syncPlan.downloads.isEmpty) {
      return;
    }

    final successfullyDownloadedRecords = <DocumentRecord>[];

    for (final download in analysis.syncPlan.downloads) {
      try {
        final destinationFile = await _documentFileStore.resolveAbsoluteFile(
          download.remoteRecord.localRelativePath,
        );
        await _remoteStore.downloadDocumentFile(
          document: download.remoteRecord,
          destinationFile: destinationFile,
        );
        successfullyDownloadedRecords.add(download.remoteRecord);
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

    if (successfullyDownloadedRecords.isEmpty) {
      return;
    }

    try {
      await _documentStore.saveDocuments(successfullyDownloadedRecords);
      completedDownloadDocumentIds.addAll(
        successfullyDownloadedRecords.map((document) => document.id),
      );
    } catch (error) {
      _addCommitFailures(
        documentIds: successfullyDownloadedRecords.map((document) => document.id),
        action: DocumentSyncExecutionAction.download,
        errorMessage: error.toString(),
        failures: failures,
      );
    }
  }

  Future<void> _executeLocalFileRecoveries({
    required DocumentSyncAnalysisResult analysis,
    required List<String> completedLocalFileRecoveryDocumentIds,
    required List<DocumentSyncExecutionFailure> failures,
  }) async {
    if (analysis.localFileRecoveryPlan.recoveries.isEmpty) {
      return;
    }

    for (final recovery in analysis.localFileRecoveryPlan.recoveries) {
      try {
        final destinationFile = await _documentFileStore.resolveAbsoluteFile(
          recovery.localRecord.localRelativePath,
        );
        await _remoteStore.downloadDocumentFile(
          document: recovery.remoteRecord,
          destinationFile: destinationFile,
        );

        if (!await destinationFile.exists()) {
          throw FileSystemException(
            'Document file was not restored.',
            destinationFile.path,
          );
        }

        completedLocalFileRecoveryDocumentIds.add(recovery.documentId);
      } catch (error) {
        failures.add(
          DocumentSyncExecutionFailure(
            documentId: recovery.documentId,
            action: DocumentSyncExecutionAction.localFileRecovery,
            errorMessage: error.toString(),
          ),
        );
      }
    }
  }

  Future<Map<String, DocumentRecord>?> _loadRemoteMetadataById({
    required DocumentSyncAnalysisResult analysis,
    required List<DocumentSyncExecutionFailure> failures,
  }) async {
    try {
      final remoteDocuments = await _remoteStore.readDocuments();
      return {
        for (final document in remoteDocuments) document.id: document,
      };
    } catch (error) {
      _addCommitFailures(
        documentIds: analysis.syncPlan.uploads.map((upload) => upload.documentId),
        action: DocumentSyncExecutionAction.upload,
        errorMessage: error.toString(),
        failures: failures,
      );
      return null;
    }
  }

  void _addCommitFailures({
    required Iterable<String> documentIds,
    required DocumentSyncExecutionAction action,
    required String errorMessage,
    required List<DocumentSyncExecutionFailure> failures,
  }) {
    for (final documentId in documentIds) {
      failures.add(
        DocumentSyncExecutionFailure(
          documentId: documentId,
          action: action,
          errorMessage: errorMessage,
        ),
      );
    }
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
