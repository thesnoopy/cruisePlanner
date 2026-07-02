import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/route/sea_day_item.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/models/travel/hotel_item.dart';
import 'package:cruiseplanner/services/documents/cruise_import_draft_prefill_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CruiseImportDraftPrefillService', () {
    const service = CruiseImportDraftPrefillService();

    test('builds a new Cruise from draft values', () {
      final cruise = service.buildNewCruise(
        cruiseId: 'cruise-1',
        fallbackPeriod: Period(
          start: DateTime(2026, 7, 2),
          end: DateTime(2026, 7, 9),
        ),
        draft: CruiseImportDraft(
          title: '  Mediterranean Escape  ',
          shipName: '  AIDAcosma  ',
          operatorName: '  AIDA Cruises  ',
          startDate: DateTime(2026, 7, 5),
          endDate: DateTime(2026, 7, 12),
          cabinNumber: '  12345  ',
          deckNumber: '  14  ',
          deckName: '  Forward  ',
        ),
      );

      expect(cruise, isNotNull);
      expect(cruise!.id, 'cruise-1');
      expect(cruise.title, 'Mediterranean Escape');
      expect(cruise.ship.name, 'AIDAcosma');
      expect(cruise.ship.operatorName, 'AIDA Cruises');
      expect(cruise.period.start, DateTime(2026, 7, 5));
      expect(cruise.period.end, DateTime(2026, 7, 12));
      expect(cruise.cabinNumber, '12345');
      expect(cruise.deckNumber, '14');
      expect(cruise.deckname, 'Forward');
    });

    test('build-new uses safe fallbacks when draft values are missing', () {
      final cruise = service.buildNewCruise(
        cruiseId: 'cruise-2',
        fallbackPeriod: Period(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 10),
        ),
        draft: CruiseImportDraft(
          title: '   ',
          shipName: '   ',
          operatorName: '   ',
          startDate: DateTime(2026, 8, 3),
          cabinNumber: '  8123  ',
          deckName: '   ',
        ),
      );

      expect(cruise, isNotNull);
      expect(cruise!.title, '');
      expect(cruise.ship.name, '');
      expect(cruise.ship.operatorName, isNull);
      expect(cruise.period.start, DateTime(2026, 8, 3));
      expect(cruise.period.end, DateTime(2026, 8, 10));
      expect(cruise.cabinNumber, '8123');
      expect(cruise.deckNumber, isNull);
      expect(cruise.deckname, isNull);
    });

    test('merges into an existing Cruise without overwriting non-empty fields', () {
      final cruise = service.mergeIntoExisting(
        base: Cruise(
          id: 'cruise-3',
          title: 'Existing title',
          ship: const Ship(name: 'Existing ship'),
          period: Period(
            start: DateTime(2026, 9, 1),
            end: DateTime(2026, 9, 8),
          ),
          cabinNumber: '',
          deckNumber: '10',
          deckname: null,
        ),
        draft: CruiseImportDraft(
          title: 'Draft title',
          shipName: 'Draft ship',
          operatorName: 'Draft operator',
          startDate: DateTime(2026, 9, 2),
          endDate: DateTime(2026, 9, 10),
          cabinNumber: '  7001  ',
          deckNumber: '12',
          deckName: '  Aft  ',
        ),
      );

      expect(cruise.title, 'Existing title');
      expect(cruise.ship.name, 'Existing ship');
      expect(cruise.ship.operatorName, 'Draft operator');
      expect(cruise.period.start, DateTime(2026, 9, 1));
      expect(cruise.period.end, DateTime(2026, 9, 8));
      expect(cruise.cabinNumber, '7001');
      expect(cruise.deckNumber, '10');
      expect(cruise.deckname, 'Aft');
    });

    test('merge preserves route, items, documents, and child collections', () {
      final base = Cruise(
        id: 'cruise-4',
        title: '',
        ship: const Ship(name: ''),
        period: Period(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 7),
        ),
        excursions: [
          Excursion(
            id: 'exc-1',
            title: 'Beach transfer',
            date: DateTime(2026, 10, 2),
          ),
        ],
        travel: [
          HotelItem(
            id: 'hotel-1',
            start: DateTime(2026, 9, 30),
            name: 'Harbor View',
          ),
        ],
        route: [
          SeaDayItem(
            id: 'sea-1',
            date: DateTime(2026, 10, 3),
            notes: 'Quiet sea day',
          ),
        ],
        documentIds: const ['doc-1', 'doc-2'],
      );

      final cruise = service.mergeIntoExisting(
        base: base,
        draft: const CruiseImportDraft(
          title: 'Draft cruise',
          shipName: 'Draft ship',
          cabinNumber: '9001',
        ),
      );

      expect(cruise.title, 'Draft cruise');
      expect(cruise.ship.name, 'Draft ship');
      expect(cruise.cabinNumber, '9001');
      expect(cruise.excursions, base.excursions);
      expect(cruise.travel, base.travel);
      expect(cruise.route, base.route);
      expect(cruise.documentIds, base.documentIds);
    });

    test('unsupported or insufficient draft data is handled safely if applicable', () {
      final cruise = service.buildNewCruise(
        cruiseId: 'cruise-5',
        fallbackPeriod: Period(
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 8),
        ),
        draft: CruiseImportDraft(
          title: 'Unsafe draft',
          shipName: 'AIDAluna',
          startDate: DateTime(2026, 11, 9),
          endDate: DateTime(2026, 11, 3),
        ),
      );

      expect(cruise, isNull);
    });
  });
}
