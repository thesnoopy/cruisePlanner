
import 'dart:convert';
import 'package:cruiseplanner/models/travel/cruise_check_in_item.dart';
import 'package:cruiseplanner/models/travel/cruise_check_out_item.dart';
import 'package:cruiseplanner/models/travel/hotel_item.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cruise.dart';
import '../models/excursion.dart';
import '../models/travel/base_travel.dart';
import '../models/travel/flight_item.dart';
import '../models/travel/train_item.dart';
import '../models/travel/transfer_item.dart';
import '../models/travel/rental_car_item.dart';
import '../models/route/route_item.dart';
import '../models/route/sea_day_item.dart';
import '../models/route/port_call_item.dart';
import '../models/identifiable.dart';

import '../settings/webdav_settings_store.dart';
import '../sync/webdav_sync.dart';
import '../sync/cruise_sync_service.dart';
import 'dart:async';

class _IndexRef {
  final String cruiseId;
  final Type type;
  _IndexRef(this.cruiseId, this.type);
}

class CruiseStore extends ChangeNotifier {
  static const String _spKey = 'cruises_json_v1';

  List<Cruise> _cruises = const [];
  final Map<String, _IndexRef> _index = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<Cruise> get cruises => _cruises;

  // NEU: Auto-Sync-Status
  Timer? _autoSyncTimer;
  bool _isAutoSyncRunning = false;

  void _scheduleAutoSync() {
    // kleine Entprellung, damit nicht bei jeder kleinen Änderung sofort gesynct wird
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(const Duration(seconds: 1), () {
      _runAutoSync();
    });
  }

  Future<void> _runAutoSync() async {
    debugPrint("Sync triggered");
    if (_isAutoSyncRunning) return;
    _isAutoSyncRunning = true;

    try {
      // WebDAV Settings laden – wenn nichts konfiguriert ist, einfach leise abbrechen
      final settingsStore = const WebDavSettingsStore();
      final settings = await settingsStore.load();
      if (settings == null || !settings.isValid) {
        return;
      }

      final webDav = WebDavSync(settings);
      final syncService = CruiseSyncService(webDav);

      // aktueller lokaler Stand als Input
      final merged = await syncService.sync(_cruises);

      // nur wenn erfolgreich: lokalen Store aktualisieren
      _cruises = List<Cruise>.unmodifiable(merged);
      _rebuildIndex();
      await _persist();
      notifyListeners();
      debugPrint('Auto sync complete');
    } catch (e) {
      // Automatischer Sync: KEINE UI-Meldung, nur optionales Logging
      if (kDebugMode) {
        // ignore: avoid_print
        debugPrint('Auto sync failed: $e');
      }
    } finally {
      _isAutoSyncRunning = false;
    }
  }

