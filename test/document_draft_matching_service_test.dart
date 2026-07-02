import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_draft_match_result.dart';
import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/route/port_call_item.dart';
import 'package:cruiseplanner/models/route/route_item.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/services/documents/document_draft_matching_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentDraftMatchingService', () {
    const service = DocumentDraftMatchingService();

    test('matches a cruise when the draft date falls into the cruise period', () {
      final cruises = <Cruise>[
        _buildCruise(
          id: 'cruise-1',
          period: Period(
            start: DateTime(2026, 7, 1),
            end: DateTime(2026, 7, 10),
          ),
          route: <RouteItem>[
            _buildPortCall(
              id: 'route-1',
              date: DateTime(2026, 7, 5),
              portName: 'Nassau',
            ),
          ],
        ),
      ];
      final draft = DocumentImportDraft(
        targetType: DocumentDraftTargetType.excursion,
        excursion: ExcursionImportDraft(
          title: 'Beach shuttle',
          date: DateTime(2026, 7, 5),
          port: 'Nassau',
        ),
      );

      final result = service.match(draft: draft, cruises: cruises);

      expect(result.matchedCruiseId, 'cruise-1');
      expect(result.matchedRouteItemId, 'route-1');
      expect(result.action, DocumentDraftMatchAction.createNew);
    });

    test('matches an existing excursion by date, title and port', () {
      final cruises = <Cruise>[
        _buildCruise(
          id: 'cruise-1',
          period: Period(
            start: DateTime(2026, 7, 1),
            end: DateTime(2026, 7, 10),
          ),
          excursions: <Excursion>[
            Excursion(
              id: 'exc-1',
              title: 'Island Tour',
              date: DateTime(2026, 7, 5),
              port: 'Nassau',
            ),
          ],
          route: <RouteItem>[
            _buildPortCall(
              id: 'route-1',
              date: DateTime(2026, 7, 5),
              portName: 'Nassau',
            ),
          ],
        ),
      ];
      final draft = DocumentImportDraft(
        targetType: DocumentDraftTargetType.excursion,
        excursion: ExcursionImportDraft(
          title: 'Island Tour Voucher',
          date: DateTime(2026, 7, 5),
          port: 'Nassau',
        ),
      );

      final result = service.match(draft: draft, cruises: cruises);

      expect(result.action, DocumentDraftMatchAction.useExisting);
      expect(result.matchedCruiseId, 'cruise-1');
      expect(result.matchedItemId, 'exc-1');
      expect(result.matchedTargetType, DocumentDraftTargetType.excursion);
    });

    test('ambiguous excursion data does not force an existing item match', () {
      final cruises = <Cruise>[
        _buildCruise(
          id: 'cruise-1',
          period: Period(
            start: DateTime(2026, 7, 1),
            end: DateTime(2026, 7, 10),
          ),
          excursions: <Excursion>[
            Excursion(
              id: 'exc-1',
              title: 'City Walk',
              date: DateTime(2026, 7, 5),
              port: 'Nassau',
            ),
          ],
        ),
      ];
      final draft = DocumentImportDraft(
        targetType: DocumentDraftTargetType.excursion,
        excursion: ExcursionImportDraft(
          date: DateTime(2026, 7, 5),
        ),
      );

      final result = service.match(draft: draft, cruises: cruises);

      expect(result.action, DocumentDraftMatchAction.manualReview);
      expect(result.hasExistingTarget, isFalse);
    });

    test('suggests creating a new cruise when no existing cruise matches', () {
      final cruises = <Cruise>[
        _buildCruise(
          id: 'cruise-1',
          title: 'Baltic Summer',
          shipName: 'Ocean Dream',
          period: Period(
            start: DateTime(2026, 8, 1),
            end: DateTime(2026, 8, 10),
          ),
        ),
      ];
      final draft = DocumentImportDraft(
        targetType: DocumentDraftTargetType.cruise,
        cruise: CruiseImportDraft(
          title: 'Autumn Escape',
          shipName: 'Sky Explorer',
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 8),
        ),
      );

      final result = service.match(draft: draft, cruises: cruises);

      expect(result.action, DocumentDraftMatchAction.createNew);
      expect(result.matchedCruiseId, isNull);
      expect(result.matchedTargetType, DocumentDraftTargetType.cruise);
    });

    test('preserves explicit existing ids when they are valid', () {
      final cruises = <Cruise>[
        _buildCruise(
          id: 'cruise-1',
          period: Period(
            start: DateTime(2026, 7, 1),
            end: DateTime(2026, 7, 10),
          ),
          excursions: <Excursion>[
            Excursion(
              id: 'exc-1',
              title: 'Island Tour',
              date: DateTime(2026, 7, 5),
              port: 'Nassau',
            ),
          ],
        ),
      ];
      final draft = DocumentImportDraft(
        targetType: DocumentDraftTargetType.excursion,
        existingCruiseId: 'cruise-1',
        existingItemId: 'exc-1',
        excursion: ExcursionImportDraft(
          title: 'Something else entirely',
          date: DateTime(2026, 8, 1),
        ),
      );

      final result = service.match(draft: draft, cruises: cruises);

      expect(result.action, DocumentDraftMatchAction.useExisting);
      expect(result.matchedCruiseId, 'cruise-1');
      expect(result.matchedItemId, 'exc-1');
      expect(
        result.confidence.reason,
        'Preserved the explicitly referenced excursion id.',
      );
    });
  });
}

Cruise _buildCruise({
  required String id,
  required Period period,
  String title = 'Test Cruise',
  String shipName = 'Test Ship',
  List<Excursion> excursions = const <Excursion>[],
  List<RouteItem> route = const <RouteItem>[],
}) {
  return Cruise(
    id: id,
    title: title,
    ship: Ship(name: shipName),
    period: period,
    excursions: excursions,
    route: route,
  );
}

PortCallItem _buildPortCall({
  required String id,
  required DateTime date,
  required String portName,
}) {
  return PortCallItem(
    id: id,
    date: date,
    portName: portName,
  );
}
