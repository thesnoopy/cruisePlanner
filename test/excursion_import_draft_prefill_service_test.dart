import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/services/documents/excursion_import_draft_prefill_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExcursionImportDraftPrefillService', () {
    const service = ExcursionImportDraftPrefillService();

    test('builds a new excursion from draft values', () {
      final excursion = service.buildNewExcursion(
        excursionId: 'exc-new',
        fallbackDate: DateTime(2026, 7, 2, 9, 0),
        draft: ExcursionImportDraft(
          title: '  Snorkeling  ',
          date: DateTime(2026, 7, 5, 14, 30),
          port: ' Cozumel ',
          meetingPoint: ' Pier 4 ',
          notes: ' Bring towels ',
          price: 149.5,
          currency: ' USD ',
        ),
      );

      expect(excursion.id, 'exc-new');
      expect(excursion.title, 'Snorkeling');
      expect(excursion.date, DateTime(2026, 7, 5, 14, 30));
      expect(excursion.port, 'Cozumel');
      expect(excursion.meetingPoint, 'Pier 4');
      expect(excursion.notes, 'Bring towels');
      expect(excursion.price, 149.5);
      expect(excursion.currency, 'USD');
    });

    test('merges draft values conservatively into an existing excursion', () {
      final excursion = service.mergeIntoExisting(
        base: Excursion(
          id: 'exc-1',
          title: 'Existing title',
          date: DateTime(2026, 7, 3, 8, 0),
          port: '',
          meetingPoint: null,
          notes: 'Keep this note',
          price: 79,
          currency: null,
        ),
        draft: ExcursionImportDraft(
          title: 'Draft title',
          date: DateTime(2026, 7, 6, 11, 0),
          port: 'Nassau',
          meetingPoint: 'Terminal A',
          notes: 'Draft note',
          price: 129,
          currency: 'BSD',
        ),
      );

      expect(excursion.title, 'Existing title');
      expect(excursion.date, DateTime(2026, 7, 3, 8, 0));
      expect(excursion.port, 'Nassau');
      expect(excursion.meetingPoint, 'Terminal A');
      expect(excursion.notes, 'Keep this note');
      expect(excursion.price, 79);
      expect(excursion.currency, 'BSD');
    });
  });
}
