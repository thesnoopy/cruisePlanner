import 'dart:convert';
import 'dart:typed_data';
import 'package:webdav_client/webdav_client.dart' as wd;
import 'package:http/http.dart' as http;

import '../models/cruise.dart';
import '../settings/webdav_settings.dart';

class RemoteInfo {
  final DateTime? mTimeUtc;
  final String? eTag;
  const RemoteInfo({this.mTimeUtc, this.eTag});
}

class WebDavSync {
  final WebDavSettings settings;
  WebDavSync(this.settings);

  wd.Client _client() {
    final c = wd.newClient(
      settings.baseUrl,              // z.B. https://host/remote.php/dav/files/USER/
      user: settings.username,
      password: settings.password,
      debug: false,
    );
    // Sinnvolle Defaults
    c.setHeaders({
      'accept-charset': 'utf-8',
      'content-type': 'application/json',
    });
    c.setConnectTimeout(10000);
    c.setSendTimeout(10000);
    c.setReceiveTimeout(15000);
    return c;
  }

  /// Hilfsfunktion: normalisiert remotePath (führtenden Slash, keine doppelten Slashes)
  String _normPath(String path) {
    var p = path.trim();
    if (!p.startsWith('/')) p = '/$p';
    // "/a//b///c" -> "/a/b/c"
    p = p.replaceAll(RegExp(r'/+'), '/');
    return p;
  }

  /// Liefert (dirPath, fileName) aus remotePath
  (String dir, String file) _splitDirAndFile(String remotePath) {
    final norm = _normPath(remotePath);
    final parts = norm.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) {
      // Fallback: direkt im Root speichern
      return ('/', 'cruises.json');
    }
    final file = parts.last;
    final dir = '/${parts.take(parts.length - 1).join('/')}';
    return (dir.isEmpty ? '/' : dir, file);
  }

  // Baut die vollständige Datei-URL aus baseUrl + normalisiertem remotePath
  String _fileUrl() {
    final base = settings.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final path = _normPath(settings.remotePath);
    return '$base$path';
  }

  Map<String, String> _basicAuthHeaders([Map<String, String>? extra]) {
    final basic = 'Basic ${base64Encode(utf8.encode('${settings.username}:${settings.password}'))}';
    return {'Authorization': basic, ...?extra};
  }

  Future<void> _httpPut(Uint8List data, {String? ifMatchETag}) async {
    final url = Uri.parse(_fileUrl());
    final headers = {
      'Content-Type': 'application/json',
      ..._basicAuthHeaders(),
      if (ifMatchETag != null) 'If-Match': _prepareIfMatch(ifMatchETag)!,
    };
    final res = await http.put(url, headers: headers, body: data);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('WebDAV PUT failed ${res.statusCode}: ${res.reasonPhrase} | body=${res.body}');
    }
  }

  /// Legt Ordnerhierarchie für remotePath an (ohne Datei)
  Future<void> _ensureRemoteFolder(wd.Client client, String remotePath) async {
    final (dir, _) = _splitDirAndFile(remotePath);
    if (dir == '/' || dir.isEmpty) return;

    // rekursiv anlegen: /CruiseApp[/sub/...]
    final segs = dir.split('/').where((s) => s.isNotEmpty).toList();
    var current = '';
    for (final s in segs) {
      current = '$current/$s';
      final exists = await _exists(client, current);
      if (!exists) {
        // mkdir ist idempotent; einige Server geben 405, wenn vorhanden
        try {
          await client.mkdir(current);
        } catch (_) {
          // Ignorieren, falls der Ordner doch existiert
        }
      }
    }
  }

  Future<bool> _exists(wd.Client client, String path) async {
    try {
      await client.readProps(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _prepareIfMatch(String? etag) {
    if (etag == null) return null;
    var v = etag.trim();
    if (v.startsWith('W/')) v = v.substring(2).trim(); // weak → strong
    if (!v.startsWith('"')) v = '"$v"';
    return v;
  }

  /// Verbindungs-/Auth-Check
  Future<void> ping() async {
    final client = _client();
    await client.ping();
  }

  /// Props der Zieldatei
  Future<RemoteInfo?> statRemote() async {
    final client = _client();
    final path = _normPath(settings.remotePath);
    try {
      final f = await client.readProps(path);
      return RemoteInfo(
        mTimeUtc: f.mTime?.toUtc(),
        eTag: f.eTag,
      );
    } catch (_) {
      return null; // Datei existiert nicht o. ä.
    }
  }

  /// Download als Liste<Cruise>
  Future<List<Cruise>> downloadCruises() async {
    final client = _client();
    final path = _normPath(settings.remotePath);
    final bytes = await client.read(path);           // Uint8List
    final jsonStr = utf8.decode(bytes);
    final decoded = jsonDecode(jsonStr);
    final List<dynamic> list = decoded is Map<String, dynamic>
        ? (decoded['cruises'] as List<dynamic>? ?? const [])
        : (decoded as List<dynamic>);
    return list
        .whereType<Map>()
        .map((e) => Cruise.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

    Future<void> uploadCruises(List<Cruise> cruises, {String? ifMatchETag}) async {
    final client = _client();
    final path = _normPath(settings.remotePath);

    // Ordner sicherstellen (ohne If-Match-Header!)
    await _ensureRemoteFolder(client, path);

    // Body wie lokal: {"cruises":[...]}
    final body = jsonEncode({
      'cruises': cruises.map((c) => c.toMap()).toList(growable: false),
    });
    final data = Uint8List.fromList(utf8.encode(body));

    if (ifMatchETag == null) {
      // Neuerstellung / erstes Hochladen: simpler write() ohne If-Match
      await client.write(path, data);
    } else {
      // Update mit Konkurrenzschutz: reiner HTTP PUT + If-Match (keine MKCOL-Versuche)
      await _httpPut(data, ifMatchETag: ifMatchETag);
    }
  }


  /// Einfache Merge-Strategie: Union nach id, lokal gewinnt
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
}
