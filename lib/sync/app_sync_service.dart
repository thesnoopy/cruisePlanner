import 'dart:convert';

import '../models/cruise.dart';
import '../models/documents/document_full_sync_execution_result.dart';
import '../models/documents/document_sync_execution_result.dart';
import '../services/documents/document_sync_execution_service.dart';
import '../settings/webdav_settings.dart';
import '../settings/webdav_settings_store.dart';
import 'cruise_sync_service.dart';
import 'webdav_sync.dart';
import 'package:flutter/foundation.dart';
import 'app_sync_progress.dart';

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
    Future<List<Cruise>> Function(WebDavSync webDav, List<Cruise> localCruises)?
        cruiseSyncRunner,
    Future<DocumentFullSyncExecutionResult> Function(
      WebDavSettings settings,
      AppSyncProgressCallback? onProgress,
    )?
        documentSyncRunner,
  }) : _settingsStore = settingsStore ?? const WebDavSettingsStore(),
       _cruiseSyncRunner = cruiseSyncRunner,
       _documentSyncRunner = documentSyncRunner;

  static Future<AppSyncResult>? _inFlightSync;
  static final Set<AppSyncProgressCallback> _progressListeners =
      <AppSyncProgressCallback>{};
  static AppSyncProgress? _currentProgress;

  @visibleForTesting
  static void resetDebugState() {
    _inFlightSync = null;
    _progressListeners.clear();
    _currentProgress = null;
  }

  final WebDavSettingsStore _settingsStore;
  final Future<List<Cruise>> Function(
    WebDavSync webDav,
    List<Cruise> localCruises,
  )? _cruiseSyncRunner;
  final Future<DocumentFullSyncExecutionResult> Function(
    WebDavSettings settings,
    AppSyncProgressCallback? onProgress,
  )? _documentSyncRunner;

  Future<AppSyncResult> sync({
    required List<Cruise> localCruises,
    AppSyncProgressCallback? onProgress,
  }) async {
    if (onProgress != null) {
      _progressListeners.add(onProgress);
      final currentProgress = _currentProgress;
      if (currentProgress != null) {
        onProgress(currentProgress);
      }
    }

    final inFlightSync = _inFlightSync;
    if (inFlightSync != null) {
      try {
        return await inFlightSync;
      } finally {
        if (onProgress != null) {
          _progressListeners.remove(onProgress);
        }
      }
    }

    final syncFuture = _performSync(localCruises: localCruises);
    _inFlightSync = syncFuture;

    try {
      return await syncFuture;
    } finally {
      if (onProgress != null) {
        _progressListeners.remove(onProgress);
      }
      if (identical(_inFlightSync, syncFuture)) {
        _inFlightSync = null;
      }
    }
  }

  Future<AppSyncResult> _performSync({
    required List<Cruise> localCruises,
  }) async {
    try {
      _emitProgress(AppSyncProgress.preparing());
      final settings = await _settingsStore.load();
      if (settings == null || !settings.isValid) {
        _emitProgress(AppSyncProgress.skipped());
        return const AppSyncResult.skipped();
      }

      final webDav = WebDavSync(settings);
      final mergedCruises = List<Cruise>.unmodifiable(
        await _runCruiseSync(webDav, localCruises),
      );

      final documentSyncResult = await _runDocumentSync(
        _documentSyncSettings(settings),
      );

      if (documentSyncResult.hasFailures) {
        _emitProgress(
          AppSyncProgress.failed(
            lastActiveStage: _currentNonTerminalStage(),
            failedStage: _failedStageForDocumentSyncResult(documentSyncResult),
          ),
        );
        return AppSyncResult.failed(
          failureMessage: _sanitizeFailureMessage(
            _documentFailureMessage(documentSyncResult),
          ),
          mergedCruises: mergedCruises,
          documentSyncResult: documentSyncResult,
        );
      }

      _emitProgress(
        AppSyncProgress.completed(
          lastActiveStage: _currentNonTerminalStage(),
        ),
      );
      return AppSyncResult.succeeded(
        mergedCruises: mergedCruises,
        documentSyncResult: documentSyncResult,
      );
    } catch (error) {
      _emitProgress(
        AppSyncProgress.failed(
          lastActiveStage: _currentNonTerminalStage(),
          failedStage: _currentRunningStage(),
        ),
      );
      return AppSyncResult.failed(
        failureMessage: _sanitizeFailureMessage(error.toString()),
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

  AppSyncProgressStage? _failedStageForDocumentSyncResult(
    DocumentFullSyncExecutionResult documentSyncResult,
  ) {
    if (documentSyncResult.hasAnalysisError) {
      return AppSyncProgressStage.documentMetadataAnalysis;
    }

    final failureStages = <AppSyncProgressStage>{};

    void collectFailures(DocumentSyncExecutionResult? result) {
      if (result == null) {
        return;
      }

      if (result.hasAnalysisError) {
        failureStages.add(AppSyncProgressStage.documentMetadataAnalysis);
      }

      for (final failure in result.failures) {
        final stage = _failedStageForAction(failure.action);
        if (stage != null) {
          failureStages.add(stage);
        }
      }
    }

    collectFailures(documentSyncResult.phase3Result);
    collectFailures(documentSyncResult.phase4Result);
    collectFailures(documentSyncResult.phase5Result);
    collectFailures(documentSyncResult.phase6Result);

    if (failureStages.length != 1) {
      return null;
    }

    return failureStages.single;
  }

  AppSyncProgressStage? _failedStageForAction(
    DocumentSyncExecutionAction action,
  ) {
    return switch (action) {
      DocumentSyncExecutionAction.upload => AppSyncProgressStage.documentUploads,
      DocumentSyncExecutionAction.download =>
        AppSyncProgressStage.documentDownloads,
      DocumentSyncExecutionAction.localFileRecovery =>
        AppSyncProgressStage.localDocumentRecovery,
      DocumentSyncExecutionAction.localSoftDeletePropagation ||
      DocumentSyncExecutionAction.remoteSoftDeletePropagation =>
        AppSyncProgressStage.deletionPropagation,
      DocumentSyncExecutionAction.cleanupHardDelete =>
        AppSyncProgressStage.cleanup,
    };
  }

  Future<List<Cruise>> _runCruiseSync(
    WebDavSync webDav,
    List<Cruise> localCruises,
  ) async {
    _emitProgress(AppSyncProgress.cruiseDataSync());
    final runner = _cruiseSyncRunner;
    if (runner != null) {
      return runner(webDav, localCruises);
    }

    final cruiseSyncService = CruiseSyncService(webDav);
    return cruiseSyncService.sync(localCruises);
  }

  Future<DocumentFullSyncExecutionResult> _runDocumentSync(
    WebDavSettings settings,
  ) async {
    final runner = _documentSyncRunner;
    if (runner != null) {
      return runner(settings, _emitProgress);
    }

    final documentSyncService = DocumentSyncExecutionService.fromSettings(
      settings: settings,
      onProgress: _emitProgress,
    );
    return documentSyncService.executeFullSync();
  }

  void _emitProgress(AppSyncProgress progress) {
    _currentProgress = progress;
    final listeners = List<AppSyncProgressCallback>.from(_progressListeners);
    for (final listener in listeners) {
      listener(progress);
    }
  }

  AppSyncProgressStage _currentNonTerminalStage() {
    final currentProgress = _currentProgress;
    if (currentProgress == null) {
      return AppSyncProgressStage.preparing;
    }

    return currentProgress.displayStage;
  }

  AppSyncProgressStage? _currentRunningStage() {
    final currentProgress = _currentProgress;
    if (currentProgress == null || currentProgress.isTerminal) {
      return null;
    }

    return currentProgress.stage;
  }

  String _sanitizeFailureMessage(String failureMessage) {
    var sanitized = failureMessage;
    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'(authorization\s*[:=]\s*)(?:basic|bearer)\s+[^\s,;]+',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}***',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(password\s*[:=]\s*)([^\s,;]+)', caseSensitive: false),
      (match) => '${match.group(1)}***',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(bearer\s+)([^\s,;]+)', caseSensitive: false),
      (match) => '${match.group(1)}***',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(basic\s+)([^\s,;]+)', caseSensitive: false),
      (match) {
        final prefix = match.group(1)!;
        final candidate = match.group(2)!;
        if (_isBasicCredentialCandidate(candidate)) {
          return '${prefix}***';
        }
        return match.group(0)!;
      },
    );
    return sanitized;
  }

  bool _isBasicCredentialCandidate(String candidate) {
    try {
      final normalized = base64.normalize(candidate);
      final decodedBytes = base64.decode(normalized);
      final decoded = utf8.decode(decodedBytes);
      final separatorIndex = decoded.indexOf(':');
      return separatorIndex > 0 && separatorIndex < decoded.length - 1;
    } catch (_) {
      return false;
    }
  }
}
