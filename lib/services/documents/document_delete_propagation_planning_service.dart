import '../../models/documents/document_delete_propagation_plan.dart';
import '../../models/documents/document_metadata_reconciliation_result.dart';

class DocumentDeletePropagationPlanningService {
  const DocumentDeletePropagationPlanningService();

  DocumentDeletePropagationPlan planPropagations(
    DocumentMetadataReconciliationResult reconciliation,
  ) {
    final plannedLocalSoftDeletes = <PlannedLocalDocumentSoftDelete>[];
    final plannedRemoteSoftDeletes = <PlannedRemoteDocumentSoftDelete>[];

    for (final match in reconciliation.both) {
      final localDeleted = match.localRecord.deleted;
      final remoteDeleted = match.remoteRecord.deleted;

      if (localDeleted == remoteDeleted) {
        continue;
      }

      if (localDeleted) {
        plannedRemoteSoftDeletes.add(
          PlannedRemoteDocumentSoftDelete(
            documentId: match.documentId,
            localRecord: match.localRecord,
            remoteRecord: match.remoteRecord,
          ),
        );
        continue;
      }

      plannedLocalSoftDeletes.add(
        PlannedLocalDocumentSoftDelete(
          documentId: match.documentId,
          localRecord: match.localRecord,
          remoteRecord: match.remoteRecord,
        ),
      );
    }

    return DocumentDeletePropagationPlan(
      plannedLocalSoftDeletes:
          List<PlannedLocalDocumentSoftDelete>.unmodifiable(
            plannedLocalSoftDeletes,
          ),
      plannedRemoteSoftDeletes:
          List<PlannedRemoteDocumentSoftDelete>.unmodifiable(
            plannedRemoteSoftDeletes,
          ),
    );
  }
}
