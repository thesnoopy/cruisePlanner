import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cruise.dart';
import '../models/excursion.dart';
import '../models/route/factory.dart' as route_factory;
import '../models/route/route_item.dart';
import '../models/travel/base_travel.dart';
import '../models/travel/factory.dart' as travel_factory;
import 'webdav_sync.dart';

/// Service, der den CruiseStore mit der WebDAV-Datei per 3-Wege-Merge
/// synchronisiert.
class CruiseSyncService {
  static const String _baselineKey = 'cruises_sync_baseline_v1';

  final WebDavSync webDav;

  const CruiseSyncService(this.webDav);

  Future<List<Cruise>> _loadBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_baselineKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      return const <Cruise>[];
    }
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map((e) => Cruise.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (_) {
      return const <Cruise>[];
    }
  }

  Future<void> _saveBaseline(List<Cruise> cruises) async {
    final prefs = await SharedPreferences.getInstance();
    final list = cruises.map((c) => c.toMap()).toList(growable: false);
    final jsonStr = jsonEncode(list);
    await prefs.setString(_baselineKey, jsonStr);
  }

  Future<List<Cruise>> sync(List<Cruise> local) async {
    final base = await _loadBaseline();
    final remote = await webDav.downloadCruises();

    final merged = _mergeThreeWay(base, local, remote);

    await webDav.uploadCruises(merged);
    await _saveBaseline(merged);

    return merged;
  }

  List<Cruise> _mergeThreeWay(
    List<Cruise> baseList,
    List<Cruise> localList,
    List<Cruise> remoteList,
  ) {
    final base = _byId(baseList);
    final local = _byId(localList);
    final remote = _byId(remoteList);
    final result = <Cruise>[];

    for (final id in _orderedCruiseIds(baseList, localList, remoteList)) {
      final merged = _mergeCruiseValue(
        base: base[id],
        local: local[id],
        remote: remote[id],
      );
      if (merged != null) {
        result.add(merged);
      }
    }

    return List<Cruise>.unmodifiable(result);
  }

  Map<String, Cruise> _byId(List<Cruise> list) =>
      {for (final cruise in list) cruise.id: cruise};

  List<String> _orderedCruiseIds(
    List<Cruise> baseList,
    List<Cruise> localList,
    List<Cruise> remoteList,
  ) {
    final ordered = <String>[];
    final seen = <String>{};

    void append(Iterable<Cruise> cruises) {
      for (final cruise in cruises) {
        if (seen.add(cruise.id)) {
          ordered.add(cruise.id);
        }
      }
    }

    append(localList);
    append(remoteList);
    append(baseList);
    return ordered;
  }

  Cruise? _mergeCruiseValue({
    required Cruise? base,
    required Cruise? local,
    required Cruise? remote,
  }) {
    final localChange = _classifyEntityChange(base, local);
    final remoteChange = _classifyEntityChange(base, remote);

    if (localChange == ChangeKind.unchanged &&
        remoteChange == ChangeKind.unchanged) {
      return base;
    }

    if (localChange != ChangeKind.unchanged &&
        remoteChange == ChangeKind.unchanged) {
      return localChange == ChangeKind.removed ? null : local;
    }

    if (localChange == ChangeKind.unchanged &&
        remoteChange != ChangeKind.unchanged) {
      return remoteChange == ChangeKind.removed ? null : remote;
    }

    if (localChange == ChangeKind.removed &&
        remoteChange != ChangeKind.removed) {
      return remote;
    }

    if (remoteChange == ChangeKind.removed &&
        localChange != ChangeKind.removed) {
      return local;
    }

    if (local == null || remote == null) {
      return local ?? remote;
    }

    return _mergeCruiseConflict(base: base, local: local, remote: remote);
  }

  Cruise _mergeCruiseConflict({
    required Cruise? base,
    required Cruise local,
    required Cruise remote,
  }) {
    final rootWinner = _resolveSameEntity(
      base: base,
      local: local,
      remote: remote,
      updatedAtOf: (entity) => entity.updatedAtUtc,
      deletedAtOf: (entity) => entity.deletedAtUtc,
      legacyMerge: _mergeCruiseLegacy,
    );

    final mergedExcursions = _mergeEntityCollection<Excursion>(
      base: base?.excursions ?? const <Excursion>[],
      local: local.excursions,
      remote: remote.excursions,
      idOf: (entity) => entity.id,
      updatedAtOf: (entity) => entity.updatedAtUtc,
      deletedAtOf: (entity) => entity.deletedAtUtc,
      legacyMerge: _mergeExcursionLegacy,
    );
    final mergedTravel = _mergeEntityCollection<TravelItem>(
      base: base?.travel ?? const <TravelItem>[],
      local: local.travel,
      remote: remote.travel,
      idOf: (entity) => entity.id,
      updatedAtOf: (entity) => entity.updatedAtUtc,
      deletedAtOf: (entity) => entity.deletedAtUtc,
      legacyMerge: _mergeTravelItemLegacy,
    );
    final mergedRoute = _mergeEntityCollection<RouteItem>(
      base: base?.route ?? const <RouteItem>[],
      local: local.route,
      remote: remote.route,
      idOf: (entity) => entity.id,
      updatedAtOf: (entity) => entity.updatedAtUtc,
      deletedAtOf: (entity) => entity.deletedAtUtc,
      legacyMerge: _mergeRouteItemLegacy,
    );

    return rootWinner.copyWith(
      excursions: mergedExcursions,
      travel: mergedTravel,
      route: mergedRoute,
    );
  }

  List<T> _mergeEntityCollection<T extends Object>({
    required List<T> base,
    required List<T> local,
    required List<T> remote,
    required String Function(T entity) idOf,
    required DateTime? Function(T entity) updatedAtOf,
    required DateTime? Function(T entity) deletedAtOf,
    required T Function(T? base, T local, T remote) legacyMerge,
  }) {
    final baseById = {for (final entity in base) idOf(entity): entity};
    final localById = {for (final entity in local) idOf(entity): entity};
    final remoteById = {for (final entity in remote) idOf(entity): entity};
    final orderedIds = _orderedEntityIds(
      base: base,
      local: local,
      remote: remote,
      idOf: idOf,
    );
    final result = <T>[];

    for (final id in orderedIds) {
      final merged = _mergeEntityValue<T>(
        base: baseById[id],
        local: localById[id],
        remote: remoteById[id],
        updatedAtOf: updatedAtOf,
        deletedAtOf: deletedAtOf,
        legacyMerge: legacyMerge,
      );
      if (merged != null) {
        result.add(merged);
      }
    }

    return List<T>.unmodifiable(result);
  }

  List<String> _orderedEntityIds<T extends Object>({
    required List<T> base,
    required List<T> local,
    required List<T> remote,
    required String Function(T entity) idOf,
  }) {
    final ordered = <String>[];
    final seen = <String>{};

    void append(Iterable<T> entities) {
      for (final entity in entities) {
        final id = idOf(entity);
        if (seen.add(id)) {
          ordered.add(id);
        }
      }
    }

    append(local);
    append(remote);
    append(base);
    return ordered;
  }

  T? _mergeEntityValue<T extends Object>({
    required T? base,
    required T? local,
    required T? remote,
    required DateTime? Function(T entity) updatedAtOf,
    required DateTime? Function(T entity) deletedAtOf,
    required T Function(T? base, T local, T remote) legacyMerge,
  }) {
    final localChange = _classifyEntityChange(base, local);
    final remoteChange = _classifyEntityChange(base, remote);

    if (localChange == ChangeKind.unchanged &&
        remoteChange == ChangeKind.unchanged) {
      return base;
    }

    if (localChange != ChangeKind.unchanged &&
        remoteChange == ChangeKind.unchanged) {
      return localChange == ChangeKind.removed ? null : local;
    }

    if (localChange == ChangeKind.unchanged &&
        remoteChange != ChangeKind.unchanged) {
      return remoteChange == ChangeKind.removed ? null : remote;
    }

    if (localChange == ChangeKind.removed &&
        remoteChange != ChangeKind.removed) {
      return remote;
    }

    if (remoteChange == ChangeKind.removed &&
        localChange != ChangeKind.removed) {
      return local;
    }

    if (local == null || remote == null) {
      return local ?? remote;
    }

    return _resolveSameEntity<T>(
      base: base,
      local: local,
      remote: remote,
      updatedAtOf: updatedAtOf,
      deletedAtOf: deletedAtOf,
      legacyMerge: legacyMerge,
    );
  }

  ChangeKind _classifyEntityChange<T extends Object>(T? base, T? next) {
    if (base == null && next == null) {
      return ChangeKind.unchanged;
    }
    if (base == null && next != null) {
      return ChangeKind.added;
    }
    if (base != null && next == null) {
      return ChangeKind.removed;
    }
    return base == next ? ChangeKind.unchanged : ChangeKind.modified;
  }

  T _resolveSameEntity<T extends Object>({
    required T? base,
    required T local,
    required T remote,
    required DateTime? Function(T entity) updatedAtOf,
    required DateTime? Function(T entity) deletedAtOf,
    required T Function(T? base, T local, T remote) legacyMerge,
  }) {
    final localDeletedAt = deletedAtOf(local);
    final remoteDeletedAt = deletedAtOf(remote);
    final localUpdatedAt = updatedAtOf(local);
    final remoteUpdatedAt = updatedAtOf(remote);
    final localDeleted = localDeletedAt != null;
    final remoteDeleted = remoteDeletedAt != null;

    if (!localDeleted && !remoteDeleted) {
      final comparison = _compareTimestamps(localUpdatedAt, remoteUpdatedAt);
      if (comparison > 0) {
        return local;
      }
      if (comparison < 0) {
        return remote;
      }
      return legacyMerge(base, local, remote);
    }

    if (localDeleted && remoteDeleted) {
      final comparison = _compareTimestamps(localDeletedAt, remoteDeletedAt);
      if (comparison > 0) {
        return local;
      }
      if (comparison < 0) {
        return remote;
      }
      return legacyMerge(base, local, remote);
    }

    final deletedEntity = localDeleted ? local : remote;
    final updatedEntity = localDeleted ? remote : local;
    final deletedAt = localDeleted ? localDeletedAt : remoteDeletedAt;
    final updatedAt = localDeleted ? remoteUpdatedAt : localUpdatedAt;
    final comparison = _compareTimestamps(deletedAt, updatedAt);

    if (comparison > 0) {
      return deletedEntity;
    }
    if (comparison < 0) {
      return updatedEntity;
    }

    return legacyMerge(base, local, remote);
  }

  int _compareTimestamps(DateTime? left, DateTime? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return -1;
    }
    if (right == null) {
      return 1;
    }
    return left.compareTo(right);
  }

  Cruise _mergeCruiseLegacy(Cruise? base, Cruise local, Cruise remote) {
    if (base == null) {
      return local;
    }

    return _mergeLegacyEntity(
      base: base,
      local: local,
      remote: remote,
      toMap: (entity) => entity.toMap(),
      fromMap: Cruise.fromMap,
      excludedKeys: const {'excursions', 'travel', 'route'},
    );
  }

  Excursion _mergeExcursionLegacy(
    Excursion? base,
    Excursion local,
    Excursion remote,
  ) {
    if (base == null) {
      return local;
    }

    return _mergeLegacyEntity(
      base: base,
      local: local,
      remote: remote,
      toMap: (entity) => entity.toMap(),
      fromMap: Excursion.fromMap,
    );
  }

  TravelItem _mergeTravelItemLegacy(
    TravelItem? base,
    TravelItem local,
    TravelItem remote,
  ) {
    if (base == null) {
      return local;
    }

    return _mergeLegacyEntity(
      base: base,
      local: local,
      remote: remote,
      toMap: (entity) => entity.toMap(),
      fromMap: travel_factory.travelItemFromMap,
    );
  }

  RouteItem _mergeRouteItemLegacy(
    RouteItem? base,
    RouteItem local,
    RouteItem remote,
  ) {
    if (base == null) {
      return local;
    }

    return _mergeLegacyEntity(
      base: base,
      local: local,
      remote: remote,
      toMap: (entity) => entity.toMap(),
      fromMap: route_factory.routeItemFromMap,
    );
  }

  T _mergeLegacyEntity<T>({
    required T base,
    required T local,
    required T remote,
    required Map<String, dynamic> Function(T entity) toMap,
    required T Function(Map<String, dynamic> map) fromMap,
    Set<String> excludedKeys = const <String>{},
  }) {
    final baseMap = toMap(base);
    final localMap = toMap(local);
    final remoteMap = toMap(remote);
    final mergedMap = Map<String, dynamic>.from(remoteMap);
    final mergeableKeys = <String>{
      ...baseMap.keys,
      ...localMap.keys,
      ...remoteMap.keys,
    }
      ..remove('id')
      ..removeAll(excludedKeys);

    for (final key in mergeableKeys) {
      final localChanged = !_fieldValueEquals(baseMap[key], localMap[key]);
      final remoteChanged = !_fieldValueEquals(baseMap[key], remoteMap[key]);

      if (localChanged && !remoteChanged) {
        mergedMap[key] = localMap[key];
      }
    }

    return fromMap(mergedMap);
  }

  bool _fieldValueEquals(dynamic a, dynamic b) {
    return jsonEncode(a) == jsonEncode(b);
  }
}

enum ChangeKind { unchanged, added, removed, modified }
