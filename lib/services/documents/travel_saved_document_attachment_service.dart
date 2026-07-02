import '../../models/documents/document_import_source_reference.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';

class TravelSavedDocumentAttachmentService {
  TravelSavedDocumentAttachmentService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;

  static String? resolveImportedDocumentId(
    DocumentImportSourceReference sourceReference,
  ) {
    final normalizedDocumentId = sourceReference.documentId?.trim();
    if (normalizedDocumentId == null || normalizedDocumentId.isEmpty) {
      return null;
    }

    return normalizedDocumentId;
  }

  Future<bool> attachImportedDocumentIfPresent({
    required String travelItemId,
    required DocumentImportSourceReference sourceReference,
  }) async {
    final documentId = resolveImportedDocumentId(sourceReference);
    if (documentId == null) {
      return false;
    }

    final document = await _documentStore.getDocumentById(documentId);
    if (document == null || document.deleted) {
      return false;
    }

    final alreadyLinked = await _attachmentService.isDocumentLinkedToTravelItem(
      travelItemId: travelItemId,
      documentId: documentId,
    );
    if (alreadyLinked) {
      return false;
    }

    return _attachmentService.attachDocumentToTravelItem(
      travelItemId: travelItemId,
      documentId: documentId,
    );
  }
}
