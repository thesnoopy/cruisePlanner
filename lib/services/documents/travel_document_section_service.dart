import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';

class TravelDocumentSectionData {
  const TravelDocumentSectionData({
    required this.linkedDocuments,
    required this.availableDocuments,
  });

  final List<DocumentRecord> linkedDocuments;
  final List<DocumentRecord> availableDocuments;

  bool get hasAvailableDocuments => availableDocuments.isNotEmpty;
}

class TravelDocumentSectionService {
  TravelDocumentSectionService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;

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
}
