import 'dart:async';
import 'dart:convert';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_full_sync_execution_result.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/models/documents/document_sync_execution_result.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/route/port_call_item.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/models/travel/hotel_item.dart';
import 'package:cruiseplanner/services/documents/cruise_document_section_service.dart';
import 'package:cruiseplanner/services/documents/document_attachment_service.dart';
import 'package:cruiseplanner/settings/webdav_settings.dart';
import 'package:cruiseplanner/settings/webdav_settings_store.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:cruiseplanner/store/document_store.dart';
import 'package:cruiseplanner/sync/app_sync_progress.dart';
import 'package:cruiseplanner/sync/app_sync_service.dart';
import 'package:cruiseplanner/sync/cruise_sync_service.dart';
import 'package:cruiseplanner/sync/webdav_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
      localCruises: <Cruise>[
        _sampleCruise().copyWith(documentIds: const <String>['doc-a']),
      ],
      onProgress: attachedProgress.add,
    );

    allowCruiseSyncToFinish.complete();

    final firstResult = await firstSync;
    final secondResult = await secondSync;

    expect(firstResult.hasFailures, isFalse);
    expect(secondResult.hasFailures, isFalse);
    expect(cruiseSyncRuns, 1);
    expect(firstResult.localCruisesAtSyncStart!.single.documentIds, isEmpty);
    expect(secondResult.localCruisesAtSyncStart, firstResult.localCruisesAtSyncStart);
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

  test('keeps locally known excursions when the remote snapshot is stale or empty', () {
    final service = CruiseSyncService(const WebDavSync(_validSettings));
    final baseCruise = _sampleCruise().copyWith(
      id: 'cruise-1',
      excursions: <Excursion>[
        _excursion('A', 'Port A'),
      ],
    );
    final localCruise = baseCruise.copyWith(
      excursions: <Excursion>[
        _excursion('A', 'Port A'),
        _excursion('B', 'Port A'),
        _excursion('C', 'Port A'),
      ],
    );

    final merged = service.mergeThreeWayForTesting(
      <Cruise>[baseCruise],
      <Cruise>[localCruise],
      const <Cruise>[],
    );

    expect(
      merged.single.excursions.map((excursion) => excursion.title).toList(),
      <String>['A', 'B', 'C'],
    );
  });

  test('keeps excursions from different port calls when remote is missing them', () {
    final service = CruiseSyncService(const WebDavSync(_validSettings));
    final baseCruise = _sampleCruise().copyWith(
      id: 'cruise-ports',
      route: <PortCallItem>[
        PortCallItem(id: 'port-a', date: DateTime.utc(2026, 1, 2), portName: 'Port A'),
        PortCallItem(id: 'port-b', date: DateTime.utc(2026, 1, 3), portName: 'Port B'),
      ],
      excursions: <Excursion>[
        _excursion('A', 'Port A'),
      ],
    );
    final localCruise = baseCruise.copyWith(
      excursions: <Excursion>[
        _excursion('A', 'Port A'),
        _excursion('B', 'Port A'),
        _excursion('C', 'Port B'),
      ],
    );

    final merged = service.mergeThreeWayForTesting(
      <Cruise>[baseCruise],
      <Cruise>[localCruise],
      const <Cruise>[],
    );

    expect(
      merged.single.excursions.map((excursion) => excursion.title).toList(),
      <String>['A', 'B', 'C'],
    );
    expect(
      merged.single.excursions.map((excursion) => excursion.port).toList(),
      <String>['Port A', 'Port A', 'Port B'],
    );
  });

  test('keeps real local deletes when remote is stale or missing', () {
    final service = CruiseSyncService(const WebDavSync(_validSettings));
    final baseCruise = _sampleCruise().copyWith(
      id: 'cruise-delete',
      excursions: <Excursion>[
        _excursion('A', 'Port A'),
        _excursion('B', 'Port A'),
      ],
    );
    final localCruise = baseCruise.copyWith(
      excursions: <Excursion>[
        _excursion('A', 'Port A').copyWith(deletedAtUtc: DateTime.utc(2026, 1, 2, 3)),
        _excursion('B', 'Port A'),
      ],
    );

    final merged = service.mergeThreeWayForTesting(
      <Cruise>[baseCruise],
      <Cruise>[localCruise],
      const <Cruise>[],
    );

    expect(
      merged.single.excursions.map((excursion) => excursion.title).toList(),
      <String>['B'],
    );
    expect(
      merged.single.excursions.single.deletedAtUtc,
      isNull,
    );
  });

  test('round-trips a cruise with multiple excursions without dropping entries', () {
    final cruise = _sampleCruise().copyWith(
      id: 'cruise-roundtrip',
      excursions: <Excursion>[
        _excursion('A', 'Port A'),
        _excursion('B', 'Port B'),
        _excursion('C', 'Port C'),
      ],
    );

    final reloaded = Cruise.fromMap(cruise.toMap());
    expect(
      reloaded.excursions.map((excursion) => excursion.title).toList(),
      <String>['A', 'B', 'C'],
    );
    expect(
      reloaded.excursions.map((excursion) => excursion.port).toList(),
      <String>['Port A', 'Port B', 'Port C'],
    );
  });

  group('Active cruise state after sync', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    for (final autoSync in <bool>[false, true]) {
      testWidgets('publishes A and new B with complete lookups '
          '(auto sync: $autoSync)', (tester) async {
        final cruiseA = _sampleCruise();
        final cruiseB = cruiseA.copyWith(
          id: 'cruise-2',
          title: 'Remote Cruise B',
          documentIds: const <String>['doc-b'],
          excursions: <Excursion>[_excursion('Remote excursion', 'Port B')],
          route: <PortCallItem>[
            PortCallItem(
              id: 'port-b',
              date: DateTime.utc(2026, 1, 2),
              portName: 'Port B',
            ),
          ],
          travel: <HotelItem>[
            HotelItem(
              id: 'hotel-b',
              start: DateTime.utc(2026, 1, 1),
              name: 'Hotel B',
            ),
          ],
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cruises_json_v3', jsonEncode(<String, Object>{
          'schemaVersion': 3,
          'cruises': <Object>[cruiseA.toMap()],
        }));
        final webDav = _MemoryCruiseWebDav(<Cruise>[cruiseA, cruiseB]);
        final documentSyncStarted = Completer<void>();
        final finishDocuments = Completer<void>();
        var syncRuns = 0;
        final service = AppSyncService(
          settingsStore: const _FakeWebDavSettingsStore(_validSettings),
          cruiseSyncRunner: (_, cruises) {
            syncRuns += 1;
            return CruiseSyncService(webDav).sync(cruises);
          },
          documentSyncRunner: (_, _) async {
            documentSyncStarted.complete();
            await finishDocuments.future;
            return const _SuccessfulDocumentSyncResult();
          },
        );
        final store = CruiseStore(appSyncService: service);
        final reader = CruiseStore();
        addTearDown(store.dispose);
        addTearDown(reader.dispose);
        await store.load();
        expect(store.activeCruises.map((cruise) => cruise.id), <String>[cruiseA.id]);
        final publishedWithB = <List<String>>[];
        var completedNotifications = 0;
        store.addListener(() {
          if (store.getCruise(cruiseB.id) != null) {
            publishedWithB.add(store.activeCruises.map((cruise) => cruise.id).toList());
            expect(store.getById<Cruise>(cruiseB.id), cruiseB);
            expect(store.getById<PortCallItem>('port-b'), cruiseB.route.single);
            expect(store.getById<HotelItem>('hotel-b'), cruiseB.travel.single);
            expect(store.getById<Excursion>(cruiseB.excursions.single.id),
                cruiseB.excursions.single);
            expect(store.getCruise(cruiseB.id)!.documentIds, <String>['doc-b']);
          }
          if (store.appSyncProgress?.stage == AppSyncProgressStage.completed) {
            completedNotifications += 1;
            expect(store.getCruise(cruiseB.id), cruiseB);
            final persisted = jsonDecode(prefs.getString('cruises_json_v3')!) as Map;
            expect((persisted['cruises'] as List).map((value) => value['id']),
                <String>[cruiseA.id, cruiseB.id]);
          }
        });

        final sync = autoSync
            ? store.triggerAutoSyncOnAppOpen()
            : store.runAppSync();
        var finished = false;
        final completion = sync.then((_) { finished = true; });
        await documentSyncStarted.future;
        expect(finished, isFalse);
        expect(store.getCruise(cruiseB.id), isNull);
        expect(completedNotifications, 0);
        finishDocuments.complete();
        await completion;

        expect(store.activeCruises, <Cruise>[cruiseA, cruiseB]);
        expect(store.getCruise(cruiseB.id), cruiseB);
        expect(publishedWithB, <List<String>>[<String>[cruiseA.id, cruiseB.id]]);
        expect(completedNotifications, 1);
        await reader.load();
        expect(reader.getCruise(cruiseB.id), cruiseB);
        await tester.pump(const Duration(seconds: 2));
        expect(syncRuns, 1);
      });
    }
  });

  group('Cruise document references', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    tearDown(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('keeps multiple cruise documents when attaching three new documents', () async {
      final cruiseStore = CruiseStore();
      addTearDown(cruiseStore.dispose);
      final documentStore = DocumentStore();
      await cruiseStore.replaceAll(<Cruise>[_sampleCruise()]);
      await documentStore.saveDocuments(<DocumentRecord>[
        _document('doc-a'),
        _document('doc-b'),
        _document('doc-c'),
      ]);

      final service = CruiseDocumentSectionService(
        attachmentService: DocumentAttachmentService(
          cruiseStore: cruiseStore,
          documentStore: documentStore,
        ),
        documentStore: documentStore,
      );

      expect((await service.loadForCruise('cruise-1')).linkedDocuments, isEmpty);
      final expectedIds = <String>[];
      for (final id in <String>['doc-a', 'doc-b', 'doc-c']) {
        expect(
          await service.attachExistingDocument(
            cruiseId: 'cruise-1',
            documentId: id,
          ),
          isTrue,
        );
        expectedIds.add(id);
        final data = await service.loadForCruise('cruise-1');
        expect(data.linkedDocuments.map((document) => document.id), expectedIds);
        expect(cruiseStore.getCruise('cruise-1')?.documentIds, expectedIds);
        expect(
          data.availableDocuments.map((document) => document.id),
          unorderedEquals(
            <String>['doc-a', 'doc-b', 'doc-c'].where(
              (documentId) => !expectedIds.contains(documentId),
            ),
          ),
        );
      }

      expect(
        await service.attachExistingDocument(
          cruiseId: 'cruise-1',
          documentId: 'doc-b',
        ),
        isFalse,
      );

      expect(
        cruiseStore.getCruise('cruise-1')?.documentIds,
        <String>['doc-a', 'doc-b', 'doc-c'],
      );
    });

    test('removes only the detached cruise document and keeps the rest', () async {
      final cruiseStore = CruiseStore();
      addTearDown(cruiseStore.dispose);
      final documentStore = DocumentStore();
      await cruiseStore.replaceAll(
        <Cruise>[
          _sampleCruise().copyWith(
            documentIds: const <String>['doc-a', 'doc-b', 'doc-c'],
          ),
        ],
      );
      await documentStore.saveDocuments(<DocumentRecord>[
        _document('doc-a'),
        _document('doc-b'),
        _document('doc-c'),
      ]);

      final service = DocumentAttachmentService(
        cruiseStore: cruiseStore,
        documentStore: documentStore,
      );

      await service.detachDocumentFromCruise(
        cruiseId: 'cruise-1',
        documentId: 'doc-b',
      );

      expect(
        cruiseStore.getCruise('cruise-1')?.documentIds,
        <String>['doc-a', 'doc-c'],
      );
      expect((await documentStore.getDocumentById('doc-a'))?.deleted, isFalse);
      expect((await documentStore.getDocumentById('doc-b'))?.deleted, isTrue);
      expect((await documentStore.getDocumentById('doc-c'))?.deleted, isFalse);
      expect(
        (await service.getDocumentsForCruise(cruiseId: 'cruise-1'))
            .map((document) => document.id),
        <String>['doc-a', 'doc-c'],
      );
      expect(
        await service.detachDocumentFromCruise(
          cruiseId: 'cruise-1',
          documentId: 'doc-b',
        ),
        isFalse,
      );
    });

    test('preserves cruise documentIds across JSON and store reload', () async {
      final cruise = _sampleCruise().copyWith(
        documentIds: const <String>['doc-a', 'doc-b', 'doc-c'],
      );

      final reloaded = Cruise.fromMap(
        jsonDecode(jsonEncode(cruise.toMap())) as Map<String, dynamic>,
      );

      expect(reloaded.documentIds, <String>['doc-a', 'doc-b', 'doc-c']);
      expect(reloaded.copyWith(title: 'Edited cruise').documentIds,
          <String>['doc-a', 'doc-b', 'doc-c']);
      final writer = CruiseStore();
      final reader = CruiseStore();
      addTearDown(writer.dispose);
      addTearDown(reader.dispose);
      await writer.replaceAll(<Cruise>[reloaded]);
      final documents = <DocumentRecord>[
        _document('doc-a'),
        _document('doc-b'),
        _document('doc-c'),
      ];
      await DocumentStore().saveDocuments(documents);
      await reader.load();
      expect(reader.getCruise('cruise-1')?.documentIds,
          <String>['doc-a', 'doc-b', 'doc-c']);
      final service = CruiseDocumentSectionService(
        attachmentService: DocumentAttachmentService(cruiseStore: reader),
      );
      final data = await service.loadForCruise('cruise-1');
      expect(data.linkedDocuments.map((document) => document.toJson()),
          documents.map((document) => document.toJson()));
      expect(data.availableDocuments, isEmpty);
    });

    test('keeps legacy data without documentIds compatible', () {
      final legacy = _sampleCruise().toMap()..remove('documentIds');
      expect(Cruise.fromMap(legacy).documentIds, isEmpty);
      legacy['documentIds'] = <String>[' doc-a ', '', 'doc-a', 'doc-b'];
      final reloaded = Cruise.fromMap(legacy);
      expect(reloaded.documentIds, <String>['doc-a', 'doc-b']);
      expect(reloaded.toMap()['documentIds'], <String>['doc-a', 'doc-b']);
    });

    test('unlink keeps document metadata active when another entity uses it', () async {
      final store = CruiseStore();
      addTearDown(store.dispose);
      await store.replaceAll(<Cruise>[
        _sampleCruise().copyWith(
          documentIds: const <String>['doc-a', 'doc-b', 'doc-c'],
          excursions: <Excursion>[
            _excursion('A', 'Port A').copyWith(
              documentIds: const <String>['doc-b'],
            ),
          ],
        ),
      ]);
      final documents = DocumentStore();
      await documents.saveDocuments(<DocumentRecord>[
        _document('doc-a'), _document('doc-b'), _document('doc-c'),
      ]);
      final service = DocumentAttachmentService(
        cruiseStore: store,
        documentStore: documents,
      );
      await service.detachDocumentFromCruise(
        cruiseId: 'cruise-1', documentId: 'doc-b',
      );
      expect(store.getCruise('cruise-1')?.documentIds,
          <String>['doc-a', 'doc-c']);
      expect(store.getCruise('cruise-1')?.excursions.single.documentIds,
          <String>['doc-b']);
      expect((await documents.getDocumentById('doc-b'))?.deleted, isFalse);
    });

    test('preserves multiple cruise documents after merge when remote snapshot is stale', () {
      final service = CruiseSyncService(const WebDavSync(_validSettings));
      final baseCruise = _sampleCruise().copyWith(
        id: 'cruise-merge',
        documentIds: const <String>['doc-a'],
      );
      final localCruise = baseCruise.copyWith(
        documentIds: const <String>['doc-a', 'doc-b', 'doc-c'],
      );

      final merged = service.mergeThreeWayForTesting(
        <Cruise>[baseCruise],
        <Cruise>[localCruise],
        const <Cruise>[],
      );

      expect(
        merged.single.documentIds,
        <String>['doc-a', 'doc-b', 'doc-c'],
      );
    });

    for (final timestamp in <DateTime?>[null, DateTime.utc(2026, 1, 2)]) {
      test('merges local document additions with a remote title ($timestamp)', () {
        final service = CruiseSyncService(const WebDavSync(_validSettings));
        final base = _sampleCruise().copyWith(
          documentIds: const <String>['doc-a'],
          updatedAtUtc: timestamp,
        );
        final local = base.copyWith(
          documentIds: const <String>['doc-a', 'doc-b', 'doc-c'],
        );
        final remote = base.copyWith(title: 'Remote title');

        final merged = service.mergeThreeWayForTesting(
          <Cruise>[base], <Cruise>[local], <Cruise>[remote],
        ).single;

        expect(merged.documentIds, <String>['doc-a', 'doc-b', 'doc-c']);
        expect(merged.title, 'Remote title');
      });

      test('does not resurrect an unlinked document in a conflict ($timestamp)', () {
        final service = CruiseSyncService(const WebDavSync(_validSettings));
        final base = _sampleCruise().copyWith(
          documentIds: const <String>['doc-a', 'doc-b', 'doc-c'],
          updatedAtUtc: timestamp,
        );
        final local = base.copyWith(documentIds: const <String>['doc-a', 'doc-c']);
        final remote = base.copyWith(title: 'Remote title');

        final merged = service.mergeThreeWayForTesting(
          <Cruise>[base], <Cruise>[local], <Cruise>[remote],
        ).single;

        expect(merged.documentIds, <String>['doc-a', 'doc-c']);
        expect(merged.title, 'Remote title');
      });
    }

    for (final changeIsLocal in <bool>[true, false]) {
      test('keeps all documents for a one-sided change (local: $changeIsLocal)', () {
        final service = CruiseSyncService(const WebDavSync(_validSettings));
        final base = _sampleCruise().copyWith(documentIds: const <String>['doc-a']);
        final changed = base.copyWith(
          documentIds: const <String>['doc-a', 'doc-b', 'doc-c'],
        );
        final merged = service.mergeThreeWayForTesting(
          <Cruise>[base],
          <Cruise>[changeIsLocal ? changed : base],
          <Cruise>[changeIsLocal ? base : changed],
        );
        expect(merged.single.documentIds, <String>['doc-a', 'doc-b', 'doc-c']);
      });

      for (final deleteIsNewer in <bool>[true, false]) {
        test('respects newer edit versus delete (local edit: $changeIsLocal, '
            'newer delete: $deleteIsNewer)', () {
          final service = CruiseSyncService(const WebDavSync(_validSettings));
          final base = _sampleCruise().copyWith(
            documentIds: const <String>['doc-a'],
            updatedAtUtc: DateTime.utc(2026, 1, 1),
          );
          final edited = base.copyWith(
            documentIds: const <String>['doc-a', 'doc-b', 'doc-c'],
            updatedAtUtc: DateTime.utc(2026, 1, deleteIsNewer ? 2 : 3),
          );
          final deletedAt = DateTime.utc(2026, 1, deleteIsNewer ? 3 : 2);
          final deleted = base.copyWith(
            documentIds: const <String>[],
            updatedAtUtc: deletedAt,
            deletedAtUtc: deletedAt,
          );
          final merged = service.mergeThreeWayForTesting(
            <Cruise>[base],
            <Cruise>[changeIsLocal ? edited : deleted],
            <Cruise>[changeIsLocal ? deleted : edited],
          ).single;
          expect(merged.documentIds,
              deleteIsNewer ? <String>[] : <String>['doc-a', 'doc-b', 'doc-c']);
          expect(merged.deletedAtUtc, deleteIsNewer ? deletedAt : isNull);
        });
      }
    }

    test('sync persists all links in the remote payload, baseline and local store', () async {
      final base = _sampleCruise().copyWith(documentIds: const <String>['doc-a']);
      final local = base.copyWith(
        documentIds: const <String>['doc-a', 'doc-b', 'doc-c'],
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cruises_sync_baseline_v3', jsonEncode(<Object>[base.toMap()]));
      final webDav = _MemoryCruiseWebDav(<Cruise>[
        base.copyWith(title: 'Remote title'),
      ]);
      final service = AppSyncService(
        settingsStore: const _FakeWebDavSettingsStore(_validSettings),
        cruiseSyncRunner: (_, cruises) => CruiseSyncService(webDav).sync(cruises),
        documentSyncRunner: (_, _) async => const _SuccessfulDocumentSyncResult(),
      );
      final store = CruiseStore(appSyncService: service);
      final writer = CruiseStore();
      final reloaded = CruiseStore();
      addTearDown(store.dispose);
      addTearDown(writer.dispose);
      addTearDown(reloaded.dispose);
      await store.replaceAll(<Cruise>[base]);
      await store.load();
      // The syncing store still holds the old snapshot from before the edit.
      await writer.replaceAll(<Cruise>[local]);
      await DocumentStore().saveDocuments(<DocumentRecord>[
        _document('doc-a'), _document('doc-b'), _document('doc-c'),
      ]);

      final result = await store.runAppSync();
      expect(result.hasFailures, isFalse);
      expect(result.mergedCruises!.single.documentIds,
          <String>['doc-a', 'doc-b', 'doc-c']);
      expect(webDav.remote.single.documentIds, <String>['doc-a', 'doc-b', 'doc-c']);
      final baseline = jsonDecode(prefs.getString('cruises_sync_baseline_v3')!) as List;
      expect(baseline.single['documentIds'], <String>['doc-a', 'doc-b', 'doc-c']);
      await reloaded.load();
      expect(reloaded.getCruise('cruise-1')?.documentIds,
          <String>['doc-a', 'doc-b', 'doc-c']);
      expect(reloaded.getCruise('cruise-1')?.title, 'Remote title');
      final section = CruiseDocumentSectionService(
        attachmentService: DocumentAttachmentService(cruiseStore: reloaded),
      );
      expect((await section.loadForCruise('cruise-1')).linkedDocuments
          .map((document) => document.id), <String>['doc-a', 'doc-b', 'doc-c']);
    });

    test('joined stores reconcile against the original shared sync input', () async {
      final documentSyncStarted = Completer<void>();
      final allowDocumentSyncToFinish = Completer<void>();
      var syncRuns = 0;
      final service = AppSyncService(
        settingsStore: const _FakeWebDavSettingsStore(_validSettings),
        cruiseSyncRunner: (_, cruises) async {
          syncRuns += 1;
          return cruises;
        },
        documentSyncRunner: (_, _) async {
          documentSyncStarted.complete();
          await allowDocumentSyncToFinish.future;
          return const _SuccessfulDocumentSyncResult();
        },
      );
      final firstStore = CruiseStore(appSyncService: service);
      final secondStore = CruiseStore(appSyncService: service);
      addTearDown(firstStore.dispose);
      addTearDown(secondStore.dispose);
      await firstStore.replaceAll(<Cruise>[_sampleCruise()]);
      await DocumentStore().saveDocument(_document('doc-a'));
      final firstSync = firstStore.runAppSync();
      await documentSyncStarted.future;
      await DocumentAttachmentService(cruiseStore: secondStore).attachDocumentToCruise(
        cruiseId: 'cruise-1', documentId: 'doc-a',
      );

      final joined = Completer<void>();
      secondStore.addListener(() {
        if (secondStore.appSyncProgress != null && !joined.isCompleted) {
          joined.complete();
        }
      });
      final secondSync = secondStore.runAppSync();
      await joined.future;
      allowDocumentSyncToFinish.complete();
      await Future.wait(<Future<AppSyncResult>>[firstSync, secondSync]);

      expect(syncRuns, 1);
      expect(firstStore.getCruise('cruise-1')?.documentIds, <String>['doc-a']);
      expect(secondStore.getCruise('cruise-1')?.documentIds, <String>['doc-a']);
      await secondStore.load();
      expect(secondStore.getCruise('cruise-1')?.documentIds, <String>['doc-a']);
    });

    testWidgets('uploads pending local links in a follow-up sync', (tester) async {
      final documentSyncStarted = Completer<void>();
      final allowDocumentSyncToFinish = Completer<void>();
      final uploadedIds = <List<String>>[];
      final service = AppSyncService(
        settingsStore: const _FakeWebDavSettingsStore(_validSettings),
        cruiseSyncRunner: (_, cruises) async {
          uploadedIds.add(cruises.single.documentIds);
          return cruises;
        },
        documentSyncRunner: (_, _) async {
          if (uploadedIds.length == 1) {
            documentSyncStarted.complete();
            await allowDocumentSyncToFinish.future;
          }
          return const _SuccessfulDocumentSyncResult();
        },
      );
      final store = CruiseStore(appSyncService: service);
      addTearDown(store.dispose);
      await store.replaceAll(<Cruise>[_sampleCruise()]);
      await DocumentStore().saveDocument(_document('doc-a'));
      final sync = store.runAppSync();
      await documentSyncStarted.future;
      await DocumentAttachmentService(cruiseStore: store).attachDocumentToCruise(
        cruiseId: 'cruise-1', documentId: 'doc-a',
      );
      // The mutation's timer fires while the first sync is still running.
      await tester.pump(const Duration(seconds: 1));
      expect(uploadedIds, <List<String>>[<String>[]]);
      allowDocumentSyncToFinish.complete();
      await sync;
      await tester.pump(const Duration(seconds: 1));
      expect(uploadedIds, <List<String>>[<String>[], <String>['doc-a']]);
      expect(store.getCruise('cruise-1')?.documentIds, <String>['doc-a']);
      // No further sync is scheduled once all pending edits were uploaded.
      await tester.pump(const Duration(seconds: 1));
      expect(uploadedIds.length, 2);
    });

    test('keeps new links when the document phase fails after cruise sync', () async {
      final documentSyncStarted = Completer<void>();
      final allowDocumentSyncToFinish = Completer<void>();
      final service = AppSyncService(
        settingsStore: const _FakeWebDavSettingsStore(_validSettings),
        cruiseSyncRunner: (_, cruises) async => cruises,
        documentSyncRunner: (_, _) async {
          documentSyncStarted.complete();
          await allowDocumentSyncToFinish.future;
          return _documentResultWithPhaseFailures(
            phase3Failures: <DocumentSyncExecutionFailure>[
              const DocumentSyncExecutionFailure(
                documentId: 'doc-a',
                action: DocumentSyncExecutionAction.upload,
                errorMessage: 'Upload failed',
              ),
            ],
          );
        },
      );
      final store = CruiseStore(appSyncService: service);
      addTearDown(store.dispose);
      await store.replaceAll(<Cruise>[_sampleCruise()]);
      await DocumentStore().saveDocument(_document('doc-a'));
      final sync = store.runAppSync();
      await documentSyncStarted.future;
      await DocumentAttachmentService(cruiseStore: store).attachDocumentToCruise(
        cruiseId: 'cruise-1', documentId: 'doc-a',
      );
      allowDocumentSyncToFinish.complete();
      final result = await sync;
      expect(result.hasFailures, isTrue);
      expect(result.localCruisesAtSyncStart!.single.documentIds, isEmpty);
      expect(store.getCruise('cruise-1')?.documentIds, <String>['doc-a']);
      await store.load();
      expect(store.getCruise('cruise-1')?.documentIds, <String>['doc-a']);
    });

    for (final useOtherStore in <bool>[false, true]) {
      for (final unlink in <bool>[false, true]) {
        test('keeps edits during document sync (other store: $useOtherStore, '
            'unlink: $unlink)', () async {
          final documentSyncStarted = Completer<void>();
          final allowDocumentSyncToFinish = Completer<void>();
          final service = AppSyncService(
            settingsStore: const _FakeWebDavSettingsStore(_validSettings),
            cruiseSyncRunner: (_, cruises) async => <Cruise>[
              cruises.single.copyWith(excursions: <Excursion>[
                _excursion('Remote excursion', 'Port A'),
              ]),
            ],
            documentSyncRunner: (_, _) async {
              documentSyncStarted.complete();
              await allowDocumentSyncToFinish.future;
              return const _SuccessfulDocumentSyncResult();
            },
          );
          final syncingStore = CruiseStore(appSyncService: service);
          final editingStore = useOtherStore ? CruiseStore() : syncingStore;
          addTearDown(syncingStore.dispose);
          if (useOtherStore) {
            addTearDown(editingStore.dispose);
          }
          await syncingStore.replaceAll(<Cruise>[
            _sampleCruise().copyWith(
              documentIds: unlink
                  ? const <String>['doc-a', 'doc-b', 'doc-c']
                  : const <String>[],
            ),
          ]);
          final documents = DocumentStore();
          await documents.saveDocuments(<DocumentRecord>[
            _document('doc-a'), _document('doc-b'), _document('doc-c'),
          ]);
          final attachments = DocumentAttachmentService(
            cruiseStore: editingStore, documentStore: documents,
          );

          final sync = syncingStore.runAppSync();
          await documentSyncStarted.future;
          if (unlink) {
            await attachments.detachDocumentFromCruise(
              cruiseId: 'cruise-1', documentId: 'doc-b',
            );
          } else {
            await attachments.attachDocumentToCruise(
              cruiseId: 'cruise-1', documentId: 'doc-a',
            );
          }
          allowDocumentSyncToFinish.complete();
          expect((await sync).hasFailures, isFalse);
          expect(syncingStore.getCruise('cruise-1')?.documentIds,
              unlink ? <String>['doc-a', 'doc-c'] : <String>['doc-a']);
          expect(syncingStore.getCruise('cruise-1')?.excursions.single.title,
              'Remote excursion');

          if (!unlink) {
            for (final id in <String>['doc-b', 'doc-c']) {
              await attachments.attachDocumentToCruise(
                cruiseId: 'cruise-1', documentId: id,
              );
            }
          }
          await syncingStore.load();
          expect(syncingStore.getCruise('cruise-1')?.documentIds,
              unlink ? <String>['doc-a', 'doc-c'] : <String>['doc-a', 'doc-b', 'doc-c']);
          expect((await documents.getDocumentById('doc-a'))?.deleted, isFalse);
          expect((await documents.getDocumentById('doc-b'))?.deleted, unlink);
        });
      }
    }
  });
}

