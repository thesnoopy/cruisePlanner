import 'dart:async';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_full_sync_execution_result.dart';
import 'package:cruiseplanner/models/documents/document_sync_execution_result.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/settings/webdav_settings.dart';
import 'package:cruiseplanner/settings/webdav_settings_store.dart';
import 'package:cruiseplanner/sync/app_sync_progress.dart';
import 'package:cruiseplanner/sync/app_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AppSyncService.resetDebugState);

  test('emits real sync stages in order and completes', () async {
    final emitted = <AppSyncProgress>[];
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async => localCruises,
      documentSyncRunner: (settings, onProgress) async {
        onProgress?.call(AppSyncProgress.documentMetadataAnalysis());
        onProgress?.call(AppSyncProgress.documentUploads(totalItems: 2));
        onProgress?.call(AppSyncProgress.documentDownloads(totalItems: 1));
        onProgress?.call(AppSyncProgress.localDocumentRecovery(totalItems: 0));
        onProgress?.call(AppSyncProgress.deletionPropagation(totalItems: 1));
        onProgress?.call(AppSyncProgress.cleanup(totalItems: 0));
        return const _SuccessfulDocumentSyncResult();
      },
    );

    final result = await service.sync(
      localCruises: <Cruise>[_sampleCruise()],
      onProgress: emitted.add,
    );

    expect(result.hasFailures, isFalse);
    expect(result.wasSkipped, isFalse);
    expect(
      emitted.map((progress) => progress.stage),
      <AppSyncProgressStage>[
        AppSyncProgressStage.preparing,
        AppSyncProgressStage.cruiseDataSync,
        AppSyncProgressStage.documentMetadataAnalysis,
        AppSyncProgressStage.documentUploads,
        AppSyncProgressStage.documentDownloads,
        AppSyncProgressStage.localDocumentRecovery,
        AppSyncProgressStage.deletionPropagation,
        AppSyncProgressStage.cleanup,
        AppSyncProgressStage.completed,
      ],
    );
  });

  test('manual sync attaches to active in-flight sync without running twice', () async {
    final cruiseSyncStarted = Completer<void>();
    final allowCruiseSyncToFinish = Completer<void>();
    var cruiseSyncRuns = 0;

    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async {
        cruiseSyncRuns += 1;
        cruiseSyncStarted.complete();
        await allowCruiseSyncToFinish.future;
        return localCruises;
      },
      documentSyncRunner: (settings, onProgress) async {
        onProgress?.call(AppSyncProgress.documentMetadataAnalysis());
        return const _SuccessfulDocumentSyncResult();
      },
    );

    final firstSync = service.sync(localCruises: <Cruise>[_sampleCruise()]);
    await cruiseSyncStarted.future;

    final attachedProgress = <AppSyncProgress>[];
    final secondSync = service.sync(
      localCruises: <Cruise>[_sampleCruise()],
      onProgress: attachedProgress.add,
    );

    allowCruiseSyncToFinish.complete();

    final firstResult = await firstSync;
    final secondResult = await secondSync;

    expect(firstResult.hasFailures, isFalse);
    expect(secondResult.hasFailures, isFalse);
    expect(cruiseSyncRuns, 1);
    expect(attachedProgress.first.stage, AppSyncProgressStage.cruiseDataSync);
    expect(attachedProgress.last.stage, AppSyncProgressStage.completed);
  });

  test('maps upload failures to upload stage even when later phases run', () async {
    final emitted = <AppSyncProgress>[];
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async => localCruises,
      documentSyncRunner: (settings, onProgress) async {
        onProgress?.call(AppSyncProgress.documentMetadataAnalysis());
        onProgress?.call(AppSyncProgress.documentUploads(totalItems: 2));
        onProgress?.call(AppSyncProgress.documentDownloads(totalItems: 1));
        onProgress?.call(AppSyncProgress.localDocumentRecovery(totalItems: 1));
        onProgress?.call(AppSyncProgress.deletionPropagation(totalItems: 1));
        onProgress?.call(AppSyncProgress.cleanup(totalItems: 1));
        return _documentResultWithPhaseFailures(
          phase3Failures: <DocumentSyncExecutionFailure>[
            const DocumentSyncExecutionFailure(
              documentId: 'doc-1',
              action: DocumentSyncExecutionAction.upload,
              errorMessage: 'Upload failed',
            ),
          ],
        );
      },
    );

    final result = await service.sync(
      localCruises: <Cruise>[_sampleCruise()],
      onProgress: emitted.add,
    );

    expect(result.hasFailures, isTrue);
    expect(emitted.last.stage, AppSyncProgressStage.failed);
    expect(emitted.last.failedStage, AppSyncProgressStage.documentUploads);
    expect(emitted.last.lastActiveStage, AppSyncProgressStage.cleanup);
  });

  test('maps download failures to download stage even when later phases run', () async {
    final emitted = <AppSyncProgress>[];
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async => localCruises,
      documentSyncRunner: (settings, onProgress) async {
        onProgress?.call(AppSyncProgress.documentMetadataAnalysis());
        onProgress?.call(AppSyncProgress.documentUploads(totalItems: 2));
        onProgress?.call(AppSyncProgress.documentDownloads(totalItems: 1));
        onProgress?.call(AppSyncProgress.localDocumentRecovery(totalItems: 1));
        onProgress?.call(AppSyncProgress.deletionPropagation(totalItems: 1));
        onProgress?.call(AppSyncProgress.cleanup(totalItems: 1));
        return _documentResultWithPhaseFailures(
          phase3Failures: <DocumentSyncExecutionFailure>[
            const DocumentSyncExecutionFailure(
              documentId: 'doc-2',
              action: DocumentSyncExecutionAction.download,
              errorMessage: 'Download failed',
            ),
          ],
        );
      },
    );

    final result = await service.sync(
      localCruises: <Cruise>[_sampleCruise()],
      onProgress: emitted.add,
    );

    expect(result.hasFailures, isTrue);
    expect(emitted.last.stage, AppSyncProgressStage.failed);
    expect(emitted.last.failedStage, AppSyncProgressStage.documentDownloads);
    expect(emitted.last.lastActiveStage, AppSyncProgressStage.cleanup);
  });

  test('keeps failedStage null when failures span multiple document stages', () async {
    final emitted = <AppSyncProgress>[];
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async => localCruises,
      documentSyncRunner: (settings, onProgress) async {
        onProgress?.call(AppSyncProgress.documentMetadataAnalysis());
        onProgress?.call(AppSyncProgress.documentUploads(totalItems: 1));
        onProgress?.call(AppSyncProgress.documentDownloads(totalItems: 1));
        onProgress?.call(AppSyncProgress.cleanup(totalItems: 0));
        return _documentResultWithPhaseFailures(
          phase3Failures: <DocumentSyncExecutionFailure>[
            const DocumentSyncExecutionFailure(
              documentId: 'doc-1',
              action: DocumentSyncExecutionAction.upload,
              errorMessage: 'Upload failed',
            ),
            const DocumentSyncExecutionFailure(
              documentId: 'doc-2',
              action: DocumentSyncExecutionAction.download,
              errorMessage: 'Download failed',
            ),
          ],
        );
      },
    );

    final result = await service.sync(
      localCruises: <Cruise>[_sampleCruise()],
      onProgress: emitted.add,
    );

    expect(result.hasFailures, isTrue);
    expect(emitted.last.stage, AppSyncProgressStage.failed);
    expect(emitted.last.failedStage, isNull);
  });

  test('sanitizes standalone basic credential in public sync result', () async {
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async {
        throw Exception('Basic dXNlcjpwYXNz failed');
      },
    );

    final result = await service.sync(localCruises: <Cruise>[_sampleCruise()]);

    expect(result.hasFailures, isTrue);
    expect(result.failureMessage, contains('Basic *** failed'));
    expect(result.failureMessage, isNot(contains('dXNlcjpwYXNz')));
  });

  test('sanitizes valid padded basic credential in public sync result', () async {
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async {
        throw Exception('Basic dGVzdDp4eA== failed');
      },
    );

    final result = await service.sync(localCruises: <Cruise>[_sampleCruise()]);

    expect(result.hasFailures, isTrue);
    expect(result.failureMessage, contains('Basic *** failed'));
    expect(result.failureMessage, isNot(contains('dGVzdDp4eA==')));
  });

  test('keeps basic authentication text readable in public sync result', () async {
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async {
        throw Exception('Basic authentication failed for remote sync');
      },
    );

    final result = await service.sync(localCruises: <Cruise>[_sampleCruise()]);

    expect(result.hasFailures, isTrue);
    expect(
      result.failureMessage,
      contains('Basic authentication failed for remote sync'),
    );
  });

  test('keeps arbitrary alphabetic word after basic unchanged', () async {
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async {
        throw Exception('Basic authenticationtoken failed');
      },
    );

    final result = await service.sync(localCruises: <Cruise>[_sampleCruise()]);

    expect(result.hasFailures, isTrue);
    expect(
      result.failureMessage,
      contains('Basic authenticationtoken failed'),
    );
  });

  test('sanitizes authorization basic header in public sync result', () async {
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async {
        throw Exception('Authorization: Basic dXNlcjpwYXNz');
      },
    );

    final result = await service.sync(localCruises: <Cruise>[_sampleCruise()]);

    expect(result.hasFailures, isTrue);
    expect(result.failureMessage, contains('Authorization: ***'));
    expect(result.failureMessage, isNot(contains('dXNlcjpwYXNz')));
    expect(result.failureMessage, isNot(contains('Basic dXNlcjpwYXNz')));
  });

  test('sanitizes authorization bearer header in public sync result', () async {
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async {
        throw Exception('Authorization: Bearer secret-token-123');
      },
    );

    final result = await service.sync(localCruises: <Cruise>[_sampleCruise()]);

    expect(result.hasFailures, isTrue);
    expect(result.failureMessage, contains('Authorization: ***'));
    expect(result.failureMessage, isNot(contains('secret-token-123')));
  });

  test('sanitizes bearer token in public sync result', () async {
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async {
        throw Exception('Bearer secret-token-123 failed');
      },
    );

    final result = await service.sync(localCruises: <Cruise>[_sampleCruise()]);

    expect(result.hasFailures, isTrue);
    expect(result.failureMessage, contains('Bearer *** failed'));
    expect(result.failureMessage, isNot(contains('secret-token-123')));
  });

  test('sanitizes password value in public sync result', () async {
    final service = AppSyncService(
      settingsStore: const _FakeWebDavSettingsStore(_validSettings),
      cruiseSyncRunner: (webDav, localCruises) async {
        throw Exception('login failed: password=topsecret');
      },
    );

    final result = await service.sync(localCruises: <Cruise>[_sampleCruise()]);

    expect(result.hasFailures, isTrue);
    expect(result.failureMessage, contains('password=***'));
    expect(result.failureMessage, isNot(contains('topsecret')));
  });
}

