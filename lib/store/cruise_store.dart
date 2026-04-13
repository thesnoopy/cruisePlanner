import 'dart:async';
import 'dart:convert';

import 'package:cruiseplanner/models/travel/cruise_check_in_item.dart';
import 'package:cruiseplanner/models/travel/cruise_check_out_item.dart';
import 'package:cruiseplanner/models/travel/hotel_item.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cruise.dart';
import '../models/excursion.dart';
import '../models/identifiable.dart';
import '../models/route/port_call_item.dart';
import '../models/route/route_item.dart';
import '../models/route/sea_day_item.dart';
import '../models/travel/base_travel.dart';
import '../models/travel/flight_item.dart';
import '../models/travel/rental_car_item.dart';
import '../models/travel/train_item.dart';
import '../models/travel/transfer_item.dart';
import '../services/documents/document_reference_cleanup_service.dart';
import '../sync/app_sync_service.dart';

class _IndexRef {
  final String cruiseId;
  final Type type;

  const _IndexRef(this.cruiseId, this.type);
}

class _StoredCruisesData {
  final List<Cruise> cruises;
  final bool needsMigration;

  const _StoredCruisesData({
    required this.cruises,
    required this.needsMigration,
  });
}

class CruiseStore extends ChangeNotifier {
  CruiseStore({
    AppSyncService? appSyncService,
    DocumentReferenceCleanupService? documentReferenceCleanupService,
  }) : _appSyncService = appSyncService ?? const AppSyncService() {
    _documentReferenceCleanupService =
        documentReferenceCleanupService ??
        DocumentReferenceCleanupService(cruiseStore: this);
  }

  static const String _spKey = 'cruises_json_v1';
  static const int _currentSchemaVersion = 2;

  final AppSyncService _appSyncService;
  late final DocumentReferenceCleanupService _documentReferenceCleanupService;
  final Map<String, _IndexRef> _index = {};

  List<Cruise> _cruises = const [];
  bool _loaded = false;
  Timer? _autoSyncTimer;
  Future<AppSyncResult>? _inFlightAppSync;

  bool get isLoaded => _loaded;
  List<Cruise> get cruises => _cruises;

