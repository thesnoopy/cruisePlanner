import 'dart:io';

import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';
import 'document_import_service.dart';

class CruiseDocumentSectionData {
  const CruiseDocumentSectionData({
    required this.linkedDocuments,
    required this.availableDocuments,
  });

  final List<DocumentRecord> linkedDocuments;
  final List<DocumentRecord> availableDocuments;

  bool get hasAvailableDocuments => availableDocuments.isNotEmpty;
}

class CruiseDocumentImportResult {
  const CruiseDocumentImportResult({
    required this.document,
    required this.attached,
  });

  final DocumentRecord document;
  final bool attached;
}

class CruiseDocumentSectionService {
  CruiseDocumentSectionService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
    DocumentImportService? importService,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore(),
        _importService = importService ?? DocumentImportService();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;
  final DocumentImportService _importService;

  Future<CruiseDocumentSectionData> loadForCruise(String cruiseId) async {
    final linkedDocuments = await _attachmentService.getDocumentsForCruise(
      cruiseId: cruiseId,
    );
    final allDocuments = await _documentStore.loadDocuments();
    final linkedIds = linkedDocuments.map((document) => document.id).toSet();

    final availableDocuments = allDocuments
        .where((document) => !linkedIds.contains(document.id))
        .toList(growable: false);

    return CruiseDocumentSectionData(
      linkedDocuments: List.unmodifiable(linkedDocuments),
      availableDocuments: List.unmodifiable(availableDocuments),
    );
  }

  Future<bool> attachExistingDocument({
    required String cruiseId,
    required String documentId,
  }) {
    return _attachmentService.attachDocumentToCruise(
      cruiseId: cruiseId,
      documentId: documentId,
    );
  }

  Future<bool> detachLinkedDocument({
    required String cruiseId,
    required String documentId,
  }) {
    return _attachmentService.detachDocumentFromCruise(
      cruiseId: cruiseId,
      documentId: documentId,
    );
  }

  Future<CruiseDocumentImportResult> importDocument({
    required String cruiseId,
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
    final attached = await _attachmentService.attachDocumentToCruise(
      cruiseId: cruiseId,
      documentId: document.id,
    );

    return CruiseDocumentImportResult(
      document: document,
      attached: attached,
    );
  }
}
