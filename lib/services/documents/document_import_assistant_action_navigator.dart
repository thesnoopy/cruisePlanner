import 'package:flutter/material.dart';

import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_assistant_action.dart';
import '../../models/identifiable.dart';
import '../../screens/details/cruise_edit_screen.dart';
import '../../screens/excursions/excursion_edit_screen.dart';
import '../../screens/route/route_edit_screen.dart';
import '../../screens/travel/travel_edit_screen.dart';

class DocumentImportAssistantActionNavigator {
  const DocumentImportAssistantActionNavigator();

  Future<bool> open(
    BuildContext context,
    DocumentImportAssistantAction action,
  ) {
    final screen = buildScreen(action);
    if (screen == null) {
      return Future.value(false);
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => screen));
    return Future.value(true);
  }

  Widget? buildScreen(DocumentImportAssistantAction action) {
    switch (action.type) {
      case DocumentImportAssistantActionType.unsupported:
      case DocumentImportAssistantActionType.manualReview:
        return null;
      case DocumentImportAssistantActionType.editExistingCruise:
        if (!_hasValue(action.cruiseId)) {
          return null;
        }
        return CruiseEditScreen(
          cruiseId: action.cruiseId!,
          initialDraft: action.initialCruiseDraft,
          sourceReference: action.sourceReference,
        );
      case DocumentImportAssistantActionType.createNewCruise:
        return CruiseEditScreen.create(
          initialDraft: action.initialCruiseDraft,
          sourceReference: action.sourceReference,
        );
      case DocumentImportAssistantActionType.editExistingExcursion:
        if (!_hasValue(action.excursionId)) {
          return null;
        }
        return ExcursionEditScreen(
          excursionId: action.excursionId!,
          initialDraft: action.initialDraft,
          sourceReference: action.sourceReference,
        );
      case DocumentImportAssistantActionType.createNewExcursion:
        if (!_hasValue(action.cruiseId)) {
          return null;
        }
        return ExcursionEditScreen.create(
          cruiseId: action.cruiseId!,
          initialDraft: action.initialDraft,
          sourceReference: action.sourceReference,
        );
      case DocumentImportAssistantActionType.editExistingRouteItem:
        final draftTargetType = action.draftTargetType;
        if (!_hasValue(action.cruiseId) ||
            !_hasValue(action.routeItemId) ||
            !_isRouteItemTarget(draftTargetType)) {
          return null;
        }
        return RouteEditScreen(
          cruiseId: action.cruiseId!,
          routeItemId: action.routeItemId!,
          draftTargetType: draftTargetType,
          initialDraft: action.initialRouteItemDraft,
          sourceReference: action.sourceReference,
        );
      case DocumentImportAssistantActionType.createNewRouteItem:
        final draftTargetType = action.draftTargetType;
        if (!_hasValue(action.cruiseId) ||
            !_isRouteItemTarget(draftTargetType)) {
          return null;
        }
        return RouteEditScreen.create(
          cruiseId: action.cruiseId!,
          routeItemId: Identifiable.newId(),
          draftTargetType: draftTargetType!,
          initialDraft: action.initialRouteItemDraft,
          sourceReference: action.sourceReference,
        );
      case DocumentImportAssistantActionType.editExistingTravel:
        final draftTargetType = action.draftTargetType;
        if (!_hasValue(action.travelItemId) ||
            !_isTravelTarget(draftTargetType)) {
          return null;
        }
        return TravelEditScreen(
          travelItemId: action.travelItemId!,
          draftTargetType: draftTargetType,
          initialDraft: action.initialTravelDraft,
          sourceReference: action.sourceReference,
        );
      case DocumentImportAssistantActionType.createNewTravel:
        final draftTargetType = action.draftTargetType;
        if (!_hasValue(action.cruiseId) || !_isTravelTarget(draftTargetType)) {
          return null;
        }
        return TravelEditScreen.create(
          cruiseId: action.cruiseId!,
          draftTargetType: draftTargetType!,
          initialDraft: action.initialTravelDraft,
          sourceReference: action.sourceReference,
        );
    }
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  bool _isRouteItemTarget(DocumentDraftTargetType? targetType) =>
      targetType != null && targetType.isRouteItemTarget;

  bool _isTravelTarget(DocumentDraftTargetType? targetType) =>
      targetType != null && targetType.isTravelTarget;
}
