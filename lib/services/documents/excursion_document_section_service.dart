import 'dart:io';

import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';
import 'document_import_service.dart';

class ExcursionDocumentSectionData {
  const ExcursionDocumentSectionData({
    required this.linkedDocuments,
    required this.availableDocuments,
  });

  final List<DocumentRecord> linkedDocuments;
  final List<DocumentRecord> availableDocuments;

  bool get hasAvailableDocuments => availableDocuments.isNotEmpty;
}

class ExcursionDocumentImportResult {
  const ExcursionDocumentImportResult({
    required this.document,
    required this.attached,
  });

  final DocumentRecord document;
  final bool attached;
}

class ExcursionDocumentSectionService {
  ExcursionDocumentSectionService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
    DocumentImportService? importService,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore(),
        _importService = importService ?? DocumentImportService();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;
  final DocumentImportService _importService;

  Future<ExcursionDocumentSectionData> loadForExcursion(
    String excursionId,
  ) async {
    final linkedDocuments = await _attachmentService.getDocumentsForExcursion(
      excursionId: excursionId,
    );
    final allDocuments = await _documentStore.loadDocuments();
    final linkedIds = linkedDocuments.map((document) => document.id).toSet();

    final availableDocuments = allDocuments
        .where((document) => !linkedIds.contains(document.id))
        .toList(growable: false);

    return ExcursionDocumentSectionData(
      linkedDocuments: List.unmodifiable(linkedDocuments),
      availableDocuments: List.unmodifiable(availableDocuments),
    );
  }

  Future<bool> attachExistingDocument({
    required String excursionId,
    required String documentId,
  }) {
    return _attachmentService.attachDocumentToExcursion(
      excursionId: excursionId,
      documentId: documentId,
    );
  }

  Future<bool> detachLinkedDocument({
    required String excursionId,
    required String documentId,
  }) {
    return _attachmentService.detachDocumentFromExcursion(
      excursionId: excursionId,
      documentId: documentId,
    );
  }

  Future<ExcursionDocumentImportResult> importDocument({
    required String excursionId,
    required String sourcePath,
    String? title,
  }) async {
    final normalizedPath = sourcePath.trim();
    if (normalizedPath.isEmpty) {
      throw ArgumentError.value(sourcePath, 'sourcePath', 'Invalid path.');
    }

    final document = await _importService.importFile(
      sourceFile: File(normalizedPath),
      title: title,
    );
    final attached = await _attachmentService.attachDocumentToExcursion(
      excursionId: excursionId,
      documentId: document.id,
    );

    return ExcursionDocumentImportResult(
      document: document,
      attached: attached,
    );
  }
}