class _MemoryCruiseWebDav extends WebDavSync {
  _MemoryCruiseWebDav(this.remote) : super(_validSettings);

  List<Cruise> remote;

  @override
  Future<List<Cruise>> downloadCruises() async => remote;

  @override
  Future<void> uploadCruises(List<Cruise> cruises) async {
    final payload = jsonDecode(
      jsonEncode(cruises.map((cruise) => cruise.toMap()).toList()),
    ) as List;
    remote = payload
        .map((value) => Cruise.fromMap(Map<String, dynamic>.from(value as Map)))
        .toList();
  }
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

DocumentRecord _document(String id) {
  final timestamp = DateTime.utc(2026, 1, 1, 10, 0, 0);
  return DocumentRecord(
    id: id,
    kind: DocumentKind.pdf,
    title: 'Document $id',
    originalFileName: '$id.pdf',
    mimeType: 'application/pdf',
    fileExtension: 'pdf',
    localRelativePath: 'documents/$id.pdf',
    byteSize: 1024,
    contentHash: id,
    createdAt: timestamp,
    updatedAt: timestamp,
    deleted: false,
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

Excursion _excursion(String title, String port) {
  return Excursion(
    id: 'excursion-${title.toLowerCase()}-${port.toLowerCase()}',
    title: title,
    date: DateTime.utc(2026, 1, 2),
    port: port,
  );
}

const WebDavSettings _validSettings = WebDavSettings(
  baseUrl: 'https://example.com/dav',
  username: 'user',
  password: 'secret',
  remotePath: '/sync/cruises.json',
);
