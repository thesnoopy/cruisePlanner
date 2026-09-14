import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/settings/webdav_settings.dart';
import 'package:cruiseplanner/sync/cruise_persistence_migration.dart';
import 'package:cruiseplanner/sync/cruise_sync_service.dart';
import 'package:cruiseplanner/sync/webdav_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cruise_location_migration_test.dart' show legacyLocationPayload;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void webDavTest(String name, Future<void> Function(_DavServer) body) {
    test(name, () async {
      SharedPreferences.setMockInitialValues({});
      final server = await _DavServer.start();
      final overrides = _LoopbackHttpOverrides(server.server.port);
      try {
        await HttpOverrides.runWithHttpOverrides(() => body(server), overrides);
      } finally {
        overrides.close();
        await server.close();
      }
    });
  }

  webDavTest('migrates V3 remote and baseline before merging, backs up original, '
      'writes V4 and uses fresh ETags on subsequent sync', (server) async {
    final original = server.document!;
    final prefs = await SharedPreferences.getInstance();
    // V3 baselines used bare lists. Local data has already migrated on load.
    await prefs.setString('cruises_sync_baseline_v3',
        jsonEncode(legacyLocationPayload()['cruises']));
    final local = decodeCruisePersistenceData(legacyLocationPayload()).cruises;
    final webDav = WebDavSync(server.settings);
    final service = CruiseSyncService(webDav);
    final merged = await service.sync(local);
    expect(merged.single.locations, hasLength(2));
    expect(server.backups.single, original);
    expect((jsonDecode(server.document!) as Map)['schemaVersion'], 4);
    expect(server.putConditions, ['"v1"']);
    expect(webDav.currentETag, '"v2"');
    final baseline = jsonDecode(prefs.getString('cruises_sync_baseline_v3')!) as Map;
    expect(baseline['schemaVersion'], 4);
    expect(decodeCruisePersistenceData(baseline).cruises, merged);
    final second = await service.sync(merged);
    expect(second, merged);
    expect(server.putConditions, ['"v1"', '"v2"']);
    expect(webDav.currentETag, '"v3"');
  });

  webDavTest('newer remote schema is rejected without PUT, backup or baseline write',
      (server) async {
    server.document = jsonEncode(legacyLocationPayload()..['schemaVersion'] = 5);
    final original = server.document;
    final webDav = WebDavSync(server.settings);
    await expectLater(CruiseSyncService(webDav).sync(const []),
        throwsA(isA<RemoteCruiseSchemaTooNewException>()));
    // A caller cannot upload after a rejected download either.
    await expectLater(webDav.uploadCruises(const []), throwsStateError);
    expect(server.document, original);
    expect(server.putConditions, isEmpty);
    expect(server.backups, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cruises_sync_baseline_v3'), isNull);
  });

  webDavTest('concurrent remote update after download rejects migration PUT', (server) async {
    final prefs = await SharedPreferences.getInstance();
    final baseline = jsonEncode(legacyLocationPayload()['cruises']);
    await prefs.setString('cruises_sync_baseline_v3', baseline);
    server.changeBeforePut = true;
    final webDav = WebDavSync(server.settings);
    await expectLater(CruiseSyncService(webDav).sync(const []),
        throwsA(isA<RemoteCruiseConflictException>()));
    expect((jsonDecode(server.document!) as Map)['schemaVersion'], 5);
    expect(server.successfulPuts, 0);
    expect(webDav.currentETag, isNull);
    expect(prefs.getString('cruises_sync_baseline_v3'), baseline);
  });

  webDavTest('change between GET and second properties read aborts before backup',
      (server) async {
    server.changeAfterGet = true;
    await expectLater(CruiseSyncService(WebDavSync(server.settings)).sync(const []),
        throwsA(isA<RemoteCruiseConflictException>()));
    expect(server.putConditions, isEmpty);
    expect(server.backups, isEmpty);
  });

  webDavTest('unsupported COPY falls back to exact old bytes', (server) async {
    server.supportsCopy = false;
    final original = server.document;
    await CruiseSyncService(WebDavSync(server.settings)).sync(const []);
    expect(server.backups.single, original);
    expect(server.successfulPuts, 1);
  });

  webDavTest('missing remote uses If-None-Match and rejects concurrent creation',
      (server) async {
    server.document = null;
    server.changeBeforePut = true;
    await expectLater(CruiseSyncService(WebDavSync(server.settings)).sync(const []),
        throwsA(isA<RemoteCruiseConflictException>()));
    expect(server.createConditions, ['*']);
    expect(server.successfulPuts, 0);
  });

  webDavTest('missing remote can be created as V4', (server) async {
    server.document = null;
    await CruiseSyncService(WebDavSync(server.settings)).sync(const <Cruise>[]);
    expect(server.createConditions, ['*']);
    expect(server.successfulPuts, 1);
    expect((jsonDecode(server.document!) as Map)['schemaVersion'], 4);
  });

  for (final etag in ['', 'W/"v1"']) {
    webDavTest('missing or weak ETag refuses overwrite ($etag)', (server) async {
      server.etag = etag;
      final original = server.document;
      await expectLater(CruiseSyncService(WebDavSync(server.settings)).sync(const []),
          throwsStateError);
      expect(server.document, original);
      expect(server.putConditions, isEmpty);
      expect(server.backups, isEmpty);
    });
  }

  webDavTest('malformed and unknown-version remote data are never overwritten',
      (server) async {
    for (final document in ['{broken', '{"schemaVersion":"5","cruises":[]}']) {
      server.document = document;
      await expectLater(CruiseSyncService(WebDavSync(server.settings)).sync(const []),
          throwsFormatException);
      expect(server.document, document);
    }
    expect(server.putConditions, isEmpty);
    expect(server.backups, isEmpty);
  });

  webDavTest('properties/auth errors are not treated as a missing remote', (server) async {
    server.propertiesStatus = 403;
    await expectLater(CruiseSyncService(WebDavSync(server.settings)).sync(const []),
        throwsA(anything));
    expect(server.putConditions, isEmpty);
    expect(server.backups, isEmpty);
  });
}

