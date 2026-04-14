import '../models/cruise.dart';
import '../models/excursion.dart';
import '../models/route/port_call_item.dart';
import '../models/route/route_item.dart';
import '../models/route/sea_day_item.dart';
import '../models/travel/base_travel.dart';
import '../models/travel/cruise_check_in_item.dart';
import '../models/travel/cruise_check_out_item.dart';
import '../models/travel/flight_item.dart';
import '../models/travel/hotel_item.dart';
import '../models/travel/rental_car_item.dart';
import '../models/travel/train_item.dart';
import '../models/travel/transfer_item.dart';

List<Cruise> normalizeCruisePersistenceData(
  List<Cruise> cruises, {
  required DateTime nowUtc,
}) {
  return List<Cruise>.unmodifiable(
    cruises.map((cruise) => _normalizeCruise(cruise, nowUtc: nowUtc)),
  );
}

Cruise _normalizeCruise(Cruise cruise, {required DateTime nowUtc}) {
  return cruise.copyWith(
    updatedAtUtc: cruise.updatedAtUtc ?? nowUtc,
    deletedAtUtc: cruise.deletedAtUtc,
    excursions: List<Excursion>.unmodifiable(
      cruise.excursions
          .map((excursion) => _normalizeExcursion(excursion, nowUtc: nowUtc)),
    ),
    travel: List<TravelItem>.unmodifiable(
      cruise.travel.map((item) => _normalizeTravelItem(item, nowUtc: nowUtc)),
    ),
    route: List<RouteItem>.unmodifiable(
      cruise.route.map((item) => _normalizeRouteItem(item, nowUtc: nowUtc)),
    ),
  );
}

Excursion _normalizeExcursion(Excursion excursion, {required DateTime nowUtc}) {
  return excursion.copyWith(
    updatedAtUtc: excursion.updatedAtUtc ?? nowUtc,
    deletedAtUtc: excursion.deletedAtUtc,
  );
}

TravelItem _normalizeTravelItem(TravelItem item, {required DateTime nowUtc}) {
  final updatedAtUtc = item.updatedAtUtc ?? nowUtc;
  final deletedAtUtc = item.deletedAtUtc;

  if (item is FlightItem) {
    return item.copyWith(
      updatedAtUtc: updatedAtUtc,
      deletedAtUtc: deletedAtUtc,
    );
  }
  if (item is TrainItem) {
    return item.copyWith(
      updatedAtUtc: updatedAtUtc,
      deletedAtUtc: deletedAtUtc,
    );
  }
  if (item is TransferItem) {
    return item.copyWith(
      updatedAtUtc: updatedAtUtc,
      deletedAtUtc: deletedAtUtc,
    );
  }
  if (item is RentalCarItem) {
    return item.copyWith(
      updatedAtUtc: updatedAtUtc,
      deletedAtUtc: deletedAtUtc,
    );
  }
  if (item is HotelItem) {
    return item.copyWith(
      updatedAtUtc: updatedAtUtc,
      deletedAtUtc: deletedAtUtc,
    );
  }
  if (item is CruiseCheckIn) {
    return item.copyWith(
      updatedAtUtc: updatedAtUtc,
      deletedAtUtc: deletedAtUtc,
    );
  }
  if (item is CruiseCheckOut) {
    return item.copyWith(
      updatedAtUtc: updatedAtUtc,
      deletedAtUtc: deletedAtUtc,
    );
  }

  throw UnsupportedError('Unsupported travel item type: ${item.runtimeType}');
}

RouteItem _normalizeRouteItem(RouteItem item, {required DateTime nowUtc}) {
  final updatedAtUtc = item.updatedAtUtc ?? nowUtc;
  final deletedAtUtc = item.deletedAtUtc;

  if (item is SeaDayItem) {
    return item.copyWith(
      updatedAtUtc: updatedAtUtc,
      deletedAtUtc: deletedAtUtc,
    );
  }
  if (item is PortCallItem) {
    return item.copyWith(
      updatedAtUtc: updatedAtUtc,
      deletedAtUtc: deletedAtUtc,
    );
  }

  throw UnsupportedError('Unsupported route item type: ${item.runtimeType}');
}
