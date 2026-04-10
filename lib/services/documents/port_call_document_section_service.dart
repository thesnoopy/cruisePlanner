import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';

class PortCallDocumentSectionData {
  const PortCallDocumentSectionData({
    required this.linkedDocuments,
    required this.availableDocuments,
  });

  final List<DocumentRecord> linkedDocuments;
  final List<DocumentRecord> availableDocuments;

  bool get hasAvailableDocuments => availableDocuments.isNotEmpty;
}

class PortCallDocumentSectionService {
  PortCallDocumentSectionService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;

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
}
