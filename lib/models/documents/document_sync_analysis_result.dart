import 'document_cleanup_plan.dart';
import 'document_delete_propagation_plan.dart';
import 'document_local_file_recovery_plan.dart';
import 'document_metadata_reconciliation_result.dart';
import 'document_sync_plan.dart';

class DocumentSyncAnalysisResult {
  const DocumentSyncAnalysisResult({
    required this.metadataReconciliation,
    required this.syncPlan,
    required this.localFileRecoveryPlan,
    required this.deletePropagationPlan,
    required this.cleanupPlan,
  });

  final DocumentMetadataReconciliationResult metadataReconciliation;
  final DocumentSyncPlan syncPlan;
  final DocumentLocalFileRecoveryPlan localFileRecoveryPlan;
  final DocumentDeletePropagationPlan deletePropagationPlan;
  final DocumentCleanupPlan cleanupPlan;

  bool get hasPlannedActions =>
      syncPlan.hasActions ||
      localFileRecoveryPlan.hasRecoveries ||
      deletePropagationPlan.hasActions ||
      cleanupPlan.hasCandidates;
}
