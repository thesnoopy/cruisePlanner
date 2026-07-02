import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_document_analysis_settings.dart';

class AiDocumentAnalysisSettingsStore {
  static const _key = 'ai_document_analysis_settings_json_v1';

  final FlutterSecureStorage _storage;

  const AiDocumentAnalysisSettingsStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                migrateOnAlgorithmChange: true,
                migrateWithBackup: true,
              ),
            );

  Future<AiDocumentAnalysisSettings?> load() async {
    final json = await _storage.read(key: _key);
    if (json == null || json.isEmpty) {
      return null;
    }
    return AiDocumentAnalysisSettings.fromJson(json);
  }

  Future<void> save(AiDocumentAnalysisSettings settings) async {
    await _storage.write(key: _key, value: settings.toJson());
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
