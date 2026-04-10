import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';

class CruiseDocumentSectionData {
  const CruiseDocumentSectionData({
    required this.linkedDocuments,
    required this.availableDocuments,
  });

  final List<DocumentRecord> linkedDocuments;
  final List<DocumentRecord> availableDocuments;

  bool get hasAvailableDocuments => availableDocuments.isNotEmpty;
}

class CruiseDocumentSectionService {
  CruiseDocumentSectionService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;

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
}
