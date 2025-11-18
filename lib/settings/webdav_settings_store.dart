
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'webdav_settings.dart';

class WebDavSettingsStore {
  static const _key = 'webdav_settings_json_v1';

  /// Secure Storage Instanz – Standard ist die Default-Implementierung.
  final FlutterSecureStorage _storage;

  const WebDavSettingsStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Lädt die gespeicherten Settings (oder null, wenn nichts gespeichert ist).
  Future<WebDavSettings?> load() async {
    final json = await _storage.read(key: _key);
    if (json == null || json.isEmpty) return null;
    return WebDavSettings.fromJson(json);
  }

  /// Speichert die Settings als JSON.
  Future<void> save(WebDavSettings settings) async {
    await _storage.write(key: _key, value: settings.toJson());
  }

  /// Löscht die gespeicherten Settings.
  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
