import '../../models/documents/document_cleanup_plan.dart';
import '../../models/documents/document_metadata_reconciliation_result.dart';

class DocumentCleanupPlanningService {
  const DocumentCleanupPlanningService();

  DocumentCleanupPlan planCleanupCandidates(
    DocumentMetadataReconciliationResult reconciliation,
  ) {
    final plannedHardDeletes = <PlannedDocumentHardDelete>[];

    for (final match in reconciliation.both) {
      if (!match.localRecord.deleted || !match.remoteRecord.deleted) {
        continue;
      }

      plannedHardDeletes.add(
        PlannedDocumentHardDelete(
          documentId: match.documentId,
          localRecord: match.localRecord,
          remoteRecord: match.remoteRecord,
        ),
      );
    }

    return DocumentCleanupPlan(
      plannedHardDeletes: List<PlannedDocumentHardDelete>.unmodifiable(
        plannedHardDeletes,
      ),
    );
  }
}
