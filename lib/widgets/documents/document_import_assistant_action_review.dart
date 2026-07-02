import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_assistant_action.dart';
import '../../models/documents/document_import_draft.dart';
import '../../services/documents/document_import_assistant_action_navigator.dart';

Future<bool> showDocumentImportAssistantActionReviewDialog({
  required BuildContext context,
  required DocumentImportAssistantAction action,
  DocumentImportAssistantActionNavigator navigator =
      const DocumentImportAssistantActionNavigator(),
}) async {
  final shouldOpen = await showDialog<bool>(
    context: context,
    builder: (_) => DocumentImportAssistantActionReview(
      action: action,
      navigator: navigator,
    ),
  );

  if (shouldOpen != true || !context.mounted) {
    return false;
  }

  return navigator.open(context, action);
}

class DocumentImportAssistantActionReview extends StatelessWidget {
  const DocumentImportAssistantActionReview({
    super.key,
    required this.action,
    this.navigator = const DocumentImportAssistantActionNavigator(),
  });

  final DocumentImportAssistantAction action;
  final DocumentImportAssistantActionNavigator navigator;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final canOpen = navigator.canOpen(action);
    final isSupported = action.isSupported && canOpen;
    final summary = _summaryText(action);

    return AlertDialog(
      title: Text(loc.documentImportAssistantReviewTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSupported) ...[
            Text(loc.documentImportAssistantReviewFound),
            if (summary != null) ...[
              const SizedBox(height: 12),
              Text(
                summary,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(_actionLabel(loc, action)),
          ] else if (action.requiresManualReview) ...[
            Text(loc.documentImportAssistantManualReviewMessage),
          ] else ...[
            Text(loc.documentImportAssistantUnsupportedMessage),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.confirmCancel),
        ),
        if (isSupported)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.documentImportAssistantReviewOpen),
          ),
      ],
    );
  }
}

String _actionLabel(
  AppLocalizations loc,
  DocumentImportAssistantAction action,
) {
  switch (action.type) {
    case DocumentImportAssistantActionType.editExistingCruise:
      return loc.documentImportAssistantActionEditExisting(loc.cruise);
    case DocumentImportAssistantActionType.createNewCruise:
      return loc.documentImportAssistantActionCreateNew(loc.cruise);
    case DocumentImportAssistantActionType.editExistingExcursion:
      return loc.documentImportAssistantActionEditExisting(loc.excursion);
    case DocumentImportAssistantActionType.createNewExcursion:
      return loc.documentImportAssistantActionCreateNew(loc.excursion);
    case DocumentImportAssistantActionType.editExistingRouteItem:
      return loc.documentImportAssistantActionEditExisting(
        _targetTypeLabel(loc, action.draftTargetType),
      );
    case DocumentImportAssistantActionType.createNewRouteItem:
      return loc.documentImportAssistantActionCreateNew(
        _targetTypeLabel(loc, action.draftTargetType),
      );
    case DocumentImportAssistantActionType.editExistingTravel:
      return loc.documentImportAssistantActionEditExisting(
        _targetTypeLabel(loc, action.draftTargetType),
      );
    case DocumentImportAssistantActionType.createNewTravel:
      return loc.documentImportAssistantActionCreateNew(
        _targetTypeLabel(loc, action.draftTargetType),
      );
    case DocumentImportAssistantActionType.manualReview:
      return loc.documentImportAssistantManualReviewMessage;
    case DocumentImportAssistantActionType.unsupported:
      return loc.documentImportAssistantUnsupportedMessage;
  }
}

String _targetTypeLabel(
  AppLocalizations loc,
  DocumentDraftTargetType? targetType,
) {
  switch (targetType) {
    case DocumentDraftTargetType.cruise:
      return loc.cruise;
    case DocumentDraftTargetType.excursion:
      return loc.excursion;
    case DocumentDraftTargetType.portCall:
      return loc.harbour;
    case DocumentDraftTargetType.seaDay:
      return loc.seaDay;
    case DocumentDraftTargetType.flight:
      return loc.flight;
    case DocumentDraftTargetType.train:
      return loc.train;
    case DocumentDraftTargetType.transfer:
      return loc.transfer;
    case DocumentDraftTargetType.rentalCar:
      return loc.rentalCar;
    case DocumentDraftTargetType.hotel:
      return loc.hotel;
    case DocumentDraftTargetType.cruiseCheckIn:
      return loc.cruiseCheckIn;
    case DocumentDraftTargetType.cruiseCheckOut:
      return loc.cruiseCheckOut;
    case DocumentDraftTargetType.documentOnly:
    case DocumentDraftTargetType.unknown:
    case null:
      return loc.documentKindUnknown;
  }
}

String? _summaryText(DocumentImportAssistantAction action) {
  switch (action.type) {
    case DocumentImportAssistantActionType.editExistingCruise:
    case DocumentImportAssistantActionType.createNewCruise:
      return _firstNonEmpty([
        action.initialCruiseDraft?.title,
        action.initialCruiseDraft?.shipName,
      ]);
    case DocumentImportAssistantActionType.editExistingExcursion:
    case DocumentImportAssistantActionType.createNewExcursion:
      return _firstNonEmpty([
        action.initialDraft?.title,
        action.initialDraft?.port,
        action.initialDraft?.meetingPoint,
      ]);
    case DocumentImportAssistantActionType.editExistingRouteItem:
    case DocumentImportAssistantActionType.createNewRouteItem:
      return _firstNonEmpty([
        action.initialRouteItemDraft?.portName,
        action.initialRouteItemDraft?.notes,
      ]);
    case DocumentImportAssistantActionType.editExistingTravel:
    case DocumentImportAssistantActionType.createNewTravel:
      return _travelSummary(action.initialTravelDraft);
    case DocumentImportAssistantActionType.manualReview:
    case DocumentImportAssistantActionType.unsupported:
      return null;
  }
}

String? _travelSummary(TravelImportDraft? draft) {
  if (draft == null) {
    return null;
  }

  return _firstNonEmpty([
    draft.name,
    draft.flightNo,
    _travelRoute(draft),
    draft.location,
    draft.address,
    draft.company,
    draft.carrier,
    draft.recordLocator,
  ]);
}

String? _travelRoute(TravelImportDraft draft) {
  final from = draft.from?.trim() ?? '';
  final to = draft.to?.trim() ?? '';
  if (from.isEmpty && to.isEmpty) {
    return null;
  }
  if (from.isEmpty) {
    return to;
  }
  if (to.isEmpty) {
    return from;
  }
  return '$from -> $to';
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }

  return null;
}