  /// NEU: Öffentlicher Trigger für "App geöffnet / App im Vordergrund".
  /// Kann direkt ohne Delay syncen oder (wenn du magst) über _scheduleAutoSync gehen.
  Future<void> triggerAutoSyncOnAppOpen() async {
    await _runAutoSync();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_spKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      _cruises = const [];
    } else {
      final decoded = jsonDecode(jsonStr);
      final list = (decoded is List)
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['cruises'] is List)
              ? decoded['cruises']
              : <dynamic>[];
      _cruises = List.unmodifiable(
        (list as List).map((e) => Cruise.fromMap(Map<String, dynamic>.from(e))).toList(),
      );
    }
    _rebuildIndex();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(_cruises.map((c) => c.toMap()).toList());
    await prefs.setString(_spKey, payload);
  }

  // Safe nullable lookup without returning null from a non-nullable closure
  Cruise? getCruise(String id) {
    for (final c in _cruises) {
      if (c.id == id) return c;
    }
    return null;
  }

  T? getById<T extends Identifiable>(String id) {
    final ref = _index[id];
    if (ref == null) return null;
    final cruise = getCruise(ref.cruiseId);
    if (cruise == null) return null;

    if (T == Cruise || ref.type == Cruise) return cruise as T?;

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

  // ---------------- Upserts ----------------

  Future<void> upsertCruise(Cruise cruise) async {
    final i = _cruises.indexWhere((c) => c.id == cruise.id);
    if (i >= 0) {
      _cruises = List<Cruise>.unmodifiable([
        ..._cruises.sublist(0, i),
        cruise,
        ..._cruises.sublist(i + 1),
      ]);
    } else {
      _cruises = List<Cruise>.unmodifiable([..._cruises, cruise]);
    }
    _rebuildIndex();
    await _persist();
    notifyListeners();

    // NEU: automatische Synchronisation anstoßen (leise)
    _scheduleAutoSync();
  }

  Future<void> upsertExcursion({required String cruiseId, required Excursion excursion}) async {
    final idx = _cruises.indexWhere((c) => c.id == cruiseId);
    if (idx < 0) return;
    final cruise = _cruises[idx];
    final list = [...cruise.excursions];
    final i = list.indexWhere((e) => e.id == excursion.id);
    if (i >= 0) list[i] = excursion; else list.add(excursion);
    await upsertCruise(cruise.copyWith(excursions: List.unmodifiable(list)));
  }

  Future<void> upsertTravelItem({required String cruiseId, required TravelItem item}) async {
    final idx = _cruises.indexWhere((c) => c.id == cruiseId);
    if (idx < 0) return;
    final cruise = _cruises[idx];
    final list = [...cruise.travel];
    final i = list.indexWhere((t) => t.id == item.id);
    if (i >= 0) list[i] = item; else list.add(item);
    await upsertCruise(cruise.copyWith(travel: List.unmodifiable(list)));
  }

  Future<void> upsertRouteItem({required String cruiseId, required RouteItem item}) async {
    final idx = _cruises.indexWhere((c) => c.id == cruiseId);
    if (idx < 0) return;
    final cruise = _cruises[idx];
    final list = [...cruise.route];
    final i = list.indexWhere((r) => r.id == item.id);
    if (i >= 0) list[i] = item; else list.add(item);
    await upsertCruise(cruise.copyWith(route: List.unmodifiable(list)));
  }

  // ---------------- Deletes ----------------

  Future<void> deleteCruise(String cruiseId) async {
    _cruises = List<Cruise>.unmodifiable(_cruises.where((c) => c.id != cruiseId));
    _rebuildIndex();
    await _persist();
    notifyListeners();

    // NEU:
    _scheduleAutoSync();
  }

  Future<void> deleteExcursion(String excursionId) async {
    final ref = _index[excursionId];
    if (ref == null) return;
    final idx = _cruises.indexWhere((c) => c.id == ref.cruiseId);
    if (idx < 0) return;
    final cruise = _cruises[idx];
    final next = cruise.copyWith(
      excursions: List.unmodifiable(cruise.excursions.where((e) => e.id != excursionId)),
    );
    await upsertCruise(next);
  }

  Future<void> deleteTravelItem(String travelItemId) async {
    final ref = _index[travelItemId];
    if (ref == null) return;
    final idx = _cruises.indexWhere((c) => c.id == ref.cruiseId);
    if (idx < 0) return;
    final cruise = _cruises[idx];
    final next = cruise.copyWith(
      travel: List.unmodifiable(cruise.travel.where((t) => t.id != travelItemId)),
    );
    await upsertCruise(next);
  }

  Future<void> deleteRouteItem(String routeItemId) async {
    final ref = _index[routeItemId];
    if (ref == null) return;
    final idx = _cruises.indexWhere((c) => c.id == ref.cruiseId);
    if (idx < 0) return;
    final cruise = _cruises[idx];
    final next = cruise.copyWith(
      route: List.unmodifiable(cruise.route.where((r) => r.id != routeItemId)),
    );
    await upsertCruise(next);
  }

  // ---------------- Utilities ----------------

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
    _rebuildIndex();    // falls vorhanden
    await _persist();   // damit SharedPreferences aktualisiert werden
    notifyListeners();

    // NEU:
    _scheduleAutoSync();
  }

}

// Small local helper to avoid package:collection dependency
extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E e) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
