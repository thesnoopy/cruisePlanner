import 'dart:io';

import '../../models/documents/document_import_resolution.dart';
import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';
import 'document_import_service.dart';
import 'url_snapshot_import_service.dart';

class TravelDocumentSectionData {
  const TravelDocumentSectionData({
    required this.linkedDocuments,
    required this.availableDocuments,
  });

  final List<DocumentRecord> linkedDocuments;
  final List<DocumentRecord> availableDocuments;

  bool get hasAvailableDocuments => availableDocuments.isNotEmpty;
}

class TravelDocumentImportResult {
  const TravelDocumentImportResult({
    required this.document,
    required this.outcome,
  });

  final DocumentRecord document;
  final TravelDocumentImportOutcome outcome;
}

enum TravelDocumentImportOutcome {
  importedAndLinked,
  existingLinked,
  alreadyLinked,
}

class TravelDocumentSectionService {
  TravelDocumentSectionService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
    DocumentImportService? importService,
    UrlSnapshotImportService? urlSnapshotImportService,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore(),
        _importService = importService ?? DocumentImportService(),
        _urlSnapshotImportService =
            urlSnapshotImportService ?? UrlSnapshotImportService();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;
  final DocumentImportService _importService;
  final UrlSnapshotImportService _urlSnapshotImportService;

  Future<TravelDocumentSectionData> loadForTravelItem(String travelItemId) async {
    final linkedDocuments = await _attachmentService.getDocumentsForTravelItem(
      travelItemId: travelItemId,
    );
    final allDocuments = await _documentStore.loadDocuments();
    final linkedIds = linkedDocuments.map((document) => document.id).toSet();

    final availableDocuments = allDocuments
        .where((document) => !linkedIds.contains(document.id))
        .toList(growable: false);

    return TravelDocumentSectionData(
      linkedDocuments: List.unmodifiable(linkedDocuments),
      availableDocuments: List.unmodifiable(availableDocuments),
    );
  }

  Future<bool> attachExistingDocument({
    required String travelItemId,
    required String documentId,
  }) {
    return _attachmentService.attachDocumentToTravelItem(
      travelItemId: travelItemId,
      documentId: documentId,
    );
  }

  Future<bool> detachLinkedDocument({
    required String travelItemId,
    required String documentId,
  }) {
    return _attachmentService.detachDocumentFromTravelItem(
      travelItemId: travelItemId,
      documentId: documentId,
    );
  }

  Future<TravelDocumentImportResult> importDocument({
    required String travelItemId,
    required String sourcePath,
    String? title,
  }) async {
    final normalizedPath = sourcePath.trim();
    if (normalizedPath.isEmpty) {
      throw ArgumentError.value(sourcePath, 'sourcePath', 'Invalid path.');
    }

    final importResolution = await _importService.importFileIfNeeded(
      sourceFile: File(normalizedPath),
      title: title,
    );
    final linkedDocuments = await _attachmentService.getDocumentsForTravelItem(
      travelItemId: travelItemId,
    );
    final alreadyLinked = linkedDocuments.any(
      (document) => document.id == importResolution.document.id,
    );
    if (alreadyLinked) {
      return TravelDocumentImportResult(
        document: importResolution.document,
        outcome: TravelDocumentImportOutcome.alreadyLinked,
      );
    }

    final attached = await _attachmentService.attachDocumentToTravelItem(
      travelItemId: travelItemId,
      documentId: importResolution.document.id,
    );
    if (!attached) {
      throw StateError('Failed to attach document to travel item.');
    }

    return TravelDocumentImportResult(
      document: importResolution.document,
      outcome: importResolution.kind == DocumentImportResolutionKind.imported
          ? TravelDocumentImportOutcome.importedAndLinked
          : TravelDocumentImportOutcome.existingLinked,
    );
  }

  Future<TravelDocumentImportResult> importUrlDocument({
    required String travelItemId,
    required String sourceUrl,
    String? title,
  }) async {
    final document = await _urlSnapshotImportService.importUrl(
      sourceUrl: sourceUrl,
      title: title,
    );
    return _attachImportedDocument(
      travelItemId: travelItemId,
      document: document,
    );
  }

  Future<TravelDocumentImportResult> _attachImportedDocument({
    required String travelItemId,
    required DocumentRecord document,
  }) async {
    final linkedDocuments = await _attachmentService.getDocumentsForTravelItem(
      travelItemId: travelItemId,
    );
    final alreadyLinked = linkedDocuments.any(
      (linkedDocument) => linkedDocument.id == document.id,
    );
    if (alreadyLinked) {
      return TravelDocumentImportResult(
        document: document,
        outcome: TravelDocumentImportOutcome.alreadyLinked,
      );
    }

    final attached = await _attachmentService.attachDocumentToTravelItem(
      travelItemId: travelItemId,
      documentId: document.id,
    );
    if (!attached) {
      throw StateError('Failed to attach document to travel item.');
    }

    return TravelDocumentImportResult(
      document: document,
      outcome: TravelDocumentImportOutcome.importedAndLinked,
    );
  }
}