/// Replace Flutter's test HTTP stub only inside each test's zone. Connections
/// are restricted to that test's local server; no external network or proxies.
class _LoopbackHttpOverrides extends HttpOverrides {
  _LoopbackHttpOverrides(this.port);

  final int port;
  final List<HttpClient> _clients = [];

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      if (uri.scheme != 'http' || uri.host != '127.0.0.1' ||
          uri.port != port || proxyHost != null || proxyPort != null) {
        throw StateError('WebDAV test connections must stay on its local server');
      }
      return Socket.startConnect(InternetAddress.loopbackIPv4, port);
    };
    _clients.add(client);
    return client;
  }

  void close() {
    for (final client in _clients) {
      client.close(force: true);
    }
  }
}

class _DavServer {
  _DavServer(this.server);

  final HttpServer server;
  late final StreamSubscription<HttpRequest> _requests;
  String? document = jsonEncode(legacyLocationPayload());
  String etag = '"v1"';
  final backups = <String>[];
  final putConditions = <String?>[];
  final createConditions = <String?>[];
  int successfulPuts = 0;
  bool supportsCopy = true;
  bool changeBeforePut = false;
  bool changeAfterGet = false;
  int? propertiesStatus;

  WebDavSettings get settings => WebDavSettings(
    baseUrl: 'http://127.0.0.1:${server.port}',
    username: 'user', password: 'password', remotePath: '/sync/cruises.json',
  );

  static Future<_DavServer> start() async {
    final result = _DavServer(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    result._requests = result.server.listen(result.handle);
    return result;
  }

  Future<void> close() async {
    await server.close(force: true);
    await _requests.cancel();
  }

  void changeDocument() {
    document = jsonEncode(legacyLocationPayload()..['schemaVersion'] = 5);
    etag = '"concurrent"';
  }

  Future<void> handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final response = request.response;
    switch (request.method) {
      case 'OPTIONS':
        response.statusCode = 200;
        break;
      case 'MKCOL':
        response.statusCode = 201;
        break;
      case 'PROPFIND':
        if (propertiesStatus != null || document == null) {
          response.statusCode = propertiesStatus ?? 404;
          break;
        }
        response.statusCode = 207;
        response.headers.contentType = ContentType('application', 'xml', charset: 'utf-8');
        response.write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:"><d:response>
<d:href>/sync/cruises.json</d:href><d:propstat><d:prop>
<d:resourcetype/><d:getcontentlength>${utf8.encode(document!).length}</d:getcontentlength>
<d:getetag>$etag</d:getetag></d:prop>
<d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>''');
        break;
      case 'GET':
        response.headers.contentType = ContentType.json;
        response.write(document);
        if (changeAfterGet) changeDocument();
        break;
      case 'COPY':
        if (!supportsCopy) {
          response.statusCode = 405;
        } else if (request.headers.value('if-match') != etag) {
          response.statusCode = 412;
        } else {
          backups.add(document!);
          response.statusCode = 201;
        }
        break;
      case 'PUT':
        if (request.uri.path.contains('/old/')) {
          backups.add(body);
          response.statusCode = 201;
          break;
        }
        final match = request.headers.value('if-match');
        final noneMatch = request.headers.value('if-none-match');
        if (match != null) putConditions.add(match);
        if (noneMatch != null) createConditions.add(noneMatch);
        if (changeBeforePut) changeDocument();
        if ((document == null && noneMatch == '*') ||
            (document != null && match == etag)) {
          document = body;
          successfulPuts++;
          etag = '"v${successfulPuts + 1}"';
          response.headers.set('etag', etag);
          response.statusCode = 204;
        } else {
          response.statusCode = 412;
        }
        break;
      default:
        response.statusCode = 405;
    }
    await response.close();
  }
}
