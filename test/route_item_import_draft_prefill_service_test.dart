import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/route/port_call_item.dart';
import 'package:cruiseplanner/models/route/sea_day_item.dart';
import 'package:cruiseplanner/services/documents/route_item_import_draft_prefill_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteItemImportDraftPrefillService', () {
    const service = RouteItemImportDraftPrefillService();

    test('builds a new port call from draft values', () {
      final item = service.buildNewRouteItem(
        routeItemId: 'port-1',
        fallbackDate: DateTime(2026, 7, 2),
        targetType: DocumentDraftTargetType.portCall,
        draft: RouteItemImportDraft(
          date: DateTime(2026, 7, 5),
          portName: '  Palma  ',
          arrival: DateTime(2026, 7, 5, 7, 30),
          departure: DateTime(2026, 7, 5, 18, 0),
          allAboard: DateTime(2026, 7, 5, 17, 30),
          notes: '  Shuttle to old town  ',
        ),
      );

      expect(item, isA<PortCallItem>());
      final portCall = item! as PortCallItem;
      expect(portCall.id, 'port-1');
      expect(portCall.date, DateTime(2026, 7, 5));
      expect(portCall.portName, 'Palma');
      expect(portCall.arrival, DateTime(2026, 7, 5, 7, 30));
      expect(portCall.departure, DateTime(2026, 7, 5, 18, 0));
      expect(portCall.allAboard, DateTime(2026, 7, 5, 17, 30));
      expect(portCall.notes, 'Shuttle to old town');
    });

    test('merges into an existing port call without overwriting non-empty fields', () {
      final item = service.mergeIntoExisting(
        base: PortCallItem(
          id: 'port-1',
          date: DateTime(2026, 7, 3),
          portName: 'Existing port',
          arrival: DateTime(2026, 7, 3, 8, 0),
          departure: null,
          allAboard: null,
          notes: 'Keep note',
        ),
        targetType: DocumentDraftTargetType.portCall,
        draft: RouteItemImportDraft(
          date: DateTime(2026, 7, 6),
          portName: 'Draft port',
          arrival: DateTime(2026, 7, 6, 9, 0),
          departure: DateTime(2026, 7, 6, 18, 0),
          allAboard: DateTime(2026, 7, 6, 17, 30),
          notes: 'Draft note',
        ),
      );

      expect(item, isA<PortCallItem>());
      final portCall = item! as PortCallItem;
      expect(portCall.date, DateTime(2026, 7, 3));
      expect(portCall.portName, 'Existing port');
      expect(portCall.arrival, DateTime(2026, 7, 3, 8, 0));
      expect(portCall.departure, DateTime(2026, 7, 6, 18, 0));
      expect(portCall.allAboard, DateTime(2026, 7, 6, 17, 30));
      expect(portCall.notes, 'Keep note');
    });

    test('unsupported or mismatched route target types are handled safely', () {
      final unsupported = service.buildNewRouteItem(
        routeItemId: 'route-x',
        fallbackDate: DateTime(2026, 7, 2),
        targetType: DocumentDraftTargetType.excursion,
        draft: const RouteItemImportDraft(portName: 'Should not build'),
      );

      final mismatched = service.mergeIntoExisting(
        base: SeaDayItem(
          id: 'sea-1',
          date: DateTime(2026, 7, 4),
          notes: null,
        ),
        targetType: DocumentDraftTargetType.portCall,
        draft: const RouteItemImportDraft(portName: 'Wrong type'),
      );

      expect(unsupported, isNull);
      expect(mismatched, isNull);
    });

    test('builds and merges sea days conservatively', () {
      final built = service.buildNewRouteItem(
        routeItemId: 'sea-2',
        fallbackDate: DateTime(2026, 7, 2),
        targetType: DocumentDraftTargetType.seaDay,
        draft: RouteItemImportDraft(
          date: DateTime(2026, 7, 7),
          notes: '  Quiet day at sea  ',
        ),
      );

      final merged = service.mergeIntoExisting(
        base: SeaDayItem(
          id: 'sea-1',
          date: DateTime(2026, 7, 4),
          notes: 'Keep existing',
        ),
        targetType: DocumentDraftTargetType.seaDay,
        draft: RouteItemImportDraft(
          date: DateTime(2026, 7, 8),
          notes: 'Draft notes',
        ),
      );

      expect(built, isA<SeaDayItem>());
      final builtSeaDay = built! as SeaDayItem;
      expect(builtSeaDay.id, 'sea-2');
      expect(builtSeaDay.date, DateTime(2026, 7, 7));
      expect(builtSeaDay.notes, 'Quiet day at sea');

      expect(merged, isA<SeaDayItem>());
      final mergedSeaDay = merged! as SeaDayItem;
      expect(mergedSeaDay.date, DateTime(2026, 7, 4));
      expect(mergedSeaDay.notes, 'Keep existing');
    });
  });
}
