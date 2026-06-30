import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/models/route/port_call_item.dart';
import 'package:cruiseplanner/models/route/route_item.dart';
import 'package:cruiseplanner/models/route/sea_day_item.dart';
import 'package:cruiseplanner/models/temporal_list_item.dart';
import 'package:cruiseplanner/models/travel/base_travel.dart';
import 'package:cruiseplanner/models/travel/cruise_check_out_item.dart';
import 'package:cruiseplanner/models/travel/flight_item.dart';
import 'package:cruiseplanner/models/travel/hotel_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('temporal status', () {
    test('date-only item is upcoming, current, then past across its day', () {
      final item = SeaDayItem(
        id: 'sea-1',
        date: DateTime(2026, 7, 4),
      );

      expect(
        item.temporalStatusAt(DateTime(2026, 7, 3, 23, 59)),
        TemporalListItemStatus.upcoming,
      );
      expect(
        item.temporalStatusAt(DateTime(2026, 7, 4, 12, 0)),
        TemporalListItemStatus.current,
      );
      expect(
        item.temporalStatusAt(DateTime(2026, 7, 5, 0, 0)),
        TemporalListItemStatus.past,
      );
    });

    test('start-time-only item stays current until the end of its day', () {
      final excursion = Excursion(
        id: 'exc-1',
        title: 'Evening walk',
        date: DateTime(2026, 7, 4, 18, 0),
      );

      expect(
        excursion.temporalStatusAt(DateTime(2026, 7, 4, 17, 59)),
        TemporalListItemStatus.upcoming,
      );
      expect(
        excursion.temporalStatusAt(DateTime(2026, 7, 4, 22, 0)),
        TemporalListItemStatus.current,
      );
      expect(
        excursion.temporalStatusAt(DateTime(2026, 7, 5, 0, 0)),
        TemporalListItemStatus.past,
      );
    });

    test('interval item is upcoming before start, current during, and past at end', () {
      final flight = FlightItem(
        id: 'flight-1',
        start: DateTime(2026, 7, 4, 8, 0),
        end: DateTime(2026, 7, 4, 11, 0),
        from: 'HAM',
        to: 'BCN',
      );

      expect(
        flight.temporalStatusAt(DateTime(2026, 7, 4, 7, 59)),
        TemporalListItemStatus.upcoming,
      );
      expect(
        flight.temporalStatusAt(DateTime(2026, 7, 4, 9, 30)),
        TemporalListItemStatus.current,
      );
      expect(
        flight.temporalStatusAt(DateTime(2026, 7, 4, 11, 0)),
        TemporalListItemStatus.past,
      );
    });

    test('representative route, excursion, and travel subtype mappings use correct end semantics', () {
      final portCall = PortCallItem(
        id: 'port-1',
        date: DateTime(2026, 7, 4),
        portName: 'Palma',
        arrival: DateTime(2026, 7, 4, 8, 0),
        departure: DateTime(2026, 7, 4, 17, 0),
      );
      final excursion = Excursion(
        id: 'exc-1',
        title: 'Old town',
        date: DateTime(2026, 7, 4),
      );
      final hotel = HotelItem(
        id: 'hotel-1',
        start: DateTime(2026, 7, 4, 15, 0),
        end: DateTime(2026, 7, 6, 11, 0),
        from: 'Airport',
        to: 'Hotel',
        name: 'Harbor Hotel',
      );
      final checkOut = CruiseCheckOut(
        id: 'checkout-1',
        start: DateTime(2026, 7, 10, 7, 30),
        end: DateTime(2026, 7, 10, 9, 0),
      );

      expect(
        portCall.temporalStatusAt(DateTime(2026, 7, 4, 16, 59)),
        TemporalListItemStatus.current,
      );
      expect(
        portCall.temporalStatusAt(DateTime(2026, 7, 4, 17, 0)),
        TemporalListItemStatus.past,
      );
      expect(
        excursion.temporalStatusAt(DateTime(2026, 7, 4, 23, 59)),
        TemporalListItemStatus.current,
      );
      expect(
        hotel.temporalStatusAt(DateTime(2026, 7, 5, 12, 0)),
        TemporalListItemStatus.current,
      );
      expect(
        checkOut.temporalStatusAt(DateTime(2026, 7, 10, 9, 0)),
        TemporalListItemStatus.past,
      );
    });
  });

  group('scroll target selection', () {
    test('prefers the first current item', () {
      final items = <RouteItem>[
        SeaDayItem(id: 'sea-1', date: DateTime(2026, 7, 3)),
        PortCallItem(
          id: 'port-1',
          date: DateTime(2026, 7, 4),
          portName: 'Morning Port',
          arrival: DateTime(2026, 7, 4, 8, 0),
          departure: DateTime(2026, 7, 4, 12, 0),
        ),
        PortCallItem(
          id: 'port-2',
          date: DateTime(2026, 7, 4),
          portName: 'Afternoon Port',
          arrival: DateTime(2026, 7, 4, 14, 0),
          departure: DateTime(2026, 7, 4, 18, 0),
        ),
      ];
      final now = DateTime(2026, 7, 4, 9, 0);

      expect(
        temporalScrollTargetIndex<RouteItem>(
          items,
          now,
          (item, currentNow) => item.temporalStatusAt(currentNow),
        ),
        1,
      );
    });

    test('uses the first upcoming item when none is current', () {
      final items = <TravelItem>[
        FlightItem(
          id: 'flight-1',
          start: DateTime(2026, 7, 4, 8, 0),
          end: DateTime(2026, 7, 4, 10, 0),
          from: 'HAM',
          to: 'FCO',
        ),
        FlightItem(
          id: 'flight-2',
          start: DateTime(2026, 7, 4, 14, 0),
          end: DateTime(2026, 7, 4, 16, 0),
          from: 'FCO',
          to: 'ATH',
        ),
      ];
      final now = DateTime(2026, 7, 4, 12, 0);

      expect(
        temporalScrollTargetIndex<TravelItem>(
          items,
          now,
          (item, currentNow) => item.temporalStatusAt(currentNow),
        ),
        1,
      );
    });

    test('returns no target when every item is past or list is empty', () {
      final items = <Excursion>[
        Excursion(
          id: 'exc-1',
          title: 'Morning stop',
          date: DateTime(2026, 7, 4, 8, 0),
        ),
      ];
      final now = DateTime(2026, 7, 5, 0, 0);

      expect(
        temporalScrollTargetIndex<Excursion>(
          items,
          now,
          (item, currentNow) => item.temporalStatusAt(currentNow),
        ),
        isNull,
      );
      expect(
        temporalScrollTargetIndex<Excursion>(
          const <Excursion>[],
          now,
          (item, currentNow) => item.temporalStatusAt(currentNow),
        ),
        isNull,
      );
    });
  });
}
