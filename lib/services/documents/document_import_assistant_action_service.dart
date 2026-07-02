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

    if (draft.targetType == DocumentDraftTargetType.excursion) {
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

    if (draft.targetType == DocumentDraftTargetType.cruise) {
      if (matchResult.action == DocumentDraftMatchAction.useExisting) {
        final cruiseId = matchResult.matchedCruiseId;
        if (cruiseId == null || cruiseId.isEmpty) {
          return DocumentImportAssistantAction.unsupported(
            sourceReference: draft.sourceReference,
          );
        }

        return DocumentImportAssistantAction.editExistingCruise(
          cruiseId: cruiseId,
          initialCruiseDraft: draft.cruise,
          sourceReference: draft.sourceReference,
        );
      }

      final cruiseId = matchResult.matchedCruiseId;
      return DocumentImportAssistantAction.createNewCruise(
        cruiseId: cruiseId == null || cruiseId.isEmpty ? null : cruiseId,
        initialCruiseDraft: draft.cruise,
        sourceReference: draft.sourceReference,
      );
    }

    if (draft.targetType.isRouteItemTarget) {
      if (matchResult.action == DocumentDraftMatchAction.useExisting) {
        final cruiseId = matchResult.matchedCruiseId;
        final routeItemId = matchResult.matchedRouteItemId;
        if (cruiseId == null ||
            cruiseId.isEmpty ||
            routeItemId == null ||
            routeItemId.isEmpty) {
          return DocumentImportAssistantAction.unsupported(
            sourceReference: draft.sourceReference,
          );
        }

        return DocumentImportAssistantAction.editExistingRouteItem(
          cruiseId: cruiseId,
          routeItemId: routeItemId,
          draftTargetType: draft.targetType,
          initialRouteItemDraft: draft.routeItem,
          sourceReference: draft.sourceReference,
        );
      }

      final cruiseId = matchResult.matchedCruiseId;
      if (cruiseId == null || cruiseId.isEmpty) {
        return DocumentImportAssistantAction.unsupported(
          sourceReference: draft.sourceReference,
        );
      }

      return DocumentImportAssistantAction.createNewRouteItem(
        cruiseId: cruiseId,
        draftTargetType: draft.targetType,
        initialRouteItemDraft: draft.routeItem,
        sourceReference: draft.sourceReference,
      );
    }

    if (!draft.targetType.isTravelTarget) {
      return DocumentImportAssistantAction.unsupported(
        sourceReference: draft.sourceReference,
      );
    }

    if (matchResult.action == DocumentDraftMatchAction.useExisting) {
      final travelItemId = matchResult.matchedItemId;
      if (travelItemId == null || travelItemId.isEmpty) {
        return DocumentImportAssistantAction.unsupported(
          sourceReference: draft.sourceReference,
        );
      }

      return DocumentImportAssistantAction.editExistingTravel(
        travelItemId: travelItemId,
        draftTargetType: draft.targetType,
        initialTravelDraft: draft.travel,
        sourceReference: draft.sourceReference,
      );
    }

    final cruiseId = matchResult.matchedCruiseId;
    if (cruiseId == null || cruiseId.isEmpty) {
      return DocumentImportAssistantAction.unsupported(
        sourceReference: draft.sourceReference,
      );
    }

    return DocumentImportAssistantAction.createNewTravel(
      cruiseId: cruiseId,
      draftTargetType: draft.targetType,
      initialTravelDraft: draft.travel,
      sourceReference: draft.sourceReference,
    );
  }
}
