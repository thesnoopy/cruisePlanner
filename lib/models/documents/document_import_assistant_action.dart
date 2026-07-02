import 'package:equatable/equatable.dart';

import 'document_draft_target_type.dart';
import 'document_import_draft.dart';
import 'document_import_source_reference.dart';

enum DocumentImportAssistantActionType {
  unsupported,
  manualReview,
  editExistingExcursion,
  createNewExcursion,
  editExistingTravel,
  createNewTravel,
}

class DocumentImportAssistantAction extends Equatable {
  final DocumentImportAssistantActionType type;
  final String? excursionId;
  final String? travelItemId;
  final String? cruiseId;
  final DocumentDraftTargetType? draftTargetType;
  final ExcursionImportDraft? initialDraft;
  final TravelImportDraft? initialTravelDraft;
  final DocumentImportSourceReference sourceReference;

  DocumentDraftTargetType? get targetType => draftTargetType;

  const DocumentImportAssistantAction.unsupported({
    this.sourceReference = const DocumentImportSourceReference(),
  }) : type = DocumentImportAssistantActionType.unsupported,
       excursionId = null,
       travelItemId = null,
       cruiseId = null,
       draftTargetType = null,
       initialDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.manualReview({
    this.sourceReference = const DocumentImportSourceReference(),
  }) : type = DocumentImportAssistantActionType.manualReview,
       excursionId = null,
       travelItemId = null,
       cruiseId = null,
       draftTargetType = null,
       initialDraft = null,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.editExistingExcursion({
    required this.excursionId,
    this.initialDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.editExistingExcursion,
       travelItemId = null,
       cruiseId = null,
       draftTargetType = DocumentDraftTargetType.excursion,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.createNewExcursion({
    required this.cruiseId,
    this.initialDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.createNewExcursion,
       excursionId = null,
       travelItemId = null,
       draftTargetType = DocumentDraftTargetType.excursion,
       initialTravelDraft = null;

  const DocumentImportAssistantAction.editExistingTravel({
    required this.travelItemId,
    required this.draftTargetType,
    this.initialTravelDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.editExistingTravel,
       excursionId = null,
       cruiseId = null,
       initialDraft = null;

  const DocumentImportAssistantAction.createNewTravel({
    required this.cruiseId,
    required this.draftTargetType,
    this.initialTravelDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.createNewTravel,
       excursionId = null,
       travelItemId = null,
       initialDraft = null;

  bool get isSupported =>
      type == DocumentImportAssistantActionType.editExistingExcursion ||
      type == DocumentImportAssistantActionType.createNewExcursion ||
      type == DocumentImportAssistantActionType.editExistingTravel ||
      type == DocumentImportAssistantActionType.createNewTravel;

  bool get requiresManualReview =>
      type == DocumentImportAssistantActionType.manualReview;

  @override
  List<Object?> get props => [
        type,
        excursionId,
        travelItemId,
        cruiseId,
        draftTargetType,
        initialDraft,
        initialTravelDraft,
        sourceReference,
      ];
}
