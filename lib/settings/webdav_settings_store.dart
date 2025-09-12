import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'webdav_settings.dart';

class WebDavSettingsStore {
  static const _key = 'webdav_settings_json_v1';
  final FlutterSecureStorage _sec;

  const WebDavSettingsStore([FlutterSecureStorage? storage])
      : _sec = storage ?? const FlutterSecureStorage();

  Future<WebDavSettings?> load() async {
    final json = await _sec.read(key: _key);
    if (json == null || json.isEmpty) return null;
    return WebDavSettings.fromJson(json);
    }

  Future<void> save(WebDavSettings s) async {
    await _sec.write(key: _key, value: s.toJson());
  }

  Future<void> clear() async {
    await _sec.delete(key: _key);
  }
}
