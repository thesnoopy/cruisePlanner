import 'dart:io';

import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';
import 'document_import_service.dart';

class PortCallDocumentSectionData {
  const PortCallDocumentSectionData({
    required this.linkedDocuments,
    required this.availableDocuments,
  });

  final List<DocumentRecord> linkedDocuments;
  final List<DocumentRecord> availableDocuments;

  bool get hasAvailableDocuments => availableDocuments.isNotEmpty;
}

class PortCallDocumentImportResult {
  const PortCallDocumentImportResult({
    required this.document,
    required this.attached,
  });

  final DocumentRecord document;
  final bool attached;
}

class PortCallDocumentSectionService {
  PortCallDocumentSectionService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
    DocumentImportService? importService,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore(),
        _importService = importService ?? DocumentImportService();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;
  final DocumentImportService _importService;

  Future<PortCallDocumentSectionData> loadForPortCall(String portCallId) async {
    final linkedDocuments = await _attachmentService.getDocumentsForPortCall(
      portCallId: portCallId,
    );
    final allDocuments = await _documentStore.loadDocuments();
    final linkedIds = linkedDocuments.map((document) => document.id).toSet();

    final availableDocuments = allDocuments
        .where((document) => !linkedIds.contains(document.id))
        .toList(growable: false);

    return PortCallDocumentSectionData(
      linkedDocuments: List.unmodifiable(linkedDocuments),
      availableDocuments: List.unmodifiable(availableDocuments),
    );
  }

  Future<bool> attachExistingDocument({
    required String portCallId,
    required String documentId,
  }) {
    return _attachmentService.attachDocumentToPortCall(
      portCallId: portCallId,
      documentId: documentId,
    );
  }

  Future<bool> detachLinkedDocument({
    required String portCallId,
    required String documentId,
  }) {
    return _attachmentService.detachDocumentFromPortCall(
      portCallId: portCallId,
      documentId: documentId,
    );
  }

  Future<PortCallDocumentImportResult> importDocument({
    required String portCallId,
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
    final attached = await _attachmentService.attachDocumentToPortCall(
      portCallId: portCallId,
      documentId: document.id,
    );

    return PortCallDocumentImportResult(
      document: document,
      attached: attached,
    );
  }
}
