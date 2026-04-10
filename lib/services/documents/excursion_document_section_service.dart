import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';

class ExcursionDocumentSectionData {
  const ExcursionDocumentSectionData({
    required this.linkedDocuments,
    required this.availableDocuments,
  });

  final List<DocumentRecord> linkedDocuments;
  final List<DocumentRecord> availableDocuments;

  bool get hasAvailableDocuments => availableDocuments.isNotEmpty;
}

class ExcursionDocumentSectionService {
  ExcursionDocumentSectionService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;

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
}
