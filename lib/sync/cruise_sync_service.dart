import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cruise.dart';
import 'webdav_sync.dart';

/// Service, der den CruiseStore mit der WebDAV‑Datei per 3‑Wege‑Merge synchronisiert.
///
/// Idee:
///  * Baseline B = Stand beim letzten erfolgreichen Sync
///  * Local   L = aktueller lokaler Stand (vom CruiseStore)
///  * Remote  R = aktueller Stand aus der Cloud
///
/// Pro Cruise-ID wird verglichen, was sich gegenüber B geändert hat.
/// Dadurch können neue / gelöschte / geänderte Cruises von mehreren
/// Geräten sauber zusammengeführt werden.
class CruiseSyncService {
  static const String _baselineKey = 'cruises_sync_baseline_v1';

  final WebDavSync webDav;

  CruiseSyncService(this.webDav);

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
      // Wenn etwas schiefgeht: Baseline verwerfen, aber App nicht killen.
      return const <Cruise>[];
    }
  }

  Future<void> _saveBaseline(List<Cruise> cruises) async {
    final prefs = await SharedPreferences.getInstance();
    final list = cruises.map((c) => c.toMap()).toList();
    final jsonStr = jsonEncode(list);
    await prefs.setString(_baselineKey, jsonStr);
  }

  /// Führt einen 3‑Wege‑Merge durch und schreibt das Ergebnis in die Cloud.
  ///
  /// [local] ist der aktuelle Inhalt deines CruiseStore (z.B. `store.cruises`).
  /// Rückgabe ist die gemergte Liste, die du anschließend wieder in den Store
  /// schreiben solltest (z.B. über eine `replaceAll`‑Methode oder ähnliches).
  Future<List<Cruise>> sync(List<Cruise> local) async {
    final base = await _loadBaseline();
    final remote = await webDav.downloadCruises();

    final merged = _mergeThreeWay(base, local, remote);

    await webDav.uploadCruises(merged);
    await _saveBaseline(merged);

    return merged;
  }

  // ==== 3‑Wege‑Merge ====

  List<Cruise> _mergeThreeWay(
    List<Cruise> baseList,
    List<Cruise> localList,
    List<Cruise> remoteList,
  ) {
    final base = _byId(baseList);
    final local = _byId(localList);
    final remote = _byId(remoteList);

    final allIds = <String>{
      ...base.keys,
      ...local.keys,
      ...remote.keys,
    };

    final result = <String, Cruise>{};

    for (final id in allIds) {
      final b = base[id];
      final l = local[id];
      final r = remote[id];

      final lc = _classifyChange(b, l);
      final rc = _classifyChange(b, r);

      // 1) Beide Seiten unverändert -> Baseline übernehmen
      if (lc == ChangeKind.unchanged && rc == ChangeKind.unchanged) {
        if (b != null) result[id] = b;
        continue;
      }

      // 2) Nur lokal geändert (added/modified/removed)
      if (lc != ChangeKind.unchanged && rc == ChangeKind.unchanged) {
        if (l != null && lc != ChangeKind.removed) {
          result[id] = l;
        }
        // wenn local == removed -> nichts in result => gelöscht
        continue;
      }

      // 3) Nur remote geändert
      if (lc == ChangeKind.unchanged && rc != ChangeKind.unchanged) {
        if (r != null && rc != ChangeKind.removed) {
          result[id] = r;
        }
        continue;
      }

      // 4) Beide geändert -> Konflikte behandeln

      // Variante A: Änderung schlägt Löschung
      if (lc == ChangeKind.removed && rc != ChangeKind.removed) {
        // remote hat geändert, lokal gelöscht -> remote gewinnt
        if (r != null) result[id] = r;
        continue;
      }
      if (rc == ChangeKind.removed && lc != ChangeKind.removed) {
        // lokal hat geändert, remote gelöscht -> lokal gewinnt
        if (l != null) result[id] = l;
        continue;
      }

      // 5) Beide added (id neu auf beiden Seiten)
      if (b == null && l != null && r != null) {
        // Hier musst du eine Strategie wählen; wir nehmen erstmal: lokal gewinnt.
        result[id] = l;
        continue;
      }

      // 6) Beide modified (von gleicher Baseline aus)
      if (lc == ChangeKind.modified && rc == ChangeKind.modified) {
        // Konfliktstrategie: aktuell gewinnt REMOTE.
        // Wenn du lieber lokal gewinnen lassen willst, einfach auf `l!` ändern.
        result[id] = r!;
        continue;
      }
    }

    return result.values.toList(growable: false);
  }

  Map<String, Cruise> _byId(List<Cruise> list) =>
      {for (final c in list) c.id: c};

  ChangeKind _classifyChange(Cruise? base, Cruise? next) {
    if (base == null && next == null) return ChangeKind.unchanged;
    if (base == null && next != null) return ChangeKind.added;
    if (base != null && next == null) return ChangeKind.removed;
    // base & next != null
    return base == next ? ChangeKind.unchanged : ChangeKind.modified;
  }
}

enum ChangeKind { unchanged, added, removed, modified }
