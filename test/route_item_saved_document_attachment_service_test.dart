import 'dart:convert';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/route/port_call_item.dart';
import 'package:cruiseplanner/models/route/route_item.dart';
import 'package:cruiseplanner/models/route/sea_day_item.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/services/documents/route_item_saved_document_attachment_service.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('RouteItemSavedDocumentAttachmentService', () {
    test('attaches a document to a PortCallItem after save', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = RouteItemSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          cruiseId: 'cruise-1',
          routeItemId: 'port-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: ' doc-1 ',
          ),
        ),
        isTrue,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final portCall = cruiseStore.getById<PortCallItem>('port-1');
      expect(portCall?.documentIds, <String>['doc-1']);
    });

    test('attaches a document to a SeaDayItem after save', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = RouteItemSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          cruiseId: 'cruise-1',
          routeItemId: 'sea-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: 'doc-1',
          ),
        ),
        isTrue,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final seaDay = cruiseStore.getById<SeaDayItem>('sea-1');
      expect(seaDay?.documentIds, <String>['doc-1']);
    });

    test('does nothing safely when sourceReference has no attachable document id', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = RouteItemSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          cruiseId: 'cruise-1',
          routeItemId: 'port-1',
          sourceReference: const DocumentImportSourceReference(
            pendingShareBatchId: 'batch-1',
            pendingShareItemIndex: 0,
          ),
        ),
        isFalse,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final portCall = cruiseStore.getById<PortCallItem>('port-1');
      expect(portCall?.documentIds, isEmpty);
    });

    test('does not duplicate an already attached document', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = RouteItemSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          cruiseId: 'cruise-1',
          routeItemId: 'port-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: 'doc-1',
          ),
        ),
        isTrue,
      );
      expect(
        await service.attachImportedDocumentIfPresent(
          cruiseId: 'cruise-1',
          routeItemId: 'port-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: 'doc-1',
          ),
        ),
        isFalse,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final portCall = cruiseStore.getById<PortCallItem>('port-1');
      expect(portCall?.documentIds, <String>['doc-1']);
    });
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

Cruise _sampleCruise() {
  return Cruise(
    id: 'cruise-1',
    title: 'Test Cruise',
    ship: const Ship(name: 'Test Ship'),
    period: Period(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 7, 14),
    ),
    route: <RouteItem>[
      PortCallItem(
        id: 'port-1',
        date: DateTime(2026, 7, 4),
        portName: 'Barcelona',
      ),
      SeaDayItem(
        id: 'sea-1',
        date: DateTime(2026, 7, 5),
      ),
    ],
  );
}

DocumentRecord _sampleDocument() {
  final timestamp = DateTime.utc(2026, 7, 4, 9);
  return DocumentRecord(
    id: 'doc-1',
    kind: DocumentKind.pdf,
    title: 'Route Ticket',
    originalFileName: 'route-ticket.pdf',
    mimeType: 'application/pdf',
    fileExtension: 'pdf',
    localRelativePath: 'documents/doc-1/original.pdf',
    byteSize: 1024,
    contentHash: 'hash-1',
    createdAt: timestamp,
    updatedAt: timestamp,
    deleted: false,
  );
}
