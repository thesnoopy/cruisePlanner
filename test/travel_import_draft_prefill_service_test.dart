import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/travel/flight_item.dart';
import 'package:cruiseplanner/models/travel/hotel_item.dart';
import 'package:cruiseplanner/services/documents/travel_import_draft_prefill_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TravelImportDraftPrefillService', () {
    const service = TravelImportDraftPrefillService();

    test('builds a new flight from draft values', () {
      final item = service.buildNewTravelItem(
        travelItemId: 'flight-1',
        fallbackStart: DateTime(2026, 7, 2, 9, 0),
        targetType: DocumentDraftTargetType.flight,
        draft: TravelImportDraft(
          start: DateTime(2026, 7, 5, 10, 30),
          end: DateTime(2026, 7, 5, 13, 45),
          from: '  HAM  ',
          to: ' BCN ',
          notes: '  Window seat  ',
          price: 249.99,
          currency: ' EUR ',
          recordLocator: ' ZX81 ',
          carrier: ' Lufthansa ',
          flightNo: ' LH1234 ',
        ),
      );

      expect(item, isA<FlightItem>());
      final flight = item! as FlightItem;
      expect(flight.id, 'flight-1');
      expect(flight.start, DateTime(2026, 7, 5, 10, 30));
      expect(flight.end, DateTime(2026, 7, 5, 13, 45));
      expect(flight.from, 'HAM');
      expect(flight.to, 'BCN');
      expect(flight.notes, 'Window seat');
      expect(flight.price, 249.99);
      expect(flight.currency, 'EUR');
      expect(flight.recordLocator, 'ZX81');
      expect(flight.carrier, 'Lufthansa');
      expect(flight.flightNo, 'LH1234');
    });

    test('builds a new hotel from draft values', () {
      final item = service.buildNewTravelItem(
        travelItemId: 'hotel-1',
        fallbackStart: DateTime(2026, 7, 2, 9, 0),
        targetType: DocumentDraftTargetType.hotel,
        draft: TravelImportDraft(
          start: DateTime(2026, 7, 8, 15, 0),
          end: DateTime(2026, 7, 10, 11, 0),
          from: ' Port ',
          to: ' Downtown ',
          notes: ' Late arrival ',
          price: 399,
          currency: ' USD ',
          recordLocator: ' HTL42 ',
          company: ' Booking Portal ',
          name: ' Harbor View Hotel ',
          location: ' Miami ',
          address: ' 123 Ocean Drive ',
        ),
      );

      expect(item, isA<HotelItem>());
      final hotel = item! as HotelItem;
      expect(hotel.id, 'hotel-1');
      expect(hotel.start, DateTime(2026, 7, 8, 15, 0));
      expect(hotel.end, DateTime(2026, 7, 10, 11, 0));
      expect(hotel.from, 'Port');
      expect(hotel.to, 'Downtown');
      expect(hotel.notes, 'Late arrival');
      expect(hotel.price, 399);
      expect(hotel.currency, 'USD');
      expect(hotel.recordLocator, 'HTL42');
      expect(hotel.company, 'Booking Portal');
      expect(hotel.name, 'Harbor View Hotel');
      expect(hotel.location, 'Miami');
      expect(hotel.address, '123 Ocean Drive');
    });

    test('merges into an existing travel item without overwriting non-empty fields', () {
      final item = service.mergeIntoExisting(
        base: FlightItem(
          id: 'flight-1',
          start: DateTime(2026, 7, 5, 9, 0),
          end: null,
          from: 'Existing origin',
          to: '',
          notes: 'Keep note',
          price: 180,
          currency: null,
          carrier: null,
          flightNo: 'EX100',
          recordLocator: '',
        ),
        targetType: DocumentDraftTargetType.flight,
        draft: TravelImportDraft(
          start: DateTime(2026, 7, 5, 11, 30),
          end: DateTime(2026, 7, 5, 14, 45),
          from: 'Draft origin',
          to: ' Draft destination ',
          notes: ' Draft note ',
          price: 220,
          currency: ' USD ',
          carrier: ' Condor ',
          flightNo: 'CD200',
          recordLocator: ' REC123 ',
        ),
      );

      expect(item, isA<FlightItem>());
      final flight = item! as FlightItem;
      expect(flight.start, DateTime(2026, 7, 5, 9, 0));
      expect(flight.end, DateTime(2026, 7, 5, 14, 45));
      expect(flight.from, 'Existing origin');
      expect(flight.to, 'Draft destination');
      expect(flight.notes, 'Keep note');
      expect(flight.price, 180);
      expect(flight.currency, 'USD');
      expect(flight.carrier, 'Condor');
      expect(flight.flightNo, 'EX100');
      expect(flight.recordLocator, 'REC123');
    });

    test('unsupported or mismatched target types are handled safely', () {
      final unsupported = service.buildNewTravelItem(
        travelItemId: 'x-1',
        fallbackStart: DateTime(2026, 7, 2, 9, 0),
        targetType: DocumentDraftTargetType.excursion,
        draft: const TravelImportDraft(name: 'Should not build'),
      );

      final mismatched = service.mergeIntoExisting(
        base: HotelItem(
          id: 'hotel-1',
          start: DateTime(2026, 7, 8, 15, 0),
          name: 'Existing hotel',
        ),
        targetType: DocumentDraftTargetType.flight,
        draft: const TravelImportDraft(flightNo: 'LH1'),
      );

      expect(unsupported, isNull);
      expect(mismatched, isNull);
    });

    test('trims empty draft strings before applying them', () {
      final item = service.buildNewTravelItem(
        travelItemId: 'hotel-blank',
        fallbackStart: DateTime(2026, 7, 2, 9, 0),
        targetType: DocumentDraftTargetType.hotel,
        draft: TravelImportDraft(
          name: '   ',
          location: '  Barcelona  ',
          notes: '   ',
          currency: '   ',
          address: '   ',
          from: '   ',
          to: '\t',
        ),
      );

      expect(item, isA<HotelItem>());
      final hotel = item! as HotelItem;
      expect(hotel.name, '');
      expect(hotel.location, 'Barcelona');
      expect(hotel.notes, isNull);
      expect(hotel.currency, isNull);
      expect(hotel.address, isNull);
      expect(hotel.from, '');
      expect(hotel.to, '');
    });
  });
}
