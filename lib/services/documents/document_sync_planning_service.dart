import '../../models/documents/document_metadata_reconciliation_result.dart';
import '../../models/documents/document_sync_plan.dart';

class DocumentSyncPlanningService {
  const DocumentSyncPlanningService();

  DocumentSyncPlan planActions(
    DocumentMetadataReconciliationResult reconciliation,
  ) {
    final uploads = reconciliation.localOnly
        .map(
          (document) => PlannedDocumentUpload(
            localRecord: document,
          ),
        )
        .toList(growable: false);

    final downloads = reconciliation.remoteOnly
        .map(
          (document) => PlannedDocumentDownload(
            remoteRecord: document,
          ),
        )
        .toList(growable: false);

    return DocumentSyncPlan(
      uploads: List<PlannedDocumentUpload>.unmodifiable(uploads),
      downloads: List<PlannedDocumentDownload>.unmodifiable(downloads),
    );
  }
}
