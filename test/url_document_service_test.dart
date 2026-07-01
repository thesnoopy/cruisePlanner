import 'dart:convert';
import 'dart:io';

import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_import_resolution.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/models/documents/url_document_target.dart';
import 'package:cruiseplanner/models/documents/url_snapshot_capture_result.dart';
import 'package:cruiseplanner/models/documents/url_snapshot_view_state.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/route/route_item.dart';
import 'package:cruiseplanner/models/route/sea_day_item.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/screens/documents/url_snapshot_capture_screen.dart';
import 'package:cruiseplanner/services/documents/document_attachment_service.dart';
import 'package:cruiseplanner/services/documents/document_import_service.dart';
import 'package:cruiseplanner/services/documents/excursion_document_section_service.dart';
import 'package:cruiseplanner/services/documents/url_document_service.dart';
import 'package:cruiseplanner/services/documents/url_snapshot_webview_controller.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:cruiseplanner/widgets/documents/excursion_documents_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = null;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('UrlDocumentService', () {
    test('saves imported PDF metadata and attaches it to a cruise', () async {
      await _seedCruise(_sampleCruise());
      final importService = _FakeDocumentImportService();
      final service = UrlDocumentService(
        documentImportService: importService,
        attachmentService: DocumentAttachmentService(),
      );
      final snapshotPath = await _writeTempSnapshotPdf(<int>[1, 2, 3]);

      final result = await service.saveSnapshot(
        target: const UrlDocumentTarget(
          type: UrlDocumentTargetType.cruise,
          id: 'cruise-1',
        ),
        snapshot: UrlSnapshotCaptureResult(
          sourceUrl: 'https://source.example/ticket',
          effectiveUrl: 'https://secure.example/ticket',
          filePath: snapshotPath,
          pageTitle: 'Boarding Pass',
        ),
      );

      expect(result.outcome, UrlDocumentSaveOutcome.importedAndLinked);
      expect(importService.lastMimeType, 'application/pdf');
      expect(importService.lastOrigin, DocumentOrigin.urlImport);
      expect(importService.lastSourceUrl, 'https://source.example/ticket');
      expect(
        importService.lastSnapshotStatus,
        DocumentSnapshotStatus.available,
      );
      expect(importService.lastSourceHost, 'secure.example');
      expect(importService.lastCapturedAtUtc, isNotNull);
      expect(importService.lastTitle, 'Boarding Pass');
      expect(importService.lastOriginalFileName, endsWith('.pdf'));

      final store = CruiseStore();
      await store.load();
      final cruise = store.getCruise('cruise-1');
      expect(cruise?.documentIds, <String>['doc-url-1']);
      expect(await File(snapshotPath).exists(), isFalse);
    });

    test('uses host and timestamp when no page title is available', () async {
      await _seedCruise(_sampleCruise());
      final importService = _FakeDocumentImportService();
      final service = UrlDocumentService(
        documentImportService: importService,
        attachmentService: DocumentAttachmentService(),
      );
      final snapshotPath = await _writeTempSnapshotPdf(<int>[9, 8, 7]);

      await service.saveSnapshot(
        target: const UrlDocumentTarget(
          type: UrlDocumentTargetType.seaDay,
          id: 'sea-1',
        ),
        snapshot: UrlSnapshotCaptureResult(
          sourceUrl: 'https://source.example/day',
          effectiveUrl: 'https://portal.example/day',
          filePath: snapshotPath,
        ),
      );

      expect(importService.lastTitle, startsWith('portal.example '));

      final store = CruiseStore();
      await store.load();
      final seaDay = store.getById<RouteItem>('sea-1') as SeaDayItem?;
      expect(seaDay?.documentIds, <String>['doc-url-1']);
    });

    test('reports alreadyLinked when the document is already attached', () async {
      await _seedCruise(
        _sampleCruise(
          documentIds: const <String>['doc-url-1'],
        ),
      );
      final importService = _FakeDocumentImportService(
        resolutionKind: DocumentImportResolutionKind.existing,
        documentId: 'doc-url-1',
      );
      final service = UrlDocumentService(
        documentImportService: importService,
        attachmentService: DocumentAttachmentService(),
      );
      final snapshotPath = await _writeTempSnapshotPdf(<int>[1, 2, 3]);

      final result = await service.saveSnapshot(
        target: const UrlDocumentTarget(
          type: UrlDocumentTargetType.cruise,
          id: 'cruise-1',
        ),
        snapshot: UrlSnapshotCaptureResult(
          sourceUrl: 'https://source.example/ticket',
          effectiveUrl: 'https://secure.example/ticket',
          filePath: snapshotPath,
        ),
      );

      expect(result.outcome, UrlDocumentSaveOutcome.alreadyLinked);
      final store = CruiseStore();
      await store.load();
      expect(store.getCruise('cruise-1')?.documentIds, <String>['doc-url-1']);
    });

    test('saves a link-only URL document and attaches it to a cruise', () async {
      await _seedCruise(_sampleCruise());
      final importService = _FakeDocumentImportService();
      final service = UrlDocumentService(
        documentImportService: importService,
        attachmentService: DocumentAttachmentService(),
      );

      final result = await service.saveLinkOnly(
        target: const UrlDocumentTarget(
          type: UrlDocumentTargetType.cruise,
          id: 'cruise-1',
        ),
        sourceUrl: 'https://example.com/tickets/boarding-pass',
      );

      expect(result.outcome, UrlDocumentSaveOutcome.importedAndLinked);
      expect(importService.lastMimeType, 'text/plain');
      expect(importService.lastOrigin, DocumentOrigin.urlImport);
      expect(
        importService.lastSourceUrl,
        'https://example.com/tickets/boarding-pass',
      );
      expect(
        importService.lastSourceDescription,
        'https://example.com/tickets/boarding-pass',
      );
      expect(
        importService.lastSnapshotStatus,
        DocumentSnapshotStatus.linkOnly,
      );
      expect(importService.lastSourceHost, 'example.com');
      expect(importService.lastOriginalFileName, endsWith('.txt'));
      expect(importService.lastTitle, 'boarding-pass');

      final store = CruiseStore();
      await store.load();
      final cruise = store.getCruise('cruise-1');
      expect(cruise?.documentIds, <String>['doc-url-1']);
    });

    test('rejects invalid URLs', () async {
      final service = UrlDocumentService(
        documentImportService: _FakeDocumentImportService(),
        attachmentService: DocumentAttachmentService(),
      );

      expect(
        () => service.normalizeSourceUrl('example.com'),
        throwsArgumentError,
      );
    });
  });

  testWidgets('UrlSnapshotCaptureScreen shows unsupported message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UrlSnapshotCaptureScreen(
          target: const UrlDocumentTarget(
            type: UrlDocumentTargetType.cruise,
            id: 'cruise-1',
          ),
          webViewController: _UnsupportedUrlSnapshotWebViewController(),
          documentService: UrlDocumentService(
            documentImportService: _FakeDocumentImportService(),
            attachmentService: DocumentAttachmentService(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Save webpage as PDF'), findsOneWidget);
    expect(
      find.text('This feature is currently only available on Android and iOS.'),
      findsOneWidget,
    );
  });

  testWidgets('UrlSnapshotCaptureScreen enables save button only when capture is possible', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final controller = _FakeUrlSnapshotWebViewController(
        const UrlSnapshotViewState(
          isSupported: true,
          isLoading: false,
          hasLoadedPage: false,
          canCapture: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UrlSnapshotCaptureScreen(
            target: const UrlDocumentTarget(
              type: UrlDocumentTargetType.cruise,
              id: 'cruise-1',
            ),
            webViewController: controller,
            documentService: UrlDocumentService(
              documentImportService: _FakeDocumentImportService(),
              attachmentService: DocumentAttachmentService(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(_saveAsPdfButton(tester).onPressed, isNull);

      controller.updateState(
        const UrlSnapshotViewState(
          isSupported: true,
          isLoading: false,
          hasLoadedPage: true,
          canCapture: true,
          currentUrl: 'https://example.com',
        ),
      );
      await tester.pump();

      expect(_saveAsPdfButton(tester).onPressed, isNotNull);

      controller.updateState(
        const UrlSnapshotViewState(
          isSupported: true,
          isLoading: true,
          hasLoadedPage: true,
          canCapture: true,
          currentUrl: 'https://example.com',
        ),
      );
      await tester.pump();

      expect(_saveAsPdfButton(tester).onPressed, isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('ExcursionDocumentsSection reloads after returning from URL snapshot capture', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final navigatorKey = GlobalKey<NavigatorState>();
      final document = _sampleDocumentRecord(
        id: 'doc-new-1',
        title: 'Saved Snapshot',
        sourceUrl: 'https://example.com/ticket',
      );
      final service = _FakeExcursionDocumentSectionService(
        initialData: const ExcursionDocumentSectionData(
          linkedDocuments: <DocumentRecord>[],
          availableDocuments: <DocumentRecord>[],
        ),
        reloadedData: ExcursionDocumentSectionData(
          linkedDocuments: <DocumentRecord>[document],
          availableDocuments: const <DocumentRecord>[],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExcursionDocumentsSection(
              excursionId: 'exc-1',
              service: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Snapshot'), findsNothing);
      expect(service.loadCallCount, 1);

      await tester.tap(find.text('URL as PDF'));
      await tester.pumpAndSettle();

      navigatorKey.currentState!.pop<UrlDocumentSaveResult>(
        UrlDocumentSaveResult(
          document: document,
          outcome: UrlDocumentSaveOutcome.importedAndLinked,
        ),
      );
      await tester.pumpAndSettle();

      expect(service.loadCallCount, 2);
      expect(service.loadedExcursionIds, <String>['exc-1', 'exc-1']);
      expect(find.text('Saved Snapshot'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

Future<void> _seedCruise(Cruise cruise) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'cruises_json_v3': jsonEncode(<String, Object>{
      'schemaVersion': 3,
      'cruises': <Map<String, dynamic>>[cruise.toMap()],
    }),
  });
}

Future<String> _writeTempSnapshotPdf(List<int> bytes) async {
  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}url_snapshot_test_${DateTime.now().microsecondsSinceEpoch}.pdf',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Cruise _sampleCruise({
  List<String> documentIds = const <String>[],
}) {
  return Cruise(
    id: 'cruise-1',
    title: 'Test Cruise',
    ship: Ship(name: 'Test Ship'),
    period: Period(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 7, 14),
    ),
    documentIds: documentIds,
    route: <RouteItem>[
      SeaDayItem(
        id: 'sea-1',
        date: DateTime(2026, 7, 4),
      ),
    ],
  );
}

class _FakeDocumentImportService extends DocumentImportService {
  _FakeDocumentImportService({
    this.resolutionKind = DocumentImportResolutionKind.imported,
    this.documentId = 'doc-url-1',
  });

  final DocumentImportResolutionKind resolutionKind;
  final String documentId;

  String? lastOriginalFileName;
  String? lastMimeType;
  String? lastTitle;
  DocumentOrigin? lastOrigin;
  String? lastSourceUrl;
  String? lastSourceDescription;
  DocumentSnapshotStatus? lastSnapshotStatus;
  DateTime? lastCapturedAtUtc;
  String? lastSourceHost;

  @override
  Future<DocumentImportResolution> createStoredDocumentIfNeeded({
    required Uint8List bytes,
    required String originalFileName,
    required String mimeType,
    String? title,
    DocumentKind? kind,
    DocumentOrigin origin = DocumentOrigin.localFile,
    String? sourceUrl,
    DocumentSnapshotStatus? snapshotStatus,
    DateTime? capturedAtUtc,
    String? sourceDescription,
    String? sourceHost,
  }) async {
    lastOriginalFileName = originalFileName;
    lastMimeType = mimeType;
    lastTitle = title;
    lastOrigin = origin;
    lastSourceUrl = sourceUrl;
    lastSourceDescription = sourceDescription;
    lastSnapshotStatus = snapshotStatus;
    lastCapturedAtUtc = capturedAtUtc;
    lastSourceHost = sourceHost;

    final timestamp = DateTime.utc(2026, 7, 1, 12);
    final document = DocumentRecord(
      id: documentId,
      kind: DocumentKind.pdf,
      title: title ?? 'Untitled',
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileExtension: 'pdf',
      localRelativePath: 'documents/$documentId/original.pdf',
      byteSize: bytes.length,
      contentHash: 'hash-$documentId',
      createdAt: timestamp,
      updatedAt: timestamp,
      deleted: false,
      origin: origin,
      sourceUrl: sourceUrl,
      snapshotStatus: snapshotStatus,
      capturedAtUtc: capturedAtUtc,
      sourceHost: sourceHost,
    );

    return DocumentImportResolution(
      document: document,
      kind: resolutionKind,
    );
  }
}

class _UnsupportedUrlSnapshotWebViewController
    extends UrlSnapshotWebViewController {
  @override
  bool get isSupported => false;

  @override
  UrlSnapshotViewState get state =>
      const UrlSnapshotViewState.initial(isSupported: false);
}

class _FakeUrlSnapshotWebViewController extends UrlSnapshotWebViewController {
  _FakeUrlSnapshotWebViewController(this._testState);

  UrlSnapshotViewState _testState;

  @override
  bool get isSupported => _testState.isSupported;

  @override
  UrlSnapshotViewState get state => _testState;

  void updateState(UrlSnapshotViewState nextState) {
    _testState = nextState;
    notifyListeners();
  }

  @override
  Future<void> attachToPlatformView(int viewId) async {}

  @override
  Future<void> loadUrl(String url) async {}

  @override
  Future<void> reload() async {}
}

class _FakeExcursionDocumentSectionService extends ExcursionDocumentSectionService {
  _FakeExcursionDocumentSectionService({
    required this.initialData,
    required this.reloadedData,
  });

  final ExcursionDocumentSectionData initialData;
  final ExcursionDocumentSectionData reloadedData;
  final List<String> loadedExcursionIds = <String>[];
  int loadCallCount = 0;

  @override
  Future<ExcursionDocumentSectionData> loadForExcursion(
    String excursionId,
  ) async {
    loadedExcursionIds.add(excursionId);
    loadCallCount++;
    return loadCallCount == 1 ? initialData : reloadedData;
  }
}

FilledButton _saveAsPdfButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Save as PDF'),
  );
}

DocumentRecord _sampleDocumentRecord({
  required String id,
  required String title,
  String? sourceUrl,
}) {
  final timestamp = DateTime.utc(2026, 7, 1, 12);
  return DocumentRecord(
    id: id,
    kind: DocumentKind.pdf,
    title: title,
    originalFileName: '$id.pdf',
    mimeType: 'application/pdf',
    fileExtension: 'pdf',
    localRelativePath: 'documents/$id/original.pdf',
    byteSize: 3,
    contentHash: 'hash-$id',
    createdAt: timestamp,
    updatedAt: timestamp,
    deleted: false,
    origin: DocumentOrigin.urlImport,
    sourceUrl: sourceUrl,
    snapshotStatus: DocumentSnapshotStatus.available,
    capturedAtUtc: timestamp,
    sourceHost: sourceUrl == null ? null : Uri.parse(sourceUrl).host,
  );
}
