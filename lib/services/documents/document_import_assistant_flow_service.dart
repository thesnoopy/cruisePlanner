import '../../models/cruise.dart';
import '../../models/documents/document_analysis_result.dart';
import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_assistant_action.dart';
import '../../models/documents/document_import_draft.dart';
import '../../models/documents/document_import_source_reference.dart';
import '../../store/cruise_store.dart';
import 'document_draft_matching_service.dart';
import 'document_import_assistant_action_service.dart';

class DocumentImportAssistantFlowService {
  DocumentImportAssistantFlowService({
    CruiseStore? cruiseStore,
    DocumentDraftMatchingService? draftMatchingService,
    DocumentImportAssistantActionService? actionService,
  })  : _cruiseStore = cruiseStore ?? CruiseStore(),
        _draftMatchingService =
            draftMatchingService ?? const DocumentDraftMatchingService(),
        _actionService =
            actionService ?? const DocumentImportAssistantActionService();

  final CruiseStore _cruiseStore;
  final DocumentDraftMatchingService _draftMatchingService;
  final DocumentImportAssistantActionService _actionService;

  Future<DocumentImportAssistantAction> buildAction(
    DocumentAnalysisResult analysisResult,
  ) async {
    final draft = _resolveDraft(analysisResult);
    if (draft == null) {
      return DocumentImportAssistantAction.unsupported(
        sourceReference: analysisResult.sourceReference,
      );
    }

    final cruises = _requiresCruiseLookup(draft)
        ? await _loadCruises()
        : const <Cruise>[];

    final matchResult = _draftMatchingService.match(
      draft: draft,
      cruises: cruises,
    );
    return _actionService.buildAction(matchResult);
  }

  DocumentImportDraft? _resolveDraft(DocumentAnalysisResult analysisResult) {
    final primaryDraft = analysisResult.primaryDraft;
    if (primaryDraft == null) {
      return null;
    }

    final sourceReference = _mergeSourceReference(
      analysisResult.sourceReference,
      primaryDraft.sourceReference,
    );
    if (primaryDraft.sourceReference == sourceReference) {
      return primaryDraft;
    }

    return primaryDraft.copyWith(
      sourceReference: sourceReference,
    );
  }

  bool _requiresCruiseLookup(DocumentImportDraft draft) {
    return draft.targetType != DocumentDraftTargetType.documentOnly &&
        draft.targetType != DocumentDraftTargetType.unknown;
  }

  Future<List<Cruise>> _loadCruises() async {
    if (!_cruiseStore.isLoaded) {
      await _cruiseStore.load();
    }

    return _cruiseStore.activeCruises;
  }

  DocumentImportSourceReference _mergeSourceReference(
    DocumentImportSourceReference analysisSourceReference,
    DocumentImportSourceReference draftSourceReference,
  ) {
    return DocumentImportSourceReference(
      documentId:
          analysisSourceReference.documentId ?? draftSourceReference.documentId,
      pendingShareBatchId: analysisSourceReference.pendingShareBatchId ??
          draftSourceReference.pendingShareBatchId,
      pendingShareItemIndex:
          analysisSourceReference.pendingShareItemIndex ??
              draftSourceReference.pendingShareItemIndex,
    );
  }
}
