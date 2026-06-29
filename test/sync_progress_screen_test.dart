import 'dart:async';

import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_full_sync_execution_result.dart';
import 'package:cruiseplanner/screens/sync/sync_progress_screen.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:cruiseplanner/sync/app_sync_progress.dart';
import 'package:cruiseplanner/sync/app_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'starts sync after first frame without build-phase notification exception',
    (tester) async {
      final completer = Completer<AppSyncResult>();
      late final _FakeCruiseStore store;
      store = _FakeCruiseStore(
        runAppSyncHandler: () {
          store.emitProgress(AppSyncProgress.preparing());
          return completer.future;
        },
      );

      await tester.pumpWidget(
        _TestApp(
          child: SyncProgressScreen(store: store),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(store.runAppSyncCallCount, 1);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Close'), findsNothing);

      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(store.runAppSyncCallCount, 1);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Close'), findsNothing);

      completer.complete(
        const AppSyncResult.succeeded(
          mergedCruises: <Cruise>[],
          documentSyncResult: _SuccessfulDocumentSyncResult(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(store.runAppSyncCallCount, 1);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Close'), findsOneWidget);
    },
  );

  testWidgets('keeps progress active until runAppSync future completes', (
    tester,
  ) async {
    final completer = Completer<AppSyncResult>();
    final store = _FakeCruiseStore(
      runAppSyncHandler: () => completer.future,
    );
    store.emitProgress(
      AppSyncProgress.completed(
        lastActiveStage: AppSyncProgressStage.cleanup,
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        child: SyncProgressScreen(store: store),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Close'), findsNothing);

    completer.complete(
      const AppSyncResult.succeeded(
        mergedCruises: <Cruise>[],
        documentSyncResult: _SuccessfulDocumentSyncResult(),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('shows failureMessage after manual sync failure', (tester) async {
    final completer = Completer<AppSyncResult>();
    final store = _FakeCruiseStore(
      runAppSyncHandler: () => completer.future,
    );
    store.emitProgress(
      AppSyncProgress.failed(
        lastActiveStage: AppSyncProgressStage.documentDownloads,
        failedStage: AppSyncProgressStage.documentDownloads,
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        child: SyncProgressScreen(store: store),
      ),
    );
    await tester.pump();

    completer.complete(
      const AppSyncResult.failed(
        failureMessage: 'Download failed',
      ),
    );
    await tester.pump();

    expect(find.text('Download failed'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

class _FakeCruiseStore extends CruiseStore {
  _FakeCruiseStore({
    required Future<AppSyncResult> Function() runAppSyncHandler,
  }) : _runAppSyncHandler = runAppSyncHandler;

  final Future<AppSyncResult> Function() _runAppSyncHandler;
  AppSyncProgress? _progress;
  int runAppSyncCallCount = 0;

  @override
  AppSyncProgress? get appSyncProgress => _progress;

  @override
  Future<AppSyncResult> runAppSync() {
    runAppSyncCallCount += 1;
    return _runAppSyncHandler();
  }

  void emitProgress(AppSyncProgress progress) {
    _progress = progress;
    notifyListeners();
  }
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
