import '../../models/documents/document_import_draft.dart';
import '../../models/excursion.dart';

class ExcursionImportDraftPrefillService {
  const ExcursionImportDraftPrefillService();

  Excursion buildNewExcursion({
    required String excursionId,
    required DateTime fallbackDate,
    ExcursionImportDraft? draft,
  }) {
    final base = Excursion(
      id: excursionId,
      title: '',
      date: fallbackDate,
    );

    return _applyDraft(
      base: base,
      draft: draft,
      allowDateOverride: true,
    );
  }

  Excursion mergeIntoExisting({
    required Excursion base,
    ExcursionImportDraft? draft,
  }) {
    return _applyDraft(
      base: base,
      draft: draft,
      allowDateOverride: false,
    );
  }

  Excursion _applyDraft({
    required Excursion base,
    required ExcursionImportDraft? draft,
    required bool allowDateOverride,
  }) {
    if (draft == null) {
      return base;
    }

    return base.copyWith(
      title: _prefillRequiredText(base.title, draft.title),
      date: allowDateOverride && draft.date != null ? draft.date : base.date,
      port: _prefillOptionalText(base.port, draft.port),
      meetingPoint: _prefillOptionalText(base.meetingPoint, draft.meetingPoint),
      notes: _prefillOptionalText(base.notes, draft.notes),
      price: base.price ?? draft.price,
      currency: _prefillOptionalText(base.currency, draft.currency),
    );
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