class _FakeWebDavSettingsStore extends WebDavSettingsStore {
  const _FakeWebDavSettingsStore(this._settings);

  final WebDavSettings? _settings;

  @override
  Future<WebDavSettings?> load() async => _settings;
}

class _SuccessfulDocumentSyncResult extends DocumentFullSyncExecutionResult {
  const _SuccessfulDocumentSyncResult()
      : super(
          analysis: null,
          analysisErrorMessage: null,
          executedPhases: const <DocumentSyncExecutionPhase>[],
          phase3Result: null,
          phase4Result: null,
          phase5Result: null,
          phase6Result: null,
        );
}

DocumentFullSyncExecutionResult _documentResultWithPhaseFailures({
  List<DocumentSyncExecutionFailure> phase3Failures =
      const <DocumentSyncExecutionFailure>[],
  List<DocumentSyncExecutionFailure> phase4Failures =
      const <DocumentSyncExecutionFailure>[],
  List<DocumentSyncExecutionFailure> phase5Failures =
      const <DocumentSyncExecutionFailure>[],
  List<DocumentSyncExecutionFailure> phase6Failures =
      const <DocumentSyncExecutionFailure>[],
}) {
  return DocumentFullSyncExecutionResult(
    analysis: null,
    analysisErrorMessage: null,
    executedPhases: const <DocumentSyncExecutionPhase>[
      DocumentSyncExecutionPhase.phase3UploadDownload,
      DocumentSyncExecutionPhase.phase4LocalFileRecovery,
      DocumentSyncExecutionPhase.phase5SoftDeletePropagation,
      DocumentSyncExecutionPhase.phase6CleanupHardDelete,
    ],
    phase3Result: _executionResult(phase3Failures),
    phase4Result: _executionResult(phase4Failures),
    phase5Result: _executionResult(phase5Failures),
    phase6Result: _executionResult(phase6Failures),
  );
}

DocumentSyncExecutionResult _executionResult(
  List<DocumentSyncExecutionFailure> failures,
) {
  return DocumentSyncExecutionResult(
    analysis: null,
    analysisErrorMessage: null,
    completedUploadDocumentIds: const <String>[],
    completedDownloadDocumentIds: const <String>[],
    completedLocalFileRecoveryDocumentIds: const <String>[],
    completedLocalSoftDeleteDocumentIds: const <String>[],
    completedRemoteSoftDeleteDocumentIds: const <String>[],
    completedHardDeleteDocumentIds: const <String>[],
    failures: failures,
  );
}

Cruise _sampleCruise() {
  final now = DateTime.utc(2026, 1, 1);
  return Cruise(
    id: 'cruise-1',
    title: 'Test Cruise',
    ship: Ship(name: 'Test Ship'),
    period: Period(
      start: now,
      end: now.add(const Duration(days: 7)),
    ),
    excursions: const [],
    travel: const [],
    route: const [],
  );
}

const WebDavSettings _validSettings = WebDavSettings(
  baseUrl: 'https://example.com/dav',
  username: 'user',
  password: 'secret',
  remotePath: '/sync/cruises.json',
);
