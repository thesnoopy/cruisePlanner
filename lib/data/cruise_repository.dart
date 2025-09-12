// lib/data/cruise_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/cruise.dart';

class CruiseRepository {
  static const _keyData  = 'cruises_json_v1';
  static const _keyMtime = 'cruises_local_mtime_v1'; // ISO-UTC (Server-Snapshot)
  static const _keyETag  = 'cruises_remote_etag_v1'; // <— NEU

  // --- Helper: auf Sekunde runden (UTC) ---
  DateTime _roundToSecondUtc(DateTime dt) {
    final u = dt.toUtc();
    return DateTime.utc(u.year, u.month, u.day, u.hour, u.minute, u.second);
  }

  Future<List<Cruise>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyData);
    if (jsonStr == null || jsonStr.trim().isEmpty) return <Cruise>[];

    try {
      final decoded = jsonDecode(jsonStr);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['cruises'] is List) {
          list = decoded['cruises'] as List<dynamic>;
        } else if (decoded.values.every((v) => v is Map)) {
          list = decoded.values.toList();
        } else if (decoded.isNotEmpty) {
          list = [decoded];
        } else {
          list = const [];
        }
      } else {
        list = const [];
      }

      final result = <Cruise>[];
      for (final e in list) {
        if (e is Map) {
          try {
            result.add(Cruise.fromMap(Map<String, dynamic>.from(e)));
          } catch (inner) {
            debugPrint('Skip invalid cruise entry: $inner | entry=$e');
          }
        } else {
          debugPrint('Skip non-map cruise entry: $e');
        }
      }
      return result;
    } catch (e, st) {
      debugPrint('CruiseRepository.load parse error: $e\n$st');
      return <Cruise>[];
    }
  }

  Future<DateTime?> localModifiedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyMtime);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toUtc();
  }

  // <— NEU: ETag lesen/schreiben
  Future<String?> remoteETag() async {
    final prefs = await SharedPreferences.getInstance();
    final et = prefs.getString(_keyETag);
    return (et == null || et.isEmpty) ? null : et;
  }

  Future<void> setRemoteETag(String? etag) async {
    final prefs = await SharedPreferences.getInstance();
    if (etag == null || etag.isEmpty) {
      await prefs.remove(_keyETag);
    } else {
      await prefs.setString(_keyETag, etag);
    }
  }

  Future<void> upsertCruise(Cruise cruise) async {
    final all = await load();
    final idx = all.indexWhere((c) => c.id == cruise.id);
    final updated = List<Cruise>.from(all);
    if (idx >= 0) {
      updated[idx] = cruise;
    } else {
      updated.add(cruise);
    }
    await save(updated); // lokaler Edit → lokale mTime = now()
  }

  Future<void> deleteCruise(String cruiseId) async {
    final all = await load();
    final updated = all.where((c) => c.id != cruiseId).toList();
    await save(updated);
  }

  // remoteETag optional mitschreiben (nach Upload/Download)
  Future<void> save(List<Cruise> cruises, {DateTime? modifiedAtUtc, String? remoteETag}) async {
    final prefs = await SharedPreferences.getInstance();
    final obj = {'cruises': cruises.map((c) => c.toMap()).toList(growable: false)};
    await prefs.setString(_keyData, jsonEncode(obj));

    final ts = _roundToSecondUtc(modifiedAtUtc ?? DateTime.now().toUtc()).toIso8601String();
    await prefs.setString(_keyMtime, ts);

    if (remoteETag != null) {
      await prefs.setString(_keyETag, remoteETag);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyData);
    await prefs.remove(_keyMtime);
    await prefs.remove(_keyETag); // <— NEU
  }
}
