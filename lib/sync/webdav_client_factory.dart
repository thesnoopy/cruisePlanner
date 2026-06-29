import 'package:webdav_client/webdav_client.dart' as webdav;

import '../settings/webdav_settings.dart';

const int webDavConnectTimeoutMs = 30000;
const int webDavSendTimeoutMs = 120000;
const int webDavReceiveTimeoutMs = 120000;

webdav.Client createConfiguredWebDavClient(
  WebDavSettings settings, {
  Map<String, String> headers = const <String, String>{},
}) {
  final client = webdav.newClient(
    settings.baseUrl,
    user: settings.username,
    password: settings.password,
    debug: false,
  );
  if (headers.isNotEmpty) {
    client.setHeaders(headers);
  }
  client.setConnectTimeout(webDavConnectTimeoutMs);
  client.setSendTimeout(webDavSendTimeoutMs);
  client.setReceiveTimeout(webDavReceiveTimeoutMs);
  return client;
}
