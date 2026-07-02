import '../../models/documents/document_import_source_reference.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';

class ExcursionSavedDocumentAttachmentService {
  ExcursionSavedDocumentAttachmentService({
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
    required String excursionId,
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

    final alreadyLinked = await _attachmentService.isDocumentLinkedToExcursion(
      excursionId: excursionId,
      documentId: documentId,
    );
    if (alreadyLinked) {
      return false;
    }

    return _attachmentService.attachDocumentToExcursion(
      excursionId: excursionId,
      documentId: documentId,
    );
  }
}
