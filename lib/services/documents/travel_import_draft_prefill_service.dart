import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_draft.dart';
import '../../models/travel/base_travel.dart';
import '../../models/travel/cruise_check_in_item.dart';
import '../../models/travel/cruise_check_out_item.dart';
import '../../models/travel/flight_item.dart';
import '../../models/travel/hotel_item.dart';
import '../../models/travel/rental_car_item.dart';
import '../../models/travel/train_item.dart';
import '../../models/travel/transfer_item.dart';

class TravelImportDraftPrefillService {
  const TravelImportDraftPrefillService();

  TravelItem? buildNewTravelItem({
    required String travelItemId,
    required DateTime fallbackStart,
    required DocumentDraftTargetType targetType,
    TravelImportDraft? draft,
  }) {
    final start = _prefillStart(draft, fallbackStart);

    switch (targetType) {
      case DocumentDraftTargetType.flight:
        return FlightItem(
          id: travelItemId,
          start: start,
          end: draft?.end,
          from: _initialText(draft?.from),
          to: _initialText(draft?.to),
          notes: _normalizeText(draft?.notes),
          price: draft?.price,
          currency: _normalizeText(draft?.currency),
          carrier: _normalizeText(draft?.carrier),
          flightNo: _normalizeText(draft?.flightNo),
          recordLocator: _normalizeText(draft?.recordLocator),
        );
      case DocumentDraftTargetType.train:
        return TrainItem(
          id: travelItemId,
          start: start,
          end: draft?.end,
          from: _initialText(draft?.from),
          to: _initialText(draft?.to),
          notes: _normalizeText(draft?.notes),
          price: draft?.price,
          currency: _normalizeText(draft?.currency),
          recordLocator: _normalizeText(draft?.recordLocator),
        );
      case DocumentDraftTargetType.transfer:
        return TransferItem(
          id: travelItemId,
          start: start,
          end: draft?.end,
          from: _initialText(draft?.from),
          to: _initialText(draft?.to),
          notes: _normalizeText(draft?.notes),
          price: draft?.price,
          currency: _normalizeText(draft?.currency),
          mode: _parseTransferMode(draft?.mode),
          recordLocator: _normalizeText(draft?.recordLocator),
        );
      case DocumentDraftTargetType.rentalCar:
        return RentalCarItem(
          id: travelItemId,
          start: start,
          end: draft?.end,
          from: _initialText(draft?.from),
          to: _initialText(draft?.to),
          notes: _normalizeText(draft?.notes),
          price: draft?.price,
          currency: _normalizeText(draft?.currency),
          company: _normalizeText(draft?.company),
          recordLocator: _normalizeText(draft?.recordLocator),
        );
      case DocumentDraftTargetType.hotel:
        return HotelItem(
          id: travelItemId,
          start: start,
          end: draft?.end,
          from: _initialText(draft?.from),
          to: _initialText(draft?.to),
          notes: _normalizeText(draft?.notes),
          price: draft?.price,
          currency: _normalizeText(draft?.currency),
          company: _normalizeText(draft?.company),
          name: _initialText(draft?.name),
          location: _initialText(draft?.location),
          address: _normalizeText(draft?.address),
          recordLocator: _normalizeText(draft?.recordLocator),
        );
      case DocumentDraftTargetType.cruiseCheckIn:
        return CruiseCheckIn(
          id: travelItemId,
          start: start,
          end: draft?.end,
          from: _initialText(draft?.from),
          to: _initialText(_firstText(draft?.to, draft?.location)),
          notes: _normalizeText(draft?.notes),
          price: draft?.price,
          currency: _normalizeText(draft?.currency),
          recordLocator: _normalizeText(draft?.recordLocator),
        );
      case DocumentDraftTargetType.cruiseCheckOut:
        return CruiseCheckOut(
          id: travelItemId,
          start: start,
          end: draft?.end,
          from: _initialText(_firstText(draft?.from, draft?.location)),
          to: _initialText(draft?.to),
          notes: _normalizeText(draft?.notes),
          price: draft?.price,
          currency: _normalizeText(draft?.currency),
          recordLocator: _normalizeText(draft?.recordLocator),
        );
      case DocumentDraftTargetType.cruise:
      case DocumentDraftTargetType.excursion:
      case DocumentDraftTargetType.portCall:
      case DocumentDraftTargetType.seaDay:
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        return null;
    }
  }

