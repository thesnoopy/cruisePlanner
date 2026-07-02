import 'package:equatable/equatable.dart';

import 'document_import_draft.dart';
import 'document_import_source_reference.dart';

enum DocumentImportAssistantActionType {
  unsupported,
  manualReview,
  editExistingExcursion,
  createNewExcursion,
}

class DocumentImportAssistantAction extends Equatable {
  final DocumentImportAssistantActionType type;
  final String? excursionId;
  final String? cruiseId;
  final ExcursionImportDraft? initialDraft;
  final DocumentImportSourceReference sourceReference;

  const DocumentImportAssistantAction.unsupported({
    this.sourceReference = const DocumentImportSourceReference(),
  }) : type = DocumentImportAssistantActionType.unsupported,
       excursionId = null,
       cruiseId = null,
       initialDraft = null;

  const DocumentImportAssistantAction.manualReview({
    this.sourceReference = const DocumentImportSourceReference(),
  }) : type = DocumentImportAssistantActionType.manualReview,
       excursionId = null,
       cruiseId = null,
       initialDraft = null;

  const DocumentImportAssistantAction.editExistingExcursion({
    required this.excursionId,
    this.initialDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.editExistingExcursion,
       cruiseId = null;

  const DocumentImportAssistantAction.createNewExcursion({
    required this.cruiseId,
    this.initialDraft,
    required this.sourceReference,
  }) : type = DocumentImportAssistantActionType.createNewExcursion,
       excursionId = null;

  bool get isSupported =>
      type == DocumentImportAssistantActionType.editExistingExcursion ||
      type == DocumentImportAssistantActionType.createNewExcursion;

  bool get requiresManualReview =>
      type == DocumentImportAssistantActionType.manualReview;

  @override
  List<Object?> get props => [
        type,
        excursionId,
        cruiseId,
        initialDraft,
        sourceReference,
      ];
}
