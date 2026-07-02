import '../../models/cruise.dart';
import '../../models/documents/document_import_draft.dart';
import '../../models/period.dart';
import '../../models/ship.dart';

class CruiseImportDraftPrefillService {
  const CruiseImportDraftPrefillService();

  Cruise? buildNewCruise({
    required String cruiseId,
    required Period fallbackPeriod,
    CruiseImportDraft? draft,
  }) {
    final period = _resolveBuildPeriod(draft, fallbackPeriod);
    if (period == null) {
      return null;
    }

    return Cruise(
      id: cruiseId,
      title: _initialText(draft?.title),
      ship: Ship(
        name: _initialText(draft?.shipName),
        operatorName: _normalizeText(draft?.operatorName),
      ),
      period: period,
      cabinNumber: _normalizeText(draft?.cabinNumber),
      deckNumber: _normalizeText(draft?.deckNumber),
      deckname: _normalizeText(draft?.deckName),
    );
  }

  Cruise mergeIntoExisting({
    required Cruise base,
    CruiseImportDraft? draft,
  }) {
    if (draft == null) {
      return base;
    }

    return base.copyWith(
      title: _prefillRequiredText(base.title, draft.title),
      ship: base.ship.copyWith(
        name: _prefillRequiredText(base.ship.name, draft.shipName),
        operatorName: _prefillOptionalText(
          base.ship.operatorName,
          draft.operatorName,
        ),
      ),
      cabinNumber: _prefillOptionalText(base.cabinNumber, draft.cabinNumber),
      deckNumber: _prefillOptionalText(base.deckNumber, draft.deckNumber),
      deckname: _prefillOptionalText(base.deckname, draft.deckName),
    );
  }

  Period? _resolveBuildPeriod(CruiseImportDraft? draft, Period fallbackPeriod) {
    final fallbackStart = fallbackPeriod.start;
    final fallbackEnd = fallbackPeriod.end;

    if (fallbackEnd.isBefore(fallbackStart) &&
        draft?.startDate == null &&
        draft?.endDate == null) {
      return null;
    }

    final draftStart = draft?.startDate;
    final draftEnd = draft?.endDate;

    if (draftStart != null && draftEnd != null) {
      if (draftEnd.isBefore(draftStart)) {
        return null;
      }

      return Period(start: draftStart, end: draftEnd);
    }

    if (draftStart != null) {
      final end = fallbackEnd.isBefore(draftStart) ? draftStart : fallbackEnd;
      return Period(start: draftStart, end: end);
    }

    if (draftEnd != null) {
      final start = fallbackStart.isAfter(draftEnd) ? draftEnd : fallbackStart;
      return Period(start: start, end: draftEnd);
    }

    if (fallbackEnd.isBefore(fallbackStart)) {
      return null;
    }

    return fallbackPeriod;
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