  void _scheduleAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(const Duration(seconds: 1), () {
      _runAutoSync();
    });
  }

  Future<void> _runAutoSync() async {
    debugPrint('Sync triggered');

    try {
      final result = await _runAppSync();
      if (result.wasSkipped) {
        return;
      }

      if (result.hasFailures) {
        debugPrint(
          'Auto sync completed with document sync failures: '
          '${result.failureMessage}',
        );
        return;
      }

      debugPrint('Auto sync complete');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auto sync failed: $e');
      }
    }
  }

  Future<void> triggerAutoSyncOnAppOpen() async {
    await _runAutoSync();
  }

  Future<AppSyncResult> runAppSync() async {
    if (!_loaded) {
      await load();
    }

    return _runAppSync();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_spKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      _cruises = const [];
    } else {
      final stored = _decodeStoredCruises(jsonStr);
      _cruises = List.unmodifiable(stored.cruises);
      if (stored.needsMigration) {
        await _persist();
      }
    }
    _rebuildIndex();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(_buildStoragePayload(_cruises));
    await prefs.setString(_spKey, payload);
  }

  _StoredCruisesData _decodeStoredCruises(String jsonStr) {
    final decoded = jsonDecode(jsonStr);

    if (decoded is List) {
      return _StoredCruisesData(
        cruises: _parseCruises(decoded),
        needsMigration: true,
      );
    }

    if (decoded is Map<String, dynamic>) {
      final schemaVersion = decoded['schemaVersion'];
      final cruises = decoded['cruises'];

      if (schemaVersion == _currentSchemaVersion && cruises is List) {
        return _StoredCruisesData(
          cruises: _parseCruises(cruises),
          needsMigration: false,
        );
      }

      if ((schemaVersion == null || schemaVersion == 1) && cruises is List) {
        return _StoredCruisesData(
          cruises: _migrateV1ToV2(decoded),
          needsMigration: true,
        );
      }
    }

    return const _StoredCruisesData(
      cruises: <Cruise>[],
      needsMigration: false,
    );
  }

  List<Cruise> _migrateV1ToV2(Map<String, dynamic> legacyData) {
    final cruises = legacyData['cruises'];
    if (cruises is! List) {
      return const <Cruise>[];
    }
    return _parseCruises(cruises);
  }

  List<Cruise> _parseCruises(List<dynamic> list) {
    return list
        .map((e) => Cruise.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Map<String, dynamic> _buildStoragePayload(List<Cruise> cruises) {
    return <String, dynamic>{
      'schemaVersion': _currentSchemaVersion,
      'cruises': cruises.map((c) => c.toMap()).toList(growable: false),
    };
  }

  Cruise? getCruise(String id) {
    for (final c in _cruises) {
      if (c.id == id) {
        return c;
      }
    }
    return null;
  }

  T? getById<T extends Identifiable>(String id) {
    final ref = _index[id];
    if (ref == null) {
      return null;
    }
    final cruise = getCruise(ref.cruiseId);
    if (cruise == null) {
      return null;
    }

    if (T == Cruise || ref.type == Cruise) {
      return cruise as T?;
    }

    if (ref.type == Excursion) {
      return cruise.excursions.firstWhereOrNull((e) => e.id == id) as T?;
    }
    if (ref.type == FlightItem ||
        ref.type == TrainItem ||
        ref.type == TransferItem ||
        ref.type == RentalCarItem ||
        ref.type == HotelItem ||
        ref.type == CruiseCheckIn ||
        ref.type == CruiseCheckOut) {
      return cruise.travel.firstWhereOrNull((t) => t.id == id) as T?;
    }
    if (ref.type == SeaDayItem || ref.type == PortCallItem) {
      return cruise.route.firstWhereOrNull((r) => r.id == id) as T?;
    }
    return null;
  }

  Future<void> upsertCruise(Cruise cruise) async {
    final i = _cruises.indexWhere((c) => c.id == cruise.id);
    if (i >= 0) {
      await _replaceCruises([
        ..._cruises.sublist(0, i),
        cruise,
        ..._cruises.sublist(i + 1),
      ]);
    } else {
      await _replaceCruises([..._cruises, cruise]);
    }
  }

  Future<void> upsertExcursion({
    required String cruiseId,
    required Excursion excursion,
  }) async {
    final idx = _cruises.indexWhere((c) => c.id == cruiseId);
    if (idx < 0) {
      return;
    }
    final cruise = _cruises[idx];
    final list = [...cruise.excursions];
    final i = list.indexWhere((e) => e.id == excursion.id);
    if (i >= 0) {
      list[i] = excursion;
    } else {
      list.add(excursion);
    }
    await upsertCruise(cruise.copyWith(excursions: List.unmodifiable(list)));
  }

  Future<void> upsertTravelItem({
    required String cruiseId,
    required TravelItem item,
  }) async {
    final idx = _cruises.indexWhere((c) => c.id == cruiseId);
    if (idx < 0) {
      return;
    }
    final cruise = _cruises[idx];
    final list = [...cruise.travel];
    final i = list.indexWhere((t) => t.id == item.id);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
    await upsertCruise(cruise.copyWith(travel: List.unmodifiable(list)));
  }

  Future<void> upsertRouteItem({
    required String cruiseId,
    required RouteItem item,
  }) async {
    final idx = _cruises.indexWhere((c) => c.id == cruiseId);
    if (idx < 0) {
      return;
    }
    final cruise = _cruises[idx];
    final list = [...cruise.route];
    final i = list.indexWhere((r) => r.id == item.id);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
    await upsertCruise(cruise.copyWith(route: List.unmodifiable(list)));
  }

  Future<void> updateExcursionStopVisited(
    String cruiseId,
    String excursionId,
    String stopId,
    bool visited,
  ) async {
    if (!_loaded) {
      await load();
    }

    final cruise = getCruise(cruiseId);
    if (cruise == null) {
      return;
    }

    final excursionIndex = cruise.excursions.indexWhere(
      (e) => e.id == excursionId,
    );
    if (excursionIndex < 0) {
      return;
    }

    final excursion = cruise.excursions[excursionIndex];
    final stopIndex = excursion.stops.indexWhere((s) => s.id == stopId);
    if (stopIndex < 0) {
      return;
    }

    final stops = [...excursion.stops];
    final stop = stops[stopIndex];
    if (stop.visited == visited) {
      return;
    }

    stops[stopIndex] = stop.copyWith(visited: visited);

    final excursions = [...cruise.excursions];
    excursions[excursionIndex] = excursion.copyWith(
      stops: List.unmodifiable(stops),
    );

    await upsertCruise(
      cruise.copyWith(excursions: List.unmodifiable(excursions)),
    );
  }

  Future<void> deleteCruise(String cruiseId) async {
    final cruise = getCruise(cruiseId);
    final affectedDocumentIds = cruise == null
        ? const <String>[]
        : _documentReferenceCleanupService.collectCruiseDocumentIds(cruise);

    await _replaceCruises(
      _cruises.where((c) => c.id != cruiseId),
      shouldNotifyListeners: false,
      shouldScheduleAutoSync: false,
    );
    await _documentReferenceCleanupService.softDeleteDocumentsIfUnreferenced(
      affectedDocumentIds,
    );
    notifyListeners();
    _scheduleAutoSync();
  }

  Future<void> deleteExcursion(String excursionId) async {
    final ref = _index[excursionId];
    if (ref == null) {
      return;
    }
    final idx = _cruises.indexWhere((c) => c.id == ref.cruiseId);
    if (idx < 0) {
      return;
    }
    final cruise = _cruises[idx];
    final excursion = cruise.excursions.firstWhereOrNull((e) => e.id == excursionId);
    final affectedDocumentIds = excursion?.documentIds ?? const <String>[];
    final next = cruise.copyWith(
      excursions: List.unmodifiable(
        cruise.excursions.where((e) => e.id != excursionId),
      ),
    );
    await _upsertCruise(
      next,
      shouldNotifyListeners: false,
      shouldScheduleAutoSync: false,
    );
    await _documentReferenceCleanupService.softDeleteDocumentsIfUnreferenced(
      affectedDocumentIds,
    );
    notifyListeners();
    _scheduleAutoSync();
  }

  Future<void> deleteTravelItem(String travelItemId) async {
    final ref = _index[travelItemId];
    if (ref == null) {
      return;
    }
    final idx = _cruises.indexWhere((c) => c.id == ref.cruiseId);
    if (idx < 0) {
      return;
    }
    final cruise = _cruises[idx];
    final travelItem = cruise.travel.firstWhereOrNull((t) => t.id == travelItemId);
    final affectedDocumentIds = travelItem?.documentIds ?? const <String>[];
    final next = cruise.copyWith(
      travel: List.unmodifiable(
        cruise.travel.where((t) => t.id != travelItemId),
      ),
    );
    await _upsertCruise(
      next,
      shouldNotifyListeners: false,
      shouldScheduleAutoSync: false,
    );
    await _documentReferenceCleanupService.softDeleteDocumentsIfUnreferenced(
      affectedDocumentIds,
    );
    notifyListeners();
    _scheduleAutoSync();
  }

  Future<void> deleteRouteItem(String routeItemId) async {
    final ref = _index[routeItemId];
    if (ref == null) {
      return;
    }
    final idx = _cruises.indexWhere((c) => c.id == ref.cruiseId);
    if (idx < 0) {
      return;
    }
    final cruise = _cruises[idx];
    final routeItem = cruise.route.firstWhereOrNull((r) => r.id == routeItemId);
    final affectedDocumentIds = routeItem is PortCallItem
        ? routeItem.documentIds
        : const <String>[];
    final next = cruise.copyWith(
      route: List.unmodifiable(cruise.route.where((r) => r.id != routeItemId)),
    );
    await _upsertCruise(
      next,
      shouldNotifyListeners: false,
      shouldScheduleAutoSync: false,
    );
    await _documentReferenceCleanupService.softDeleteDocumentsIfUnreferenced(
      affectedDocumentIds,
    );
    notifyListeners();
    _scheduleAutoSync();
  }

  Future<void> _upsertCruise(
    Cruise cruise, {
    bool shouldNotifyListeners = true,
    bool shouldScheduleAutoSync = true,
  }) async {
    final i = _cruises.indexWhere((c) => c.id == cruise.id);
    if (i >= 0) {
      await _replaceCruises([
        ..._cruises.sublist(0, i),
        cruise,
        ..._cruises.sublist(i + 1),
      ],
        shouldNotifyListeners: shouldNotifyListeners,
        shouldScheduleAutoSync: shouldScheduleAutoSync,
      );
      return;
    }

    await _replaceCruises(
      [..._cruises, cruise],
      shouldNotifyListeners: shouldNotifyListeners,
      shouldScheduleAutoSync: shouldScheduleAutoSync,
    );
  }

  Future<void> _replaceCruises(
    Iterable<Cruise> cruises, {
    bool shouldNotifyListeners = true,
    bool shouldScheduleAutoSync = true,
  }) async {
    _cruises = List<Cruise>.unmodifiable(cruises);
    _rebuildIndex();
    await _persist();

    if (shouldNotifyListeners) {
      notifyListeners();
    }
    if (shouldScheduleAutoSync) {
      _scheduleAutoSync();
    }
  }

  void _rebuildIndex() {
    _index.clear();
    for (final c in _cruises) {
      _index[c.id] = _IndexRef(c.id, Cruise);
      for (final e in c.excursions) {
        _index[e.id] = _IndexRef(c.id, Excursion);
      }
      for (final t in c.travel) {
        _index[t.id] = _IndexRef(c.id, t.runtimeType);
      }
      for (final r in c.route) {
        _index[r.id] = _IndexRef(c.id, r.runtimeType);
      }
    }
  }

  Future<void> replaceAll(List<Cruise> cruises) async {
    _cruises = List.unmodifiable(cruises);
    _rebuildIndex();
    await _persist();
    notifyListeners();
    _scheduleAutoSync();
  }

  Future<AppSyncResult> _runAppSync() async {
    final inFlightSync = _inFlightAppSync;
    if (inFlightSync != null) {
      return inFlightSync;
    }

    final syncFuture = _performAppSync();
    _inFlightAppSync = syncFuture;

    try {
      return await syncFuture;
    } finally {
      if (identical(_inFlightAppSync, syncFuture)) {
        _inFlightAppSync = null;
      }
    }
  }

  Future<AppSyncResult> _performAppSync() async {
    final result = await _appSyncService.sync(localCruises: _cruises);
    final mergedCruises = result.mergedCruises;
    if (mergedCruises == null) {
      return result;
    }

    _cruises = List<Cruise>.unmodifiable(mergedCruises);
    _rebuildIndex();
    await _persist();
    notifyListeners();
    return result;
  }
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E e) test) {
    for (final e in this) {
      if (test(e)) {
        return e;
      }
    }
    return null;
  }
}
