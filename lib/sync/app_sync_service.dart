import '../models/cruise.dart';
import '../models/documents/document_full_sync_execution_result.dart';
import '../services/documents/document_sync_execution_service.dart';
import '../settings/webdav_settings.dart';
import '../settings/webdav_settings_store.dart';
import 'cruise_sync_service.dart';
import 'webdav_sync.dart';

enum AppSyncOutcome {
  skipped,
  succeeded,
  failed,
}

class AppSyncResult {
  const AppSyncResult({
    required this.outcome,
    required this.mergedCruises,
    required this.documentSyncResult,
    required this.failureMessage,
  });

  const AppSyncResult.skipped()
      : outcome = AppSyncOutcome.skipped,
        mergedCruises = null,
        documentSyncResult = null,
        failureMessage = null;

  const AppSyncResult.succeeded({
    required List<Cruise> mergedCruises,
    required DocumentFullSyncExecutionResult documentSyncResult,
  }) : this(
         outcome: AppSyncOutcome.succeeded,
         mergedCruises: mergedCruises,
         documentSyncResult: documentSyncResult,
         failureMessage: null,
       );

  const AppSyncResult.failed({
    required String failureMessage,
    List<Cruise>? mergedCruises,
    DocumentFullSyncExecutionResult? documentSyncResult,
  }) : this(
         outcome: AppSyncOutcome.failed,
         mergedCruises: mergedCruises,
         documentSyncResult: documentSyncResult,
         failureMessage: failureMessage,
       );

  final AppSyncOutcome outcome;
  final List<Cruise>? mergedCruises;
  final DocumentFullSyncExecutionResult? documentSyncResult;
  final String? failureMessage;

  bool get wasSkipped => outcome == AppSyncOutcome.skipped;
  bool get hasFailures => outcome == AppSyncOutcome.failed;
}

class AppSyncService {
  const AppSyncService({
    WebDavSettingsStore? settingsStore,
  }) : _settingsStore = settingsStore ?? const WebDavSettingsStore();

  static Future<AppSyncResult>? _inFlightSync;

  final WebDavSettingsStore _settingsStore;

  Future<AppSyncResult> sync({
    required List<Cruise> localCruises,
  }) async {
    final inFlightSync = _inFlightSync;
    if (inFlightSync != null) {
      return inFlightSync;
    }

    final syncFuture = _performSync(localCruises: localCruises);
    _inFlightSync = syncFuture;

    try {
      return await syncFuture;
    } finally {
      if (identical(_inFlightSync, syncFuture)) {
        _inFlightSync = null;
      }
    }
  }

  Future<AppSyncResult> _performSync({
    required List<Cruise> localCruises,
  }) async {
    try {
      final settings = await _settingsStore.load();
      if (settings == null || !settings.isValid) {
        return const AppSyncResult.skipped();
      }

      final webDav = WebDavSync(settings);
      final cruiseSyncService = CruiseSyncService(webDav);
      final mergedCruises = List<Cruise>.unmodifiable(
        await cruiseSyncService.sync(localCruises),
      );

      final documentSyncService = DocumentSyncExecutionService.fromSettings(
        settings: _documentSyncSettings(settings),
      );
      final documentSyncResult = await documentSyncService.executeFullSync();

      if (documentSyncResult.hasFailures) {
        return AppSyncResult.failed(
          failureMessage: _documentFailureMessage(documentSyncResult),
          mergedCruises: mergedCruises,
          documentSyncResult: documentSyncResult,
        );
      }

      return AppSyncResult.succeeded(
        mergedCruises: mergedCruises,
        documentSyncResult: documentSyncResult,
      );
    } catch (error) {
      return AppSyncResult.failed(
        failureMessage: error.toString(),
      );
    }
  }

  WebDavSettings _documentSyncSettings(WebDavSettings settings) {
    return settings.copyWith(
      remotePath: _parentDirectory(settings.remotePath),
    );
  }

  String _parentDirectory(String path) {
    var normalized = path.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return '/';
    }
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    while (normalized.contains('//')) {
      normalized = normalized.replaceAll('//', '/');
    }

    final separatorIndex = normalized.lastIndexOf('/');
    if (separatorIndex <= 0) {
      return '/';
    }

    return normalized.substring(0, separatorIndex);
  }

  String _documentFailureMessage(
    DocumentFullSyncExecutionResult documentSyncResult,
  ) {
    if (documentSyncResult.hasAnalysisError) {
      return documentSyncResult.analysisErrorMessage ?? 'Document sync failed.';
    }

    final failures = documentSyncResult.failures;
    if (failures.isEmpty) {
      return 'Document sync failed.';
    }

    return failures.first.errorMessage;
  }
}
