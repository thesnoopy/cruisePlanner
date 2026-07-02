import 'dart:convert';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/services/documents/excursion_saved_document_attachment_service.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ExcursionSavedDocumentAttachmentService', () {
    test('attaches imported documents to excursions only once', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = ExcursionSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          excursionId: 'exc-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: ' doc-1 ',
          ),
        ),
        isTrue,
      );
      expect(
        await service.attachImportedDocumentIfPresent(
          excursionId: 'exc-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: 'doc-1',
          ),
        ),
        isFalse,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final excursion = cruiseStore.getById<Excursion>('exc-1');
      expect(excursion?.documentIds, <String>['doc-1']);
    });

    test('ignores pending share references without imported documents', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = ExcursionSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          excursionId: 'exc-1',
          sourceReference: const DocumentImportSourceReference(
            pendingShareBatchId: 'batch-1',
            pendingShareItemIndex: 0,
          ),
        ),
        isFalse,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final excursion = cruiseStore.getById<Excursion>('exc-1');
      expect(excursion?.documentIds, isEmpty);
    });

    test('resolveImportedDocumentId trims and rejects empty ids', () {
      expect(
        ExcursionSavedDocumentAttachmentService.resolveImportedDocumentId(
          const DocumentImportSourceReference(documentId: ' doc-1 '),
        ),
        'doc-1',
      );
      expect(
        ExcursionSavedDocumentAttachmentService.resolveImportedDocumentId(
          const DocumentImportSourceReference(documentId: '   '),
        ),
        isNull,
      );
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
    excursions: <Excursion>[
      Excursion(
        id: 'exc-1',
        title: 'Beach Shuttle',
        date: DateTime(2026, 7, 4, 9),
      ),
    ],
  );
}

DocumentRecord _sampleDocument() {
  final timestamp = DateTime.utc(2026, 7, 4, 9);
  return DocumentRecord(
    id: 'doc-1',
    kind: DocumentKind.pdf,
    title: 'Beach Ticket',
    originalFileName: 'beach-ticket.pdf',
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
