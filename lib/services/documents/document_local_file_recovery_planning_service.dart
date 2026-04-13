import '../../models/documents/document_local_file_recovery_plan.dart';
import '../../models/documents/document_metadata_reconciliation_result.dart';
import 'document_file_store.dart';

class DocumentLocalFileRecoveryPlanningService {
  DocumentLocalFileRecoveryPlanningService({
    DocumentFileStore? fileStore,
  }) : _fileStore = fileStore ?? DocumentFileStore();

  final DocumentFileStore _fileStore;

  Future<DocumentLocalFileRecoveryPlan> planRecoveries(
    DocumentMetadataReconciliationResult reconciliation,
  ) async {
    final recoveries = <PlannedLocalDocumentFileRecovery>[];

    for (final match in reconciliation.both) {
      if (match.localRecord.deleted || match.remoteRecord.deleted) {
        continue;
      }

      final fileExists = await _fileStore.fileExists(
        match.localRecord.localRelativePath,
      );
      if (fileExists) {
        continue;
      }

      recoveries.add(
        PlannedLocalDocumentFileRecovery(
          documentId: match.documentId,
          localRecord: match.localRecord,
          remoteRecord: match.remoteRecord,
        ),
      );
    }

    return DocumentLocalFileRecoveryPlan(
      recoveries: List<PlannedLocalDocumentFileRecovery>.unmodifiable(
        recoveries,
      ),
    );
  }
}
