import 'package:equatable/equatable.dart';

import 'document_draft_confidence.dart';
import 'document_draft_target_type.dart';
import 'document_import_draft.dart';

enum DocumentDraftMatchAction {
  useExisting,
  createNew,
  manualReview,
  documentOnly,
}

class DocumentDraftMatchResult extends Equatable {
  final DocumentImportDraft draft;
  final String? matchedCruiseId;
  final String? matchedRouteItemId;
  final String? matchedItemId;
  final DocumentDraftTargetType matchedTargetType;
  final DocumentDraftMatchAction action;
  final DocumentDraftConfidence confidence;

  const DocumentDraftMatchResult({
    required this.draft,
    required this.matchedTargetType,
    required this.action,
    required this.confidence,
    this.matchedCruiseId,
    this.matchedRouteItemId,
    this.matchedItemId,
  });

  bool get hasExistingTarget =>
      action == DocumentDraftMatchAction.useExisting &&
      (matchedCruiseId != null ||
          matchedRouteItemId != null ||
          matchedItemId != null);

  bool get suggestsCreateNew => action == DocumentDraftMatchAction.createNew;

  bool get requiresManualReview =>
      action == DocumentDraftMatchAction.manualReview;

  @override
  List<Object?> get props => [
        draft,
        matchedCruiseId,
        matchedRouteItemId,
        matchedItemId,
        matchedTargetType,
        action,
        confidence,
      ];
}
