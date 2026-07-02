import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_draft.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/route_item.dart';
import '../../models/route/sea_day_item.dart';

class RouteItemImportDraftPrefillService {
  const RouteItemImportDraftPrefillService();

  RouteItem? buildNewRouteItem({
    required String routeItemId,
    required DateTime fallbackDate,
    required DocumentDraftTargetType targetType,
    RouteItemImportDraft? draft,
  }) {
    final date = draft?.date ?? fallbackDate;

    switch (targetType) {
      case DocumentDraftTargetType.portCall:
        return PortCallItem(
          id: routeItemId,
          date: date,
          portName: _initialText(draft?.portName),
          arrival: draft?.arrival,
          departure: draft?.departure,
          allAboard: draft?.allAboard,
          notes: _normalizeText(draft?.notes),
        );
      case DocumentDraftTargetType.seaDay:
        return SeaDayItem(
          id: routeItemId,
          date: date,
          notes: _normalizeText(draft?.notes),
        );
      case DocumentDraftTargetType.cruise:
      case DocumentDraftTargetType.excursion:
      case DocumentDraftTargetType.flight:
      case DocumentDraftTargetType.train:
      case DocumentDraftTargetType.transfer:
      case DocumentDraftTargetType.rentalCar:
      case DocumentDraftTargetType.hotel:
      case DocumentDraftTargetType.cruiseCheckIn:
      case DocumentDraftTargetType.cruiseCheckOut:
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        return null;
    }
  }

  RouteItem? mergeIntoExisting({
    required RouteItem base,
    required DocumentDraftTargetType targetType,
    RouteItemImportDraft? draft,
  }) {
    if (!_matchesTargetType(base, targetType)) {
      return null;
    }

    if (draft == null) {
      return base;
    }

    switch (targetType) {
      case DocumentDraftTargetType.portCall:
        final item = base as PortCallItem;
        return item.copyWith(
          portName: _prefillRequiredText(item.portName, draft.portName),
          arrival: item.arrival ?? draft.arrival,
          departure: item.departure ?? draft.departure,
          allAboard: item.allAboard ?? draft.allAboard,
          notes: _prefillOptionalText(item.notes, draft.notes),
        );
      case DocumentDraftTargetType.seaDay:
        final item = base as SeaDayItem;
        return item.copyWith(
          notes: _prefillOptionalText(item.notes, draft.notes),
        );
      case DocumentDraftTargetType.cruise:
      case DocumentDraftTargetType.excursion:
      case DocumentDraftTargetType.flight:
      case DocumentDraftTargetType.train:
      case DocumentDraftTargetType.transfer:
      case DocumentDraftTargetType.rentalCar:
      case DocumentDraftTargetType.hotel:
      case DocumentDraftTargetType.cruiseCheckIn:
      case DocumentDraftTargetType.cruiseCheckOut:
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        return null;
    }
  }

  bool _matchesTargetType(RouteItem item, DocumentDraftTargetType targetType) {
    switch (targetType) {
      case DocumentDraftTargetType.portCall:
        return item is PortCallItem;
      case DocumentDraftTargetType.seaDay:
        return item is SeaDayItem;
      case DocumentDraftTargetType.cruise:
      case DocumentDraftTargetType.excursion:
      case DocumentDraftTargetType.flight:
      case DocumentDraftTargetType.train:
      case DocumentDraftTargetType.transfer:
      case DocumentDraftTargetType.rentalCar:
      case DocumentDraftTargetType.hotel:
      case DocumentDraftTargetType.cruiseCheckIn:
      case DocumentDraftTargetType.cruiseCheckOut:
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        return false;
    }
  }

  String _initialText(String? draftValue) {
    return _normalizeText(draftValue) ?? '';
  }

  String _prefillRequiredText(String currentValue, String? draftValue) {
    if (_hasText(currentValue)) {
      return currentValue;
    }

    return _normalizeText(draftValue) ?? currentValue;
  }

  String? _prefillOptionalText(String? currentValue, String? draftValue) {
    if (_hasText(currentValue)) {
      return currentValue;
    }

    return _normalizeText(draftValue);
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String? _normalizeText(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
