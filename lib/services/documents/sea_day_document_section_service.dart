import 'dart:io';

import '../../models/documents/document_import_resolution.dart';
import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';
import 'document_import_service.dart';
import 'url_snapshot_import_service.dart';

class SeaDayDocumentSectionData {
  const SeaDayDocumentSectionData({
    required this.linkedDocuments,
    required this.availableDocuments,
  });

  final List<DocumentRecord> linkedDocuments;
  final List<DocumentRecord> availableDocuments;

  bool get hasAvailableDocuments => availableDocuments.isNotEmpty;
}

class SeaDayDocumentImportResult {
  const SeaDayDocumentImportResult({
    required this.document,
    required this.outcome,
  });

  final DocumentRecord document;
  final SeaDayDocumentImportOutcome outcome;
}

enum SeaDayDocumentImportOutcome {
  importedAndLinked,
  existingLinked,
  alreadyLinked,
}

class SeaDayDocumentSectionService {
  SeaDayDocumentSectionService({
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

  Future<SeaDayDocumentSectionData> loadForSeaDay(String seaDayId) async {
    final linkedDocuments = await _attachmentService.getDocumentsForSeaDay(
      seaDayId: seaDayId,
    );
    final allDocuments = await _documentStore.loadDocuments();
    final linkedIds = linkedDocuments.map((document) => document.id).toSet();

    final availableDocuments = allDocuments
        .where((document) => !linkedIds.contains(document.id))
        .toList(growable: false);

    return SeaDayDocumentSectionData(
      linkedDocuments: List.unmodifiable(linkedDocuments),
      availableDocuments: List.unmodifiable(availableDocuments),
    );
  }

  Future<bool> attachExistingDocument({
    required String seaDayId,
    required String documentId,
  }) {
    return _attachmentService.attachDocumentToSeaDay(
      seaDayId: seaDayId,
      documentId: documentId,
    );
  }

  Future<bool> detachLinkedDocument({
    required String seaDayId,
    required String documentId,
  }) {
    return _attachmentService.detachDocumentFromSeaDay(
      seaDayId: seaDayId,
      documentId: documentId,
    );
  }

  Future<SeaDayDocumentImportResult> importDocument({
    required String seaDayId,
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
    final linkedDocuments = await _attachmentService.getDocumentsForSeaDay(
      seaDayId: seaDayId,
    );
    final alreadyLinked = linkedDocuments.any(
      (document) => document.id == importResolution.document.id,
    );
    if (alreadyLinked) {
      return SeaDayDocumentImportResult(
        document: importResolution.document,
        outcome: SeaDayDocumentImportOutcome.alreadyLinked,
      );
    }

    final attached = await _attachmentService.attachDocumentToSeaDay(
      seaDayId: seaDayId,
      documentId: importResolution.document.id,
    );
    if (!attached) {
      throw StateError('Failed to attach document to sea day.');
    }

    return SeaDayDocumentImportResult(
      document: importResolution.document,
      outcome: importResolution.kind == DocumentImportResolutionKind.imported
          ? SeaDayDocumentImportOutcome.importedAndLinked
          : SeaDayDocumentImportOutcome.existingLinked,
    );
  }

  Future<SeaDayDocumentImportResult> importUrlDocument({
    required String seaDayId,
    required String sourceUrl,
    String? title,
  }) async {
    final document = await _urlSnapshotImportService.importUrl(
      sourceUrl: sourceUrl,
      title: title,
    );
    return _attachImportedDocument(
      seaDayId: seaDayId,
      document: document,
    );
  }

  Future<SeaDayDocumentImportResult> _attachImportedDocument({
    required String seaDayId,
    required DocumentRecord document,
  }) async {
    final linkedDocuments = await _attachmentService.getDocumentsForSeaDay(
      seaDayId: seaDayId,
    );
    final alreadyLinked = linkedDocuments.any(
      (linkedDocument) => linkedDocument.id == document.id,
    );
    if (alreadyLinked) {
      return SeaDayDocumentImportResult(
        document: document,
        outcome: SeaDayDocumentImportOutcome.alreadyLinked,
      );
    }

    final attached = await _attachmentService.attachDocumentToSeaDay(
      seaDayId: seaDayId,
      documentId: document.id,
    );
    if (!attached) {
      throw StateError('Failed to attach document to sea day.');
    }

    return SeaDayDocumentImportResult(
      document: document,
      outcome: SeaDayDocumentImportOutcome.importedAndLinked,
    );
  }
}
