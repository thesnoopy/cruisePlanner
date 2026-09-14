import 'dart:convert';

import 'package:uuid/uuid.dart';

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

const int currentCruiseSchemaVersion = 4;

// Keep the existing exception and sync failure path for unsupported versions.
class RemoteCruiseSchemaTooNewException implements Exception {
  const RemoteCruiseSchemaTooNewException({
    required this.remoteSchemaVersion,
    required this.supportedSchemaVersion,
  });

  final int remoteSchemaVersion;
  final int supportedSchemaVersion;

  @override
  String toString() => 'Remote cruise schema version $remoteSchemaVersion is '
      'newer than supported version $supportedSchemaVersion. Sync aborted.';
}

class MigratedCruiseData {
  final List<Cruise> cruises;
  final bool wasMigrated;

  const MigratedCruiseData(this.cruises, this.wasMigrated);
}

MigratedCruiseData decodeCruisePersistenceData(dynamic decoded) {
  final wrapper = decoded is List
      ? <String, dynamic>{'schemaVersion': 1, 'cruises': decoded}
      : Map<String, dynamic>.from(decoded as Map);
  final version = wrapper['schemaVersion'] ?? 1;
  if (version is! int || version < 1) {
    throw const FormatException('Invalid cruise schema version');
  }
  if (version > currentCruiseSchemaVersion) {
    throw RemoteCruiseSchemaTooNewException(
      remoteSchemaVersion: version,
      supportedSchemaVersion: currentCruiseSchemaVersion,
    );
  }
  // Work on a detached document; callers may retain the raw remote for backup.
  final data = jsonDecode(jsonEncode(wrapper)) as Map<String, dynamic>;
  if (data['cruises'] is! List) {
    throw const FormatException('Missing cruise collection');
  }
  for (var step = version; step < currentCruiseSchemaVersion; step++) {
    switch (step) {
      case 1:
        // Historical optional fields are handled by the existing model readers.
        break;
      case 2:
        // V3 sync timestamps are normalized below using the existing helper.
        break;
      case 3:
        for (final raw in data['cruises'] as List) {
          _migrateLocationsV3ToV4(raw as Map<String, dynamic>);
        }
        break;
    }
    data['schemaVersion'] = step + 1;
  }
  var cruises = (data['cruises'] as List)
      .map((e) => Cruise.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList(growable: false);
  if (version < 3) {
    cruises = normalizeCruisePersistenceData(
      cruises,
      // Identical old local/remote/baseline data must normalize identically.
      nowUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
  validateCruiseLocations(cruises);
  return MigratedCruiseData(cruises, version < currentCruiseSchemaVersion);
}

Map<String, dynamic> cruiseStoragePayload(List<Cruise> cruises) {
  validateCruiseLocations(cruises);
  return {
    'schemaVersion': currentCruiseSchemaVersion,
    'cruises': cruises.map((c) => c.toMap()).toList(growable: false),
  };
}

void _migrateLocationsV3ToV4(Map<String, dynamic> cruise) {
  final locations = <Map<String, dynamic>>[
    for (final raw in cruise['locations'] as List? ?? const [])
      Map<String, dynamic>.from(raw as Map),
  ];
  final existingIds = locations.map((location) => location['id']).toSet();
  String resolve(String name, String type, String originId) {
    final key = name.trim().toLowerCase();
    final matches = locations.where((location) =>
        location['deletedAtUtc'] == null &&
        (location['name'] as String).trim().toLowerCase() == key).toList();
    if (key.isNotEmpty && matches.length == 1) {
      return matches.single['id'] as String;
    }
    // UUID v5 is stable across devices and repeated migrations of a baseline.
    // Empty names are kept separate, using the originating entity's ID.
    final id = const Uuid().v5(Namespace.url.value,
        jsonEncode(['cruise-location-v4', cruise['id'],
          key.isEmpty || matches.length > 1 ? originId : key]));
    if (locations.any((location) => location['id'] == id)) {
      throw const FormatException('Ambiguous migrated location identity');
    }
    locations.add({
      'id': id,
      'name': name,
      'type': type,
      'updatedAtUtc': null,
      'deletedAtUtc': null,
    });
    return id;
  }

  for (final raw in cruise['route'] as List? ?? const []) {
    final item = raw as Map<String, dynamic>;
    if (item['type'] != 'port') continue;
    item['locationId'] ??= resolve(
      item['portName'] as String? ?? '', 'port', 'route:${item['id']}',
    );
    item.remove('portName');
  }
  for (final raw in cruise['excursions'] as List? ?? const []) {
    final item = raw as Map<String, dynamic>;
    final name = item['port'] as String?;
    if (item['locationId'] == null && name != null && name.isNotEmpty) {
      item['locationId'] = resolve(name, 'stopPoint', 'excursion:${item['id']}');
    }
    item.remove('port');
  }
  // A place introduced solely for deleted records must not appear as an active
  // choice. Keep the tombstone and its references for the normal merge rules.
  final references = <Map<String, dynamic>>[
    for (final raw in cruise['route'] as List? ?? const [])
      if ((raw as Map)['type'] == 'port') raw as Map<String, dynamic>,
    for (final raw in cruise['excursions'] as List? ?? const [])
      raw as Map<String, dynamic>,
  ];
  for (final location in locations) {
    if (existingIds.contains(location['id'])) continue;
    final refs = references.where((item) => item['locationId'] == location['id']);
    if (refs.isNotEmpty && refs.every((item) =>
        item['deletedAtUtc'] != null || cruise['deletedAtUtc'] != null)) {
      final deletions = refs.map((item) => DateTime.parse(
          (item['deletedAtUtc'] ?? cruise['deletedAtUtc']) as String).toUtc())
          .toList()..sort();
      location['deletedAtUtc'] = deletions.last.toIso8601String();
      location['updatedAtUtc'] = location['deletedAtUtc'];
    }
  }
  cruise['locations'] = locations;
}

void validateCruiseLocations(Iterable<Cruise> cruises) {
  for (final cruise in cruises) {
    final byId = {for (final location in cruise.locations) location.id: location};
    if (byId.length != cruise.locations.length || byId.containsKey('')) {
      throw const FormatException('Invalid location IDs');
    }
    void check(String? id, DateTime? deletedAtUtc, {bool requireLocation = false}) {
      if (id == null && !requireLocation) return; // Existing unnamed excursion draft.
      final location = byId[id];
      if (location == null ||
          (cruise.deletedAtUtc == null && deletedAtUtc == null &&
              location.deletedAtUtc != null)) {
        throw FormatException('Invalid location reference: $id');
      }
    }
    for (final item in cruise.route.whereType<PortCallItem>()) {
      check(item.locationId, item.deletedAtUtc, requireLocation: true);
    }
    for (final excursion in cruise.excursions) {
      check(excursion.locationId, excursion.deletedAtUtc);
    }
  }
}

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
