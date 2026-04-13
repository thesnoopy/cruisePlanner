import '../../models/documents/document_sync_analysis_result.dart';
import '../../settings/webdav_settings.dart';
import '../../store/document_store.dart';
import 'document_cleanup_planning_service.dart';
import 'document_delete_propagation_planning_service.dart';
import 'document_file_store.dart';
import 'document_local_file_recovery_planning_service.dart';
import 'document_metadata_reconciliation_service.dart';
import 'document_remote_store.dart';
import 'document_sync_planning_service.dart';

class DocumentSyncOrchestrationService {
  DocumentSyncOrchestrationService({
    DocumentStore? documentStore,
    DocumentFileStore? documentFileStore,
    required DocumentRemoteStore remoteStore,
    DocumentMetadataReconciliationService? metadataReconciliationService,
    DocumentSyncPlanningService? syncPlanningService,
    DocumentLocalFileRecoveryPlanningService? localFileRecoveryPlanningService,
    DocumentDeletePropagationPlanningService?
        deletePropagationPlanningService,
    DocumentCleanupPlanningService? cleanupPlanningService,
  })  : _metadataReconciliationService =
            metadataReconciliationService ??
                DocumentMetadataReconciliationService(
                  documentStore: documentStore,
                  remoteStore: remoteStore,
                ),
        _syncPlanningService =
            syncPlanningService ?? const DocumentSyncPlanningService(),
        _localFileRecoveryPlanningService =
            localFileRecoveryPlanningService ??
                DocumentLocalFileRecoveryPlanningService(
                  fileStore: documentFileStore,
                ),
        _deletePropagationPlanningService =
            deletePropagationPlanningService ??
                const DocumentDeletePropagationPlanningService(),
        _cleanupPlanningService =
            cleanupPlanningService ?? const DocumentCleanupPlanningService();

  factory DocumentSyncOrchestrationService.fromSettings({
    DocumentStore? documentStore,
    DocumentFileStore? documentFileStore,
    required WebDavSettings settings,
    DocumentMetadataReconciliationService? metadataReconciliationService,
    DocumentSyncPlanningService? syncPlanningService,
    DocumentLocalFileRecoveryPlanningService? localFileRecoveryPlanningService,
    DocumentDeletePropagationPlanningService?
        deletePropagationPlanningService,
    DocumentCleanupPlanningService? cleanupPlanningService,
  }) {
    return DocumentSyncOrchestrationService(
      documentStore: documentStore,
      documentFileStore: documentFileStore,
      remoteStore: DocumentRemoteStore(settings),
      metadataReconciliationService: metadataReconciliationService,
      syncPlanningService: syncPlanningService,
      localFileRecoveryPlanningService: localFileRecoveryPlanningService,
      deletePropagationPlanningService: deletePropagationPlanningService,
      cleanupPlanningService: cleanupPlanningService,
    );
  }

  final DocumentMetadataReconciliationService _metadataReconciliationService;
  final DocumentSyncPlanningService _syncPlanningService;
  final DocumentLocalFileRecoveryPlanningService
      _localFileRecoveryPlanningService;
  final DocumentDeletePropagationPlanningService
      _deletePropagationPlanningService;
  final DocumentCleanupPlanningService _cleanupPlanningService;

  Future<DocumentSyncAnalysisResult> analyze() async {
    final metadataReconciliation =
        await _metadataReconciliationService.reconcile();
    final syncPlan = _syncPlanningService.planActions(metadataReconciliation);
    final localFileRecoveryPlan =
        await _localFileRecoveryPlanningService.planRecoveries(
          metadataReconciliation,
        );
    final deletePropagationPlan =
        _deletePropagationPlanningService.planPropagations(
          metadataReconciliation,
        );
    final cleanupPlan = _cleanupPlanningService.planCleanupCandidates(
      metadataReconciliation,
    );

    return DocumentSyncAnalysisResult(
      metadataReconciliation: metadataReconciliation,
      syncPlan: syncPlan,
      localFileRecoveryPlan: localFileRecoveryPlan,
      deletePropagationPlan: deletePropagationPlan,
      cleanupPlan: cleanupPlan,
    );
  }
}
