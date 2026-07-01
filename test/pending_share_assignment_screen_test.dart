import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/models/share/share_intake_payload.dart';
import 'package:cruiseplanner/screens/share/pending_share_assignment_screen.dart';
import 'package:cruiseplanner/services/documents/url_document_service.dart';
import 'package:cruiseplanner/services/share/pending_share_assignment_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = null;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shared URL can be assigned as link only', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final service = _FakePendingShareAssignmentService();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    final resultFuture = navigatorKey.currentState!.push<String>(
      MaterialPageRoute(
        builder: (_) => PendingShareAssignmentScreen(
          batchId: 'batch-1',
          itemIndex: 0,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Harbor Excursion'));
    await tester.pumpAndSettle();

    expect(find.text('Add link only'), findsOneWidget);
    expect(find.text('Add link and save PDF'), findsOneWidget);

    await tester.tap(find.text('Add link only'));
    await tester.pumpAndSettle();

    expect(service.linkAssignmentCallCount, 1);
    expect(service.lastRemovePendingItem, isTrue);
    expect(service.completePendingUrlAssignmentCallCount, 0);
    expect(await resultFuture, 'Document imported.');
  });

  testWidgets('shared URL can open snapshot flow and then attach link', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final navigatorKey = GlobalKey<NavigatorState>();
      final service = _FakePendingShareAssignmentService();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      final resultFuture = navigatorKey.currentState!.push<String>(
        MaterialPageRoute(
          builder: (_) => PendingShareAssignmentScreen(
            batchId: 'batch-1',
            itemIndex: 0,
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Harbor Excursion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add link and save PDF'));
      await tester.pumpAndSettle();

      expect(find.text('Save webpage as PDF'), findsOneWidget);
      expect(find.text('https://example.com/tickets/boarding-pass'), findsWidgets);

      navigatorKey.currentState!.pop<UrlDocumentSaveResult>(
        UrlDocumentSaveResult(
          document: _sampleDocument(),
          outcome: UrlDocumentSaveOutcome.importedAndLinked,
        ),
      );
      await tester.pumpAndSettle();

      expect(service.linkAssignmentCallCount, 1);
      expect(service.lastRemovePendingItem, isFalse);
      expect(service.completePendingUrlAssignmentCallCount, 1);
      expect(await resultFuture, 'Link and PDF saved.');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _FakePendingShareAssignmentService extends PendingShareAssignmentService {
  int linkAssignmentCallCount = 0;
  int completePendingUrlAssignmentCallCount = 0;
  bool? lastRemovePendingItem;

  @override
  bool canAssignItem({
    required String batchId,
    required int itemIndex,
    ShareIntakeItem? item,
  }) {
    return true;
  }

  @override
  Future<PendingShareAssignmentSelectionData> loadSelectionData({
    required String batchId,
    required int itemIndex,
    required AppLocalizations loc,
  }) async {
    return PendingShareAssignmentSelectionData(
      item: const ShareIntakeItem(
        kind: ShareIntakeItemKind.url,
        value: 'https://example.com/tickets/boarding-pass',
      ),
      cruiseGroups: const <PendingShareAssignmentCruiseGroup>[
        PendingShareAssignmentCruiseGroup(
          cruiseId: 'cruise-1',
          cruiseTitle: 'Cruise One',
          cruiseTarget: PendingShareAssignmentTarget(
            type: PendingShareAssignmentTargetType.cruise,
            id: 'cruise-1',
            title: 'Cruise One',
          ),
          excursions: <PendingShareAssignmentTarget>[
            PendingShareAssignmentTarget(
              type: PendingShareAssignmentTargetType.excursion,
              id: 'exc-1',
              title: 'Harbor Excursion',
            ),
          ],
          travelItems: <PendingShareAssignmentTarget>[],
          portCalls: <PendingShareAssignmentTarget>[],
          seaDays: <PendingShareAssignmentTarget>[],
        ),
      ],
    );
  }

  @override
  Future<UrlDocumentSaveResult> assignPendingUrlAsLinkDocument({
    required String batchId,
    required int itemIndex,
    required PendingShareAssignmentTarget target,
    bool removePendingItem = true,
  }) async {
    linkAssignmentCallCount++;
    lastRemovePendingItem = removePendingItem;
    return UrlDocumentSaveResult(
      document: _sampleDocument(),
      outcome: UrlDocumentSaveOutcome.importedAndLinked,
    );
  }

  @override
  Future<void> completePendingUrlAssignment({
    required String batchId,
    required int itemIndex,
  }) async {
    completePendingUrlAssignmentCallCount++;
  }
}

DocumentRecord _sampleDocument() {
  final timestamp = DateTime.utc(2026, 7, 1, 12);
  return DocumentRecord(
    id: 'doc-1',
    kind: DocumentKind.pdf,
    title: 'Saved URL',
    originalFileName: 'saved-url.pdf',
    mimeType: 'application/pdf',
    fileExtension: 'pdf',
    localRelativePath: 'documents/doc-1/original.pdf',
    byteSize: 3,
    contentHash: 'hash-doc-1',
    createdAt: timestamp,
    updatedAt: timestamp,
    deleted: false,
  );
}
