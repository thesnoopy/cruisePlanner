import 'dart:convert';
import 'dart:typed_data';

import 'package:webdav_client/webdav_client.dart' as webdav;

import '../models/cruise.dart';
import '../settings/webdav_settings.dart';

/// Metadaten zur Remote-Datei (für spätere Erweiterungen wie ETag / mTime)
class RemoteInfo {
  final DateTime? mTimeUtc;
  final String? eTag;

  const RemoteInfo({this.mTimeUtc, this.eTag});
}

/// Low-Level WebDAV‑Zugriff für die Cruise-JSON-Datei.
///
/// Diese Klasse kennt nur:
///  * Wo liegt die Datei (Base URL + Pfad)
///  * Wie liest/schreibt man die JSON-Struktur {"cruises":[...]}
///
/// Die eigentliche Merge-Logik steckt in [CruiseSyncService].
class WebDavSync {
  final WebDavSettings settings;

  WebDavSync(this.settings);

  webdav.Client _createClient() {
    final client = webdav.newClient(
      settings.baseUrl,
      user: settings.username,
      password: settings.password,
      debug: false,
    );
    client.setHeaders({
      'accept-charset': 'utf-8',
      'content-type': 'application/json',
    });
    // Timeouts optional; kannst du bei Bedarf anpassen
    client.setConnectTimeout(8000);
    client.setSendTimeout(8000);
    client.setReceiveTimeout(8000);
    return client;
  }

  /// Ließt die Properties der Remote-Datei (falls vorhanden).
  ///
  /// Aktuell noch nicht im Merge genutzt, aber vorbereitet für ETag-basierte
  /// Optimierungen.
  Future<RemoteInfo?> stat() async {
    final client = _createClient();
    try {
      final file = await client.readProps(settings.remotePath);
      return RemoteInfo(
        mTimeUtc: file.mTime,
        eTag: file.eTag,
      );
    } catch (_) {
      // z.B. 404 -> Datei existiert (noch) nicht
      return null;
    }
  }

  /// Lädt die Cruises aus der Remote-Datei.
  ///
  /// Erwartetes Format:
  ///   { "cruises": [ {..Cruise.toMap()..}, ... ] }
  ///
  /// Falls die Datei nicht existiert, wird eine leere Liste zurückgegeben.
  Future<List<Cruise>> downloadCruises() async {
    final client = _createClient();
    try {
      final bytes = await client.read(settings.remotePath);
      if (bytes.isEmpty) return const <Cruise>[];

      final data = Uint8List.fromList(bytes);
      final jsonStr = utf8.decode(data);
      final decoded = jsonDecode(jsonStr);

      final List<dynamic> list;
      if (decoded is Map<String, dynamic> && decoded['cruises'] is List) {
        list = decoded['cruises'] as List<dynamic>;
      } else if (decoded is List) {
        // Fallback: nackte Liste ohne Wrapper
        list = decoded;
      } else {
        return const <Cruise>[];
      }

      return list
          .map((e) => Cruise.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      // Wenn die Datei (noch) nicht existiert -> leere Liste.
      // Andere Fehler (Netzwerk, Auth, JSON) sollten nach außen sichtbar sein.
      final msg = e.toString();
      if (msg.contains('404') || msg.contains('Not Found')) {
        return const <Cruise>[];
      }
      rethrow;
    }
  }

  /// Schreibt die übergebene Liste von Cruises in die Remote-Datei.
  ///
  /// Format wie bei [downloadCruises]: {"cruises":[...]}.
  Future<void> uploadCruises(List<Cruise> cruises) async {
    final client = _createClient();
    final payload = <String, dynamic>{
      'cruises': cruises.map((c) => c.toMap()).toList(),
    };
    final jsonStr = jsonEncode(payload);
    final data = Uint8List.fromList(utf8.encode(jsonStr));
    await client.write(settings.remotePath, data);
  }
/*
  /// Einfache Union-Strategie (nur zur Rückwärtskompatibilität):
  /// Remote + Local nach id gemerged, lokal gewinnt.
  ///
  /// Für "vernünftigen" Sync zwischen mehreren Systemen solltest du
  /// stattdessen [CruiseSyncService] verwenden.
  Future<List<Cruise>> mergeRemoteIntoLocal(List<Cruise> local) async {
    final remote = await downloadCruises();
    final byId = {for (final c in remote) c.id: c};
    for (final c in local) {
      byId[c.id] = c;
    }
    final merged = byId.values.toList(growable: false);
    await uploadCruises(merged);
    return merged;
  }
  */
   Future<List<Cruise>> CruiseSyncService(List<Cruise> local) async {
    final remote = await downloadCruises();
    final byId = {for (final c in remote) c.id: c};
    for (final c in local) {
      byId[c.id] = c;
    }
    final merged = byId.values.toList(growable: false);
    await uploadCruises(merged);
    return merged;
  }
}
