import 'dart:convert';
import 'dart:typed_data';

import 'package:webdav_client/webdav_client.dart' as webdav;

import '../models/cruise.dart';
import '../settings/webdav_settings.dart';
import 'webdav_client_factory.dart';
import 'cruise_persistence_migration.dart';
import 'cruise_sync_service.dart';

export 'cruise_persistence_migration.dart'
    show RemoteCruiseSchemaTooNewException;

/// Metadaten zur Remote-Datei (für spätere Erweiterungen wie ETag / mTime)
class RemoteInfo {
  final DateTime? mTimeUtc;
  final String? eTag;

  const RemoteInfo({this.mTimeUtc, this.eTag});
}

class RemoteCruiseConflictException implements Exception {
  const RemoteCruiseConflictException();

  @override
  String toString() => 'Remote cruise data changed during sync. Sync aborted; retry.';
}

/// Low-Level WebDAV‑Zugriff für die Cruise-JSON-Datei.
///
/// Diese Klasse kennt nur:
///  * Wo liegt die Datei (Base URL + Pfad)
///  * Wie liest/schreibt man die JSON-Struktur {"cruises":[...]}
///
/// Die eigentliche Merge-Logik steckt in [CruiseSyncService].
class WebDavSync {
  static const int supportedCruiseSchemaVersion = currentCruiseSchemaVersion;

  final WebDavSettings settings;

  WebDavSync(this.settings);
  bool _hasValidatedDownload = false;
  String? _downloadETag;
  Uint8List? _downloadBytes;

  /// Updated after a successful write; never reuse the pre-upload ETag.
  String? get currentETag => _downloadETag;

  webdav.Client _createClient() {
    return createConfiguredWebDavClient(
      settings,
      headers: const <String, String>{
        'accept-charset': 'utf-8',
        'content-type': 'application/json',
      },
    );
  }

  /// Reads remote properties; only HTTP 404 represents a missing document.
  Future<RemoteInfo?> stat() => _readRemoteInfo(_createClient());

  /// Lädt die Cruises aus der Remote-Datei.
  ///
  /// Erwartetes Format:
  ///   { "cruises": [ {..Cruise.toMap()..}, ... ] }
  ///
  /// Falls die Datei nicht existiert, wird eine leere Liste zurückgegeben.
  Future<List<Cruise>> downloadCruises() async {
    _hasValidatedDownload = false;
    _downloadETag = null;
    _downloadBytes = null;
    final client = _createClient();
    // Properties bracket the GET so the captured ETag belongs to these bytes.
    final before = await _readRemoteInfo(client);
    if (before == null) {
      _hasValidatedDownload = true;
      return const [];
    }
    final bytes = Uint8List.fromList(await client.read(settings.remotePath));
    final after = await _readRemoteInfo(client);
    if (after == null || before.eTag != after.eTag) {
      throw const RemoteCruiseConflictException();
    }
    final data = decodeCruisePersistenceData(jsonDecode(utf8.decode(bytes)));
    _downloadETag = after.eTag;
    _downloadBytes = bytes;
    _hasValidatedDownload = true;
    return data.cruises;
  }

  Future<RemoteInfo?> _readRemoteInfo(webdav.Client client) async {
    try {
      final file = await client.readProps(settings.remotePath);
      return RemoteInfo(eTag: file.eTag, mTimeUtc: file.mTime);
    } catch (error) {
      // The client's readProps throws a Dio error with the HTTP status.
      // Never treat authentication, transport or malformed JSON as empty data.
      if (_httpStatus(error) == 404) return null;
      rethrow;
    }
  }

  int? _httpStatus(Object error) {
    // webdav_client exposes no typed status exception in its public API.
    try {
      return (error as dynamic).response?.statusCode as int?;
    } catch (_) {
      return null;
    }
  }

  Future<void> uploadCruises(List<Cruise> cruises) async {
    if (!_hasValidatedDownload) {
      throw StateError('A validated remote download is required before upload');
    }
    final payload = cruiseStoragePayload(cruises);
    final previousBytes = _downloadBytes;
    final previousETag = _downloadETag;
    // Fail closed on servers without a strong ETag: an unconditional PUT
    // could overwrite changes (including a newer schema) made after the GET.
    if (previousBytes != null &&
        (previousETag == null || previousETag.isEmpty ||
            previousETag.startsWith('W/'))) {
      throw StateError('WebDAV must provide a strong ETag for cruise sync');
    }
    _hasValidatedDownload = false;
    _downloadETag = null;
    final client = _createClient();
    if (previousBytes == null) {
      await client.mkdirAll(_parentDir(settings.remotePath));
    }
    await _backupCurrentRemoteFileIfExists(client, previousBytes, previousETag);
    final jsonStr = jsonEncode(payload);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    // Use the existing authenticated WebDAV transport, with conditions only
    // on this PUT (not on OPTIONS, MKCOL, or backup writes).
    final response = await client.c.req(
      client, 'PUT', settings.remotePath,
      // A string can be replayed by the client's authentication retry.
      data: jsonStr,
      optionsHandler: (options) {
        options.headers?['content-length'] = bytes.length;
        options.headers?['content-type'] = 'application/json; charset=utf-8';
        if (previousBytes == null) {
          options.headers?['If-None-Match'] = '*';
        } else {
          options.headers?['If-Match'] = previousETag;
        }
      },
    );
    if (response.statusCode == 412) {
      throw const RemoteCruiseConflictException();
    }
    if (![200, 201, 204].contains(response.statusCode)) {
      throw StateError('Cruise upload failed (HTTP ${response.statusCode})');
    }
    _downloadETag = response.headers.value('etag');
    _downloadBytes = bytes;
    // The next sync always downloads again before merging/writing.
  }

