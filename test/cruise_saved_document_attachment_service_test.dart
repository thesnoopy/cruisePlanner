import 'dart:convert';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/services/documents/cruise_saved_document_attachment_service.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('CruiseSavedDocumentAttachmentService', () {
    test('attaches document to existing cruise', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = CruiseSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          cruiseId: 'cruise-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: ' doc-1 ',
          ),
        ),
        isTrue,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final cruise = cruiseStore.getCruise('cruise-1');
      expect(cruise?.documentIds, <String>['doc-1']);
    });

    test(
      'does nothing safely when sourceReference has no attachable document id',
      () async {
        await _seedCruise(_sampleCruise());
        await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

        final service = CruiseSavedDocumentAttachmentService();

        expect(
          await service.attachImportedDocumentIfPresent(
            cruiseId: 'cruise-1',
            sourceReference: const DocumentImportSourceReference(
              pendingShareBatchId: 'batch-1',
              pendingShareItemIndex: 0,
            ),
          ),
          isFalse,
        );

        final cruiseStore = CruiseStore();
        await cruiseStore.load();
        final cruise = cruiseStore.getCruise('cruise-1');
        expect(cruise?.documentIds, isEmpty);
      },
    );

    test('does not duplicate an already attached document', () async {
      await _seedCruise(_sampleCruise(documentIds: <String>['doc-1']));
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = CruiseSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          cruiseId: 'cruise-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: 'doc-1',
          ),
        ),
        isFalse,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final cruise = cruiseStore.getCruise('cruise-1');
      expect(cruise?.documentIds, <String>['doc-1']);
    });

    test('does nothing safely when the document is missing or deleted', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[
        _sampleDocument(id: 'doc-deleted', deleted: true),
      ]);

      final service = CruiseSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          cruiseId: 'cruise-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: 'doc-missing',
          ),
        ),
        isFalse,
      );
      expect(
        await service.attachImportedDocumentIfPresent(
          cruiseId: 'cruise-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: 'doc-deleted',
          ),
        ),
        isFalse,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final cruise = cruiseStore.getCruise('cruise-1');
      expect(cruise?.documentIds, isEmpty);
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

Cruise _sampleCruise({
  List<String> documentIds = const <String>[],
}) {
  return Cruise(
    id: 'cruise-1',
    title: 'Test Cruise',
    ship: const Ship(name: 'Test Ship'),
    period: Period(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 7, 14),
    ),
    documentIds: documentIds,
  );
}

DocumentRecord _sampleDocument({
  String id = 'doc-1',
  bool deleted = false,
}) {
  final timestamp = DateTime.utc(2026, 7, 4, 9);
  return DocumentRecord(
    id: id,
    kind: DocumentKind.pdf,
    title: 'Cruise Ticket',
    originalFileName: 'cruise-ticket.pdf',
    mimeType: 'application/pdf',
    fileExtension: 'pdf',
    localRelativePath: 'documents/$id/original.pdf',
    byteSize: 1024,
    contentHash: 'hash-$id',
    createdAt: timestamp,
    updatedAt: timestamp,
    deleted: deleted,
  );
}
