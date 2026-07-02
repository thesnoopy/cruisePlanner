import 'dart:convert';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/models/travel/base_travel.dart';
import 'package:cruiseplanner/models/travel/transfer_item.dart';
import 'package:cruiseplanner/services/documents/travel_saved_document_attachment_service.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('TravelSavedDocumentAttachmentService', () {
    test('attaches imported documents to travel items only once', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = TravelSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          travelItemId: 'travel-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: ' doc-1 ',
          ),
        ),
        isTrue,
      );
      expect(
        await service.attachImportedDocumentIfPresent(
          travelItemId: 'travel-1',
          sourceReference: const DocumentImportSourceReference(
            documentId: 'doc-1',
          ),
        ),
        isFalse,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final travelItem = cruiseStore.getById<TransferItem>('travel-1');
      expect(travelItem?.documentIds, <String>['doc-1']);
    });

    test('ignores pending share references without imported documents', () async {
      await _seedCruise(_sampleCruise());
      await _seedDocuments(<DocumentRecord>[_sampleDocument()]);

      final service = TravelSavedDocumentAttachmentService();

      expect(
        await service.attachImportedDocumentIfPresent(
          travelItemId: 'travel-1',
          sourceReference: const DocumentImportSourceReference(
            pendingShareBatchId: 'batch-1',
            pendingShareItemIndex: 0,
          ),
        ),
        isFalse,
      );

      final cruiseStore = CruiseStore();
      await cruiseStore.load();
      final travelItem = cruiseStore.getById<TransferItem>('travel-1');
      expect(travelItem?.documentIds, isEmpty);
    });

    test('resolveImportedDocumentId trims and rejects empty ids', () {
      expect(
        TravelSavedDocumentAttachmentService.resolveImportedDocumentId(
          const DocumentImportSourceReference(documentId: ' doc-1 '),
        ),
        'doc-1',
      );
      expect(
        TravelSavedDocumentAttachmentService.resolveImportedDocumentId(
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
    travel: <TravelItem>[
      TransferItem(
        id: 'travel-1',
        start: DateTime(2026, 7, 4, 9),
        end: DateTime(2026, 7, 4, 10),
        from: 'Airport',
        to: 'Port',
      ),
    ],
  );
}

DocumentRecord _sampleDocument() {
  final timestamp = DateTime.utc(2026, 7, 4, 9);
  return DocumentRecord(
    id: 'doc-1',
    kind: DocumentKind.pdf,
    title: 'Transfer Voucher',
    originalFileName: 'transfer-voucher.pdf',
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