  TravelItem? mergeIntoExisting({
    required TravelItem base,
    required DocumentDraftTargetType targetType,
    TravelImportDraft? draft,
  }) {
    if (!_matchesTargetType(base.kind, targetType)) {
      return null;
    }

    if (draft == null) {
      return base;
    }

    switch (targetType) {
      case DocumentDraftTargetType.flight:
        final item = base as FlightItem;
        return item.copyWith(
          end: item.end ?? draft.end,
          from: _prefillOptionalText(item.from, draft.from),
          to: _prefillOptionalText(item.to, draft.to),
          notes: _prefillOptionalText(item.notes, draft.notes),
          price: item.price ?? draft.price,
          currency: _prefillOptionalText(item.currency, draft.currency),
          carrier: _prefillOptionalText(item.carrier, draft.carrier),
          flightNo: _prefillOptionalText(item.flightNo, draft.flightNo),
          recordLocator:
              _prefillOptionalText(item.recordLocator, draft.recordLocator),
        );
      case DocumentDraftTargetType.train:
        final item = base as TrainItem;
        return item.copyWith(
          end: item.end ?? draft.end,
          from: _prefillOptionalText(item.from, draft.from),
          to: _prefillOptionalText(item.to, draft.to),
          notes: _prefillOptionalText(item.notes, draft.notes),
          price: item.price ?? draft.price,
          currency: _prefillOptionalText(item.currency, draft.currency),
          recordLocator:
              _prefillOptionalText(item.recordLocator, draft.recordLocator),
        );
      case DocumentDraftTargetType.transfer:
        final item = base as TransferItem;
        return item.copyWith(
          end: item.end ?? draft.end,
          from: _prefillOptionalText(item.from, draft.from),
          to: _prefillOptionalText(item.to, draft.to),
          notes: _prefillOptionalText(item.notes, draft.notes),
          price: item.price ?? draft.price,
          currency: _prefillOptionalText(item.currency, draft.currency),
          mode: item.mode ?? _parseTransferMode(draft.mode),
          recordLocator:
              _prefillOptionalText(item.recordLocator, draft.recordLocator),
        );
      case DocumentDraftTargetType.rentalCar:
        final item = base as RentalCarItem;
        return item.copyWith(
          end: item.end ?? draft.end,
          from: _prefillOptionalText(item.from, draft.from),
          to: _prefillOptionalText(item.to, draft.to),
          notes: _prefillOptionalText(item.notes, draft.notes),
          price: item.price ?? draft.price,
          currency: _prefillOptionalText(item.currency, draft.currency),
          company: _prefillOptionalText(item.company, draft.company),
          recordLocator:
              _prefillOptionalText(item.recordLocator, draft.recordLocator),
        );
      case DocumentDraftTargetType.hotel:
        final item = base as HotelItem;
        return item.copyWith(
          end: item.end ?? draft.end,
          from: _prefillOptionalText(item.from, draft.from),
          to: _prefillOptionalText(item.to, draft.to),
          notes: _prefillOptionalText(item.notes, draft.notes),
          price: item.price ?? draft.price,
          currency: _prefillOptionalText(item.currency, draft.currency),
          company: _prefillOptionalText(item.company, draft.company),
          name: _prefillRequiredText(item.name, draft.name),
          location: _prefillOptionalText(item.location, draft.location),
          address: _prefillOptionalText(item.address, draft.address),
          recordLocator:
              _prefillOptionalText(item.recordLocator, draft.recordLocator),
        );
      case DocumentDraftTargetType.cruiseCheckIn:
        final item = base as CruiseCheckIn;
        return item.copyWith(
          end: item.end ?? draft.end,
          from: _prefillOptionalText(item.from, draft.from),
          to: _prefillOptionalText(item.to, _firstText(draft.to, draft.location)),
          notes: _prefillOptionalText(item.notes, draft.notes),
          price: item.price ?? draft.price,
          currency: _prefillOptionalText(item.currency, draft.currency),
          recordLocator:
              _prefillOptionalText(item.recordLocator, draft.recordLocator),
        );
      case DocumentDraftTargetType.cruiseCheckOut:
        final item = base as CruiseCheckOut;
        return item.copyWith(
          end: item.end ?? draft.end,
          from:
              _prefillOptionalText(item.from, _firstText(draft.from, draft.location)),
          to: _prefillOptionalText(item.to, draft.to),
          notes: _prefillOptionalText(item.notes, draft.notes),
          price: item.price ?? draft.price,
          currency: _prefillOptionalText(item.currency, draft.currency),
          recordLocator:
              _prefillOptionalText(item.recordLocator, draft.recordLocator),
        );
      case DocumentDraftTargetType.cruise:
      case DocumentDraftTargetType.excursion:
      case DocumentDraftTargetType.portCall:
      case DocumentDraftTargetType.seaDay:
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        return null;
    }
  }

  bool _matchesTargetType(
    TravelKind kind,
    DocumentDraftTargetType targetType,
  ) {
    switch (targetType) {
      case DocumentDraftTargetType.flight:
        return kind == TravelKind.flight;
      case DocumentDraftTargetType.train:
        return kind == TravelKind.train;
      case DocumentDraftTargetType.transfer:
        return kind == TravelKind.transfer;
      case DocumentDraftTargetType.rentalCar:
        return kind == TravelKind.rentalCar;
      case DocumentDraftTargetType.hotel:
        return kind == TravelKind.hotel;
      case DocumentDraftTargetType.cruiseCheckIn:
        return kind == TravelKind.cruiseCheckIn;
      case DocumentDraftTargetType.cruiseCheckOut:
        return kind == TravelKind.cruiseCheckOut;
      case DocumentDraftTargetType.cruise:
      case DocumentDraftTargetType.excursion:
      case DocumentDraftTargetType.portCall:
      case DocumentDraftTargetType.seaDay:
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        return false;
    }
  }

  DateTime _prefillStart(TravelImportDraft? draft, DateTime fallbackStart) {
    return draft?.start ?? draft?.end ?? fallbackStart;
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

  String? _firstText(String? primary, String? secondary) {
    return _normalizeText(primary) ?? _normalizeText(secondary);
  }

  TransferMode? _parseTransferMode(String? value) {
    final normalized = _normalizeText(value)?.toLowerCase();
    switch (normalized) {
      case 'shuttle':
        return TransferMode.shuttle;
      case 'taxi':
        return TransferMode.taxi;
      case 'private driver':
      case 'private-driver':
      case 'private_driver':
      case 'privatedriver':
        return TransferMode.privateDriver;
      case 'ride share':
      case 'ride-share':
      case 'ride_share':
      case 'rideshare':
        return TransferMode.rideshare;
    }
    return null;
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
