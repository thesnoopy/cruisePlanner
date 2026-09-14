import 'dart:async';
import 'dart:convert';

import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_full_sync_execution_result.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/screens/cruise_hub_screen.dart';
import 'package:cruiseplanner/screens/details/cruise_details_screen.dart';
import 'package:cruiseplanner/screens/home_screen.dart';
import 'package:cruiseplanner/settings/webdav_settings.dart';
import 'package:cruiseplanner/settings/webdav_settings_store.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:cruiseplanner/sync/app_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppSyncService.resetDebugState();
  });
  tearDown(AppSyncService.resetDebugState);

  for (final manualSync in <bool>[true, false]) {
    testWidgets('Home displays synced B and opens its details '
        '(manual sync: $manualSync)', (tester) async {
      final cruiseA = _cruise('a', 'Cruise A');
      final cruiseB = _cruise('b', 'Cruise B');
      await _seedCruises(<Cruise>[cruiseA]);
      final settings = _SwitchableSettingsStore();
      final documentSyncStarted = Completer<void>();
      final finishDocuments = Completer<void>();
      addTearDown(() {
        if (!finishDocuments.isCompleted) {
          finishDocuments.complete();
        }
      });
      var syncRuns = 0;
      List<Cruise>? cruisesAtSyncStart;
      final store = CruiseStore(
        appSyncService: AppSyncService(
          settingsStore: settings,
          cruiseSyncRunner: (_, cruises) async {
            syncRuns += 1;
            cruisesAtSyncStart = cruises;
            return <Cruise>[cruiseA.copyWith(title: 'Updated Cruise A'), cruiseB];
          },
          documentSyncRunner: (_, _) async {
            documentSyncStarted.complete();
            await finishDocuments.future;
            return const _SuccessfulDocumentSyncResult();
          },
        ),
      );
      addTearDown(store.dispose);
      await tester.pumpWidget(_app(HomeScreen(store: store)));
      await tester.pumpAndSettle();
      expect(find.text('Cruise A'), findsOneWidget);
      expect(find.text('Cruise B'), findsNothing);
      settings.enabled = true;

      if (manualSync) {
        await tester.tap(find.byTooltip('Cloud sync'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      } else {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
      }
      await documentSyncStarted.future;
      expect(cruisesAtSyncStart, <Cruise>[cruiseA]);
      expect(find.text('Cruise B', skipOffstage: false), findsNothing);
      if (manualSync) {
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Close'), findsNothing);
      }
      finishDocuments.complete();
      await tester.pumpAndSettle();

      // Check before returning from the sync route: a route rebuild must not
      // hide a stale snapshot captured outside Home's listener builder.
      expect(find.text('Cruise B', skipOffstage: false), findsOneWidget);
      expect(find.text('Updated Cruise A', skipOffstage: false), findsOneWidget);
      expect(find.text('Cruise A', skipOffstage: false), findsNothing);
      expect(store.getCruise('b'), cruiseB);
      if (manualSync) {
        expect(find.byType(LinearProgressIndicator), findsNothing);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Cruise B'));
      await tester.pumpAndSettle();
      expect(find.byType(CruiseHubScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final loc = AppLocalizations.of(
        tester.element(find.byType(CruiseHubScreen)),
      )!;
      await tester.tap(find.text(loc.cruiseDetails));
      await tester.pumpAndSettle();
      expect(find.byType(CruiseDetailsScreen), findsOneWidget);
      expect(find.text('Cruise B'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(syncRuns, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Home leaves its empty state after launch sync', (tester) async {
    final cruiseB = _cruise('b', 'Cruise B');
    final finishDownload = Completer<List<Cruise>>();
    addTearDown(() {
      if (!finishDownload.isCompleted) {
        finishDownload.complete(<Cruise>[]);
      }
    });
    final settings = _SwitchableSettingsStore()..enabled = true;
    final store = CruiseStore(
      appSyncService: AppSyncService(
        settingsStore: settings,
        cruiseSyncRunner: (_, _) => finishDownload.future,
        documentSyncRunner: (_, _) async => const _SuccessfulDocumentSyncResult(),
      ),
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(_app(HomeScreen(store: store)));
    await tester.pumpAndSettle();
    expect(find.text('No cruises yet. Tap + to add one.'), findsOneWidget);
    finishDownload.complete(<Cruise>[cruiseB]);
    await tester.pumpAndSettle();
    expect(find.text('Cruise B'), findsOneWidget);
    expect(find.text('No cruises yet. Tap + to add one.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final details in <bool>[false, true]) {
    for (final scenario in <String>['missing', 'deleted', 'invalid JSON']) {
      testWidgets('Cruise lookup ends for $scenario (details: $details)',
          (tester) async {
        if (scenario == 'deleted') {
          await _seedCruises(<Cruise>[
            _cruise('missing-id', 'Deleted Cruise').copyWith(
              deletedAtUtc: DateTime.utc(2026, 9, 1),
            ),
          ]);
        } else if (scenario == 'invalid JSON') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cruises_json_v3', '{invalid JSON');
        }
        final screen = details
            ? const CruiseDetailsScreen(cruiseId: 'missing-id')
            : const CruiseHubScreen(cruiseId: 'missing-id');
        await tester.pumpWidget(_app(screen));
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(scenario == 'invalid JSON'
            ? 'Could not load cruise. Please try again later.'
            : 'Cruise not found'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

Future<void> _seedCruises(List<Cruise> cruises) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('cruises_json_v3', jsonEncode(<String, Object>{
    'schemaVersion': 4,
    'cruises': cruises.map((cruise) => cruise.toMap()).toList(),
  }));
}

Cruise _cruise(String id, String title) => Cruise(
      id: id,
      title: title,
      ship: Ship(name: 'Test Ship'),
      period: Period(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 8)),
      excursions: const [],
      travel: const [],
      route: const [],
    );

class _SwitchableSettingsStore extends WebDavSettingsStore {
  bool enabled = false;

  @override
  Future<WebDavSettings?> load() async => enabled
      ? const WebDavSettings(
          baseUrl: 'https://example.com/dav',
          username: 'user',
          password: 'secret',
          remotePath: '/sync/cruises.json',
        )
      : null;
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
