import 'package:equatable/equatable.dart';

import 'document_draft_target_type.dart';
import 'document_import_draft.dart';
import 'document_import_source_reference.dart';

enum DocumentImportAssistantActionType {
  unsupported,
  manualReview,
  editExistingCruise,
  createNewCruise,
  editExistingExcursion,
  createNewExcursion,
  editExistingRouteItem,
  createNewRouteItem,
  editExistingTravel,
  createNewTravel,
}

class DocumentImportAssistantAction extends Equatable {
  final DocumentImportAssistantActionType type;
  final String? excursionId;
  final String? routeItemId;
  final String? travelItemId;
  final String? cruiseId;
  final DocumentDraftTargetType? draftTargetType;
  final CruiseImportDraft? initialCruiseDraft;
  final ExcursionImportDraft? initialDraft;
  final RouteItemImportDraft? initialRouteItemDraft;
  final TravelImportDraft? initialTravelDraft;
  final DocumentImportSourceReference sourceReference;

  DocumentDraftTargetType? get targetType => draftTargetType;

  const DocumentImportAssistantAction.unsupported({
    this.sourceReference = const DocumentImportSourceReference(),
  }) : type = DocumentImportAssistantActionType.unsupported,
       excursionId = null,
       routeItemId = null,
       travelItemId = null,
       cruiseId = null,
       draftTargetType = null,
       initialCruiseDraft = null,
       initialDraft = null,
       initialRouteItemDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.manualReview({
    this.sourceReference = const DocumentImportSourceReference(),
  }) : type = DocumentImportAssistantActionType.manualReview,
       excursionId = null,
       routeItemId = null,
       travelItemId = null,
       cruiseId = null,
       draftTargetType = null,
       initialCruiseDraft = null,
       initialDraft = null,
       initialRouteItemDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.editExistingCruise({
    required this.cruiseId,
    this.initialCruiseDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.editExistingCruise,
       excursionId = null,
       routeItemId = null,
       travelItemId = null,
       draftTargetType = DocumentDraftTargetType.cruise,
       initialDraft = null,
       initialRouteItemDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.createNewCruise({
    this.cruiseId,
    this.initialCruiseDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.createNewCruise,
       excursionId = null,
       routeItemId = null,
       travelItemId = null,
       draftTargetType = DocumentDraftTargetType.cruise,
       initialDraft = null,
       initialRouteItemDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.editExistingExcursion({
    required this.excursionId,
    this.initialDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.editExistingExcursion,
       routeItemId = null,
       travelItemId = null,
       cruiseId = null,
       draftTargetType = DocumentDraftTargetType.excursion,
       initialCruiseDraft = null,
       initialRouteItemDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.createNewExcursion({
    required this.cruiseId,
    this.initialDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.createNewExcursion,
       excursionId = null,
       routeItemId = null,
       travelItemId = null,
       draftTargetType = DocumentDraftTargetType.excursion,
       initialCruiseDraft = null,
       initialRouteItemDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.editExistingRouteItem({
    required this.cruiseId,
    required this.routeItemId,
    required this.draftTargetType,
    this.initialRouteItemDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.editExistingRouteItem,
       excursionId = null,
       travelItemId = null,
       initialCruiseDraft = null,
       initialDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.createNewRouteItem({
    required this.cruiseId,
    required this.draftTargetType,
    this.initialRouteItemDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.createNewRouteItem,
       excursionId = null,
       routeItemId = null,
       travelItemId = null,
       initialCruiseDraft = null,
       initialDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.editExistingTravel({
    required this.travelItemId,
    required this.draftTargetType,
    this.initialTravelDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.editExistingTravel,
       excursionId = null,
       routeItemId = null,
       cruiseId = null,
       initialCruiseDraft = null,
       initialDraft = null,
       initialRouteItemDraft = null;

  const DocumentImportAssistantAction.createNewTravel({
    required this.cruiseId,
    required this.draftTargetType,
    this.initialTravelDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.createNewTravel,
       excursionId = null,
       routeItemId = null,
       travelItemId = null,
       initialCruiseDraft = null,
       initialDraft = null,
       initialRouteItemDraft = null;

  bool get isSupported =>
      type == DocumentImportAssistantActionType.editExistingCruise ||
      type == DocumentImportAssistantActionType.createNewCruise ||
      type == DocumentImportAssistantActionType.editExistingExcursion ||
      type == DocumentImportAssistantActionType.createNewExcursion ||
      type == DocumentImportAssistantActionType.editExistingRouteItem ||
      type == DocumentImportAssistantActionType.createNewRouteItem ||
      type == DocumentImportAssistantActionType.editExistingTravel ||
      type == DocumentImportAssistantActionType.createNewTravel;

  bool get requiresManualReview =>
      type == DocumentImportAssistantActionType.manualReview;

  @override
  List<Object?> get props => [
        type,
        excursionId,
        routeItemId,
        travelItemId,
        cruiseId,
        draftTargetType,
        initialCruiseDraft,
        initialDraft,
        initialRouteItemDraft,
        initialTravelDraft,
        sourceReference,
      ];
}
