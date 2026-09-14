import 'dart:convert';

import 'package:cruiseplanner/models/cruise_location.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/models/route/port_call_item.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:cruiseplanner/sync/cruise_persistence_migration.dart';
import 'package:cruiseplanner/sync/cruise_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('V3 ports and matching excursions share stable V4 location IDs', () {
    final source = legacyLocationPayload();
    final untouched = jsonEncode(source);
    final migrated = decodeCruisePersistenceData(source);
    final cruise = migrated.cruises.single;
    final ports = cruise.route.whereType<PortCallItem>().toList();

    expect(migrated.wasMigrated, isTrue);
    expect(cruise.locations, hasLength(2));
    expect(ports[0].locationId, ports[1].locationId);
    expect(cruise.excursions[0].locationId, ports[0].locationId);
    expect(cruise.locationById(ports[0].locationId)!.type,
        CruiseLocationType.port);
    final stopPoint = cruise.locationById(cruise.excursions[1].locationId)!;
    expect(stopPoint.name, 'Santiago de Compostela');
    expect(stopPoint.type, CruiseLocationType.stopPoint);
    expect(cruise.excursions[2].locationId, isNull);
    expect(jsonEncode(source), untouched);
    expect(decodeCruisePersistenceData(source).cruises, migrated.cruises);

    final payload = cruiseStoragePayload(migrated.cruises);
    expect(payload['schemaVersion'], 4);
    expect(ports.first.toMap().containsKey('portName'), isFalse);
    expect(cruise.excursions.first.toMap().containsKey('port'), isFalse);
    final reopened = decodeCruisePersistenceData(payload);
    expect(reopened.wasMigrated, isFalse);
    expect(reopened.cruises, migrated.cruises);
  });

  test('older wrappers and bare lists pass through the migration chain', () {
    for (final version in [1, 2, 3]) {
      final source = legacyLocationPayload()..['schemaVersion'] = version;
      expect(decodeCruisePersistenceData(source).cruises.single.locations,
          hasLength(2));
    }
    expect(decodeCruisePersistenceData(legacyLocationPayload()['cruises'])
        .cruises.single.locations, hasLength(2));
  });

  test('conservative matching keeps distinct names and unnamed visits separate', () {
    final source = legacyLocationPayload();
    final cruise = (source['cruises'] as List<Map<String, dynamic>>).single;
    final route = cruise['route'] as List<Map<String, dynamic>>;
    route.addAll(<Map<String, dynamic>>[
      {'type': 'port', 'id': 'blank-1', 'date': '2026-01-05', 'portName': ''},
      {'type': 'port', 'id': 'blank-2', 'date': '2026-01-06', 'portName': ''},
      {'type': 'port', 'id': 'distinct', 'date': '2026-01-07', 'portName': 'Porto Alegre'},
    ]);
    final migrated = decodeCruisePersistenceData(source).cruises.single;
    expect(migrated.locations, hasLength(5));
    expect(migrated.route.whereType<PortCallItem>()
        .map((item) => item.locationId).toSet(), hasLength(4));
  });

  test('migration retains tombstones, attachments and sea days', () {
    final source = legacyLocationPayload();
    final cruise = (source['cruises'] as List<Map<String, dynamic>>).single;
    final excursion = (cruise['excursions'] as List<Map<String, dynamic>>).first;
    excursion['deletedAtUtc'] = '2026-01-10T00:00:00.000Z';
    excursion['updatedAtUtc'] = '2026-01-09T00:00:00.000Z';
    excursion['documentIds'] = ['doc-1'];
    final migrated = decodeCruisePersistenceData(source).cruises.single;
    expect(migrated.excursions.first.deletedAtUtc, DateTime.utc(2026, 1, 10));
    expect(migrated.excursions.first.updatedAtUtc, DateTime.utc(2026, 1, 9));
    expect(migrated.excursions.first.documentIds, ['doc-1']);
    expect(migrated.route.last.type, 'sea');
    expect(migrated.route.last.toMap()['notes'], 'At sea');
  });

  test('local V3 data is persisted once as V4 and reopens without duplicates', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cruises_json_v3', jsonEncode(legacyLocationPayload()));
    final first = CruiseStore();
    final second = CruiseStore();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await first.load();
    final saved = prefs.getString('cruises_json_v3');
    expect((jsonDecode(saved!) as Map)['schemaVersion'], 4);
    await second.load();
    expect(second.cruises, first.cruises);
    expect(prefs.getString('cruises_json_v3'), saved);
  });

  test('newer local schema is rejected without rewriting preferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonEncode(legacyLocationPayload()..['schemaVersion'] = 5);
    await prefs.setString('cruises_json_v3', saved);
    final store = CruiseStore();
    addTearDown(store.dispose);
    await expectLater(store.load(), throwsA(isA<RemoteCruiseSchemaTooNewException>()));
    expect(prefs.getString('cruises_json_v3'), saved);
  });

  test('store creates excursions at existing and newly created locations', () async {
    final store = CruiseStore();
    addTearDown(store.dispose);
    final cruise = decodeCruisePersistenceData(legacyLocationPayload()).cruises.single;
    await store.replaceAll([cruise]);
    final portId = cruise.route.whereType<PortCallItem>().first.locationId;
    final excursion = Excursion(id: 'new-ex', title: 'Walk',
        date: DateTime.utc(2026), locationId: portId);
    await store.upsertExcursion(cruiseId: cruise.id, excursion: excursion);
    expect(store.getById<Excursion>(excursion.id)!.locationId, portId);
    final location = await store.createLocation(cruiseId: cruise.id,
        name: '  San Francisco  ', type: CruiseLocationType.stopPoint);
    await store.upsertExcursion(cruiseId: cruise.id,
        excursion: excursion.copyWith(locationId: location.id));
    await store.upsertExcursion(cruiseId: cruise.id,
        excursion: store.getById<Excursion>(excursion.id)!.copyWith(title: 'Edited'));
    await store.load();
    expect(store.getById<Excursion>(excursion.id)!.locationId, location.id);
    expect(store.getCruise(cruise.id)!.locationName(location.id), 'San Francisco');
    expect(store.locationChoices(cruise.id).first.id, portId);
    expect(await store.deleteLocation(cruise.id, portId), isFalse);
    expect(await store.deleteLocation(cruise.id, location.id), isFalse);
    final unused = await store.createLocation(cruiseId: cruise.id,
        name: 'Unused', type: CruiseLocationType.port);
    expect(await store.deleteLocation(cruise.id, unused.id), isTrue);
    expect(store.locationChoices(cruise.id).map((item) => item.id),
        isNot(contains(unused.id)));
  });

  test('location edits merge with excursion edits and retain shared identity', () {
    final base = decodeCruisePersistenceData(legacyLocationPayload()).cruises.single;
    final location = base.locations.first;
    final local = base.copyWith(locations: [
      location.copyWith(name: 'Porto updated', updatedAtUtc: DateTime.utc(2026, 2)),
      ...base.locations.skip(1),
    ]);
    final remote = base.copyWith(excursions: [
      base.excursions.first.copyWith(title: 'Edited remotely',
          updatedAtUtc: DateTime.utc(2026, 3)),
      ...base.excursions.skip(1),
    ]);
    final merged = CruiseSyncService.reconcileLocalChanges(
        syncInput: [base], currentLocal: [local], synced: [remote]).single;
    expect(merged.locationName(location.id), 'Porto updated');
    expect(merged.excursions.first.title, 'Edited remotely');
    expect(merged.excursions.first.locationId, location.id);
    expect(merged.locations, hasLength(2));
  });

  test('dangling references fail validation rather than inventing locations', () {
    final cruise = decodeCruisePersistenceData(legacyLocationPayload()).cruises.single;
    expect(() => cruiseStoragePayload([cruise.copyWith(locations: [])]),
        throwsFormatException);
  });

  test('locations originating only from deleted entries remain deleted', () {
    final source = legacyLocationPayload();
    final raw = (source['cruises'] as List<Map<String, dynamic>>).single;
    final excursion = (raw['excursions'] as List<Map<String, dynamic>>)[1];
    excursion['deletedAtUtc'] = '2026-02-01T00:00:00.000Z';
    final cruise = decodeCruisePersistenceData(source).cruises.single;
    final location = cruise.locationById(cruise.excursions[1].locationId)!;
    expect(location.deletedAtUtc, DateTime.utc(2026, 2));
    final roundTrip = decodeCruisePersistenceData(cruiseStoragePayload([cruise]));
    expect(roundTrip.cruises.single.locations, cruise.locations);
  });

  test('unreferenced location tombstones follow existing delete versus edit rules', () {
    final original = decodeCruisePersistenceData(legacyLocationPayload()).cruises.single;
    final unused = CruiseLocation(id: 'unused', name: 'Unused',
        type: CruiseLocationType.stopPoint, updatedAtUtc: DateTime.utc(2026, 1));
    final base = original.copyWith(locations: [...original.locations, unused]);
    final local = base.copyWith(locations: [...original.locations,
      unused.copyWith(deletedAtUtc: DateTime.utc(2026, 3),
          updatedAtUtc: DateTime.utc(2026, 3)),
    ]);
    final remote = base.copyWith(locations: [...original.locations,
      unused.copyWith(name: 'Old edit', updatedAtUtc: DateTime.utc(2026, 2)),
    ]);
    final merged = CruiseSyncService.reconcileLocalChanges(
        syncInput: [base], currentLocal: [local], synced: [remote]).single;
    expect(merged.locationById('unused')!.deletedAtUtc, DateTime.utc(2026, 3));
    final absentRemote = CruiseSyncService.reconcileLocalChanges(
        syncInput: [base], currentLocal: [local], synced: [original]).single;
    expect(absentRemote.locationById('unused'), isNull);
  });
}

// Explicit JSON types keep all nested collections mutable with heterogeneous
// values, even when the initial entries happen to contain only strings.
Map<String, dynamic> legacyLocationPayload() => <String, dynamic>{
  'schemaVersion': 3,
  'cruises': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'cruise-1', 'title': 'Cruise',
      'ship': <String, dynamic>{'name': 'Ship'},
      'period': <String, dynamic>{'start': '2026-01-01', 'end': '2026-01-08'},
      'route': <Map<String, dynamic>>[
        {'id': 'visit-1', 'type': 'port', 'date': '2026-01-02', 'portName': 'Porto'},
        {'id': 'visit-2', 'type': 'port', 'date': '2026-01-03', 'portName': ' porto '},
        {'id': 'sea-1', 'type': 'sea', 'date': '2026-01-04', 'notes': 'At sea'},
      ],
      'excursions': <Map<String, dynamic>>[
        {'id': 'ex-1', 'title': 'Walk', 'date': '2026-01-02', 'port': ' PORTO '},
        {'id': 'ex-2', 'title': 'Tour', 'date': '2026-01-09', 'port': 'Santiago de Compostela'},
        {'id': 'ex-3', 'title': 'Draft', 'date': '2026-01-10', 'port': null},
      ],
    },
  ],
};
