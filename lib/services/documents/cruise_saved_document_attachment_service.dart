import '../../models/documents/document_import_source_reference.dart';
import '../../store/cruise_store.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';

class CruiseSavedDocumentAttachmentService {
  CruiseSavedDocumentAttachmentService({
    DocumentAttachmentService? attachmentService,
    DocumentStore? documentStore,
    CruiseStore? cruiseStore,
  })  : _attachmentService = attachmentService ?? DocumentAttachmentService(),
        _documentStore = documentStore ?? DocumentStore(),
        _cruiseStore = cruiseStore ?? CruiseStore();

  final DocumentAttachmentService _attachmentService;
  final DocumentStore _documentStore;
  final CruiseStore _cruiseStore;

  static String? resolveImportedDocumentId(
    DocumentImportSourceReference? sourceReference,
  ) {
    final normalizedDocumentId = sourceReference?.documentId?.trim();
    if (normalizedDocumentId == null || normalizedDocumentId.isEmpty) {
      return null;
    }

    return normalizedDocumentId;
  }

  Future<bool> attachImportedDocumentIfPresent({
    required String cruiseId,
    required DocumentImportSourceReference? sourceReference,
  }) async {
    final documentId = resolveImportedDocumentId(sourceReference);
    if (documentId == null) {
      return false;
    }

    await _cruiseStore.load();
    final cruise = _cruiseStore.getCruise(cruiseId);
    if (cruise == null) {
      return false;
    }

    final document = await _documentStore.getDocumentById(documentId);
    if (document == null || document.deleted) {
      return false;
    }

    final alreadyLinked = await _attachmentService.isDocumentLinkedToCruise(
      cruiseId: cruiseId,
      documentId: documentId,
    );
    if (alreadyLinked) {
      return false;
    }

    return _attachmentService.attachDocumentToCruise(
      cruiseId: cruiseId,
      documentId: documentId,
    );
  }
}
