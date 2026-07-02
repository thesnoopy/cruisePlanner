import 'package:cruiseplanner/settings/ai_document_analysis_settings.dart';
import 'package:cruiseplanner/settings/ai_document_analysis_settings_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiDocumentAnalysisSettings', () {
    test('round-trips JSON and keeps null fields trimmed', () {
      const settings = AiDocumentAnalysisSettings(
        enabled: true,
        provider: AiDocumentAnalysisProvider.gemini,
        apiKey: ' secret ',
        model: ' gemini-2.5-pro ',
        sendPdfWhenOcrIsInsufficient: true,
      );

      final decoded = AiDocumentAnalysisSettings.fromJson(settings.toJson());

      expect(decoded.enabled, isTrue);
      expect(decoded.provider, AiDocumentAnalysisProvider.gemini);
      expect(decoded.apiKey, 'secret');
      expect(decoded.model, 'gemini-2.5-pro');
      expect(decoded.sendPdfWhenOcrIsInsufficient, isTrue);
    });

    test('falls back to disabled defaults for missing or unknown values', () {
      final settings = AiDocumentAnalysisSettings.fromMap(const {
        'provider': 'unknown-provider',
      });

      expect(settings.enabled, isFalse);
      expect(settings.provider, AiDocumentAnalysisProvider.openAi);
      expect(settings.apiKey, isNull);
      expect(settings.model, isNull);
      expect(settings.sendPdfWhenOcrIsInsufficient, isFalse);
    });
  });

  group('AiDocumentAnalysisSettingsStore', () {
    late FlutterSecureStorage storage;
    late AiDocumentAnalysisSettingsStore store;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({
        'webdav_settings_json_v1': '{"baseUrl":"https://example.com"}',
      });
      storage = const FlutterSecureStorage();
      store = AiDocumentAnalysisSettingsStore(storage: storage);
    });

    test('loads null when no AI settings were saved yet', () async {
      final loaded = await store.load();

      expect(loaded, isNull);
      expect(
        await storage.read(key: 'webdav_settings_json_v1'),
        '{"baseUrl":"https://example.com"}',
      );
    });

    test('saves, loads, and clears AI settings without touching WebDAV data', () async {
      const settings = AiDocumentAnalysisSettings(
        enabled: true,
        provider: AiDocumentAnalysisProvider.custom,
        apiKey: 'abc123',
        model: 'document-v1',
        sendPdfWhenOcrIsInsufficient: true,
      );

      await store.save(settings);

      final loaded = await store.load();

      expect(loaded, settings);
      expect(
        await storage.read(key: 'webdav_settings_json_v1'),
        '{"baseUrl":"https://example.com"}',
      );

      await store.clear();

      expect(await store.load(), isNull);
      expect(
        await storage.read(key: 'webdav_settings_json_v1'),
        '{"baseUrl":"https://example.com"}',
      );
    });
  });
}
