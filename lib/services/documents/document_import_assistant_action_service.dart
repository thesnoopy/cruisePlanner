import '../../models/documents/document_draft_match_result.dart';
import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_assistant_action.dart';

class DocumentImportAssistantActionService {
  const DocumentImportAssistantActionService();

  DocumentImportAssistantAction buildAction(
    DocumentDraftMatchResult matchResult,
  ) {
    final draft = matchResult.draft;
    switch (matchResult.action) {
      case DocumentDraftMatchAction.manualReview:
      case DocumentDraftMatchAction.documentOnly:
        return DocumentImportAssistantAction.manualReview(
          sourceReference: draft.sourceReference,
        );
      case DocumentDraftMatchAction.useExisting:
      case DocumentDraftMatchAction.createNew:
        break;
    }

    if (draft.targetType != DocumentDraftTargetType.excursion) {
      return DocumentImportAssistantAction.unsupported(
        sourceReference: draft.sourceReference,
      );
    }

    if (matchResult.action == DocumentDraftMatchAction.useExisting) {
      final excursionId = matchResult.matchedItemId;
      if (excursionId == null || excursionId.isEmpty) {
        return DocumentImportAssistantAction.unsupported(
          sourceReference: draft.sourceReference,
        );
      }
      return DocumentImportAssistantAction.editExistingExcursion(
        excursionId: excursionId,
        initialDraft: draft.excursion,
        sourceReference: draft.sourceReference,
      );
    }

    final cruiseId = matchResult.matchedCruiseId;
    if (cruiseId == null || cruiseId.isEmpty) {
      return DocumentImportAssistantAction.unsupported(
        sourceReference: draft.sourceReference,
      );
    }
    return DocumentImportAssistantAction.createNewExcursion(
      cruiseId: cruiseId,
      initialDraft: draft.excursion,
      sourceReference: draft.sourceReference,
    );
  }
}