  /// Sichert die aktuell vorhandene Remote-Datei in einem "old"-Ordner,
  /// bevor sie überschrieben wird.
  ///
  /// Zielpfad: `<parent>/old/<filename>_<yyyyMMdd_HHmmss>.json`
  ///
  /// Falls die Remote-Datei nicht existiert, passiert nichts.
  Future<void> _backupCurrentRemoteFileIfExists(
    webdav.Client client, Uint8List? previousBytes, String? previousETag,
  ) async {
    if (previousBytes == null) return;
    final remotePath = _normalizePath(settings.remotePath);
    final parentDir = _parentDir(remotePath);
    final oldDir = _joinPath(parentDir, 'old');

    // Ensure "old" directory exists (ignore if already there).
    try {
      await client.mkdir(oldDir);
    } catch (_) {
      // Server may return 405/409 or similar if it already exists; ignore.
    }

    final backupFileName = _backupFileName(_baseName(remotePath));
    final backupPath = _joinPath(oldDir, backupFileName);

    // Preserve the exact representation read before migration. Prefer the
    // existing server-side COPY, conditioned on the source snapshot's ETag.
    try {
      final response = await client.c.req(
        client, 'COPY', remotePath,
        optionsHandler: (options) {
          final base = settings.baseUrl.replaceAll(RegExp(r'/+$'), '');
          options.headers?['destination'] = Uri.encodeFull('$base$backupPath');
          options.headers?['overwrite'] = 'F';
          options.headers?['If-Match'] = previousETag;
        },
      );
      if (![200, 201, 204].contains(response.statusCode)) {
        throw StateError('Remote backup COPY failed');
      }
    } catch (_) {
      // A changed source or unsupported COPY still permits backing up our
      // original bytes. The conditional PUT below will reject a changed source.
      await client.write(backupPath, previousBytes);
    }
  }

  String _backupFileName(String originalName) {
    final now = DateTime.now();
    final ts = '${_timestampForFileName(now)}_${now.microsecondsSinceEpoch}';
    final dot = originalName.lastIndexOf('.');
    if (dot <= 0 || dot == originalName.length - 1) {
      return '${originalName}_$ts';
    }
    final name = originalName.substring(0, dot);
    final ext = originalName.substring(dot); // includes '.'
    return '${name}_$ts$ext';
  }

  /// yyyyMMdd_HHmmss (lokale Zeit). Sicher für Dateinamen.
  String _timestampForFileName(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final m = two(dt.month);
    final d = two(dt.day);
    final hh = two(dt.hour);
    final mm = two(dt.minute);
    final ss = two(dt.second);
    return '$y$m${d}_$hh$mm$ss';
  }

  String _normalizePath(String p) {
    var s = p.trim();
    if (s.isEmpty) {
      return '/';
    }
    // WebDAV clients typically expect leading '/'
    if (!s.startsWith('/')) {
      s = '/$s';
    }
    // Collapse duplicate slashes
    while (s.contains('//')) {
      s = s.replaceAll('//', '/');
    }
    return s;
  }

  String _parentDir(String path) {
    final p = _normalizePath(path);
    final idx = p.lastIndexOf('/');
    if (idx <= 0) {
      return '/';
    }
    return p.substring(0, idx);
  }

  String _baseName(String path) {
    final p = _normalizePath(path);
    final idx = p.lastIndexOf('/');
    return idx >= 0 ? p.substring(idx + 1) : p;
  }

  String _joinPath(String a, String b) {
    final left = _normalizePath(a);
    final right = b.trim().replaceAll('\n', '').replaceAll('\r', '');
    if (left == '/') {
      return '/$right'.replaceAll('//', '/');
    }
    return '$left/$right'.replaceAll('//', '/');
  }

  Future<List<Cruise>> cruiseSyncService(List<Cruise> local) =>
      CruiseSyncService(this).sync(local);
}
