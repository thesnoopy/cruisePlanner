import 'dart:convert';

import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/route/route_item.dart';
import 'package:cruiseplanner/models/route/sea_day_item.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/screens/route/sea_day_detail_screen.dart';
import 'package:cruiseplanner/services/documents/document_attachment_service.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:cruiseplanner/store/document_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SeaDayItem JSON', () {
    test('loads legacy persisted data without documentIds', () {
      final item = SeaDayItem.fromMap(<String, dynamic>{
        'type': 'sea',
        'id': 'sea-1',
        'date': '2026-07-04T00:00:00.000',
        'notes': 'Legacy sea day',
      });

      expect(item.documentIds, isEmpty);
      expect(item.notes, 'Legacy sea day');
    });

    test('round-trips normalized documentIds', () {
      final item = SeaDayItem.fromMap(<String, dynamic>{
        'type': 'sea',
        'id': 'sea-1',
        'date': '2026-07-04T00:00:00.000',
        'documentIds': <String>[' doc-1 ', '', 'doc-1', 'doc-2'],
      });

      expect(item.documentIds, <String>['doc-1', 'doc-2']);
      expect(item.toMap()['documentIds'], <String>['doc-1', 'doc-2']);
    });
  });

  group('Sea day document attachments', () {
    test('attach and detach existing documents for sea days', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = DocumentAttachmentService();
      final documentStore = DocumentStore();

      expect(
        await service.attachDocumentToSeaDay(
          seaDayId: 'sea-1',
          documentId: 'doc-1',
        ),
        isTrue,
      );
      expect(
        await service.attachDocumentToSeaDay(
          seaDayId: 'sea-1',
          documentId: 'doc-1',
        ),
        isFalse,
      );

      final linkedDocuments = await service.getDocumentsForSeaDay(
        seaDayId: 'sea-1',
      );
      expect(
        linkedDocuments.map((document) => document.id).toList(),
        <String>['doc-1'],
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final seaDay = cruiseStore.getById<RouteItem>('sea-1') as SeaDayItem?;
      expect(seaDay?.documentIds, <String>['doc-1']);
      expect(await service.countDocumentReferences('doc-1'), 1);

      expect(
        await service.detachDocumentFromSeaDay(
          seaDayId: 'sea-1',
          documentId: 'doc-1',
        ),
        isTrue,
      );
      expect(
        await service.detachDocumentFromSeaDay(
          seaDayId: 'sea-1',
          documentId: 'doc-1',
        ),
        isFalse,
      );

      await cruiseStore.load();
      final detachedSeaDay = cruiseStore.getById<RouteItem>('sea-1') as SeaDayItem?;
      expect(detachedSeaDay?.documentIds, isEmpty);
      expect((await documentStore.getDocumentById('doc-1'))?.deleted, isFalse);
    });

    test('soft-deletes sea day documents when the route item is deleted', () async {
      await _seedCruise(
        _sampleCruise(
          route: <RouteItem>[
            SeaDayItem(
              id: 'sea-1',
              date: DateTime(2026, 7, 4),
              documentIds: const <String>['doc-1'],
            ),
          ],
        ),
      );
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      await cruiseStore.deleteRouteItem('sea-1');

      final deletedDocument = await DocumentStore().getDocumentById('doc-1');
      expect(deletedDocument?.deleted, isTrue);
    });
  });

  testWidgets('SeaDayDetailScreen shows linked documents', (tester) async {
    await _seedCruise(
      _sampleCruise(
        route: <RouteItem>[
          SeaDayItem(
            id: 'sea-1',
            date: DateTime(2026, 7, 4),
            notes: 'AIDAheute',
            documentIds: const <String>['doc-1'],
          ),
        ],
      ),
    );
    await _seedDocuments(<DocumentRecord>[_sampleDocument(title: 'AIDAheute PDF')]);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SeaDayDetailScreen(routeItemId: 'sea-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sea Day'), findsWidgets);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('AIDAheute PDF'), findsOneWidget);
    expect(find.text('Attach existing document'), findsNothing);
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

Future<void> _seedDocuments(List<DocumentRecord> documents) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'document_store_v1',
    jsonEncode(<String, Object>{
      'records': documents.map((document) => document.toJson()).toList(),
    }),
  );
}

Cruise _sampleCruise({
  List<RouteItem>? route,
}) {
  return Cruise(
    id: 'cruise-1',
    title: 'Test Cruise',
    ship: Ship(name: 'Test Ship'),
    period: Period(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 7, 14),
    ),
    route: route ??
        <RouteItem>[
          SeaDayItem(
            id: 'sea-1',
            date: DateTime(2026, 7, 4),
            notes: 'Quiet day',
          ),
        ],
  );
}

DocumentRecord _sampleDocument({
  String title = 'AIDAheute',
}) {
  final timestamp = DateTime.utc(2026, 7, 4, 9, 0);
  return DocumentRecord(
    id: 'doc-1',
    kind: DocumentKind.pdf,
    title: title,
    originalFileName: 'aidaheute.pdf',
    mimeType: 'application/pdf',
    fileExtension: 'pdf',
    localRelativePath: 'documents/doc-1.pdf',
    byteSize: 1024,
    contentHash: 'hash-1',
    createdAt: timestamp,
    updatedAt: timestamp,
    deleted: false,
  );
}
