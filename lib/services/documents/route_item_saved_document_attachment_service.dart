import '../../models/documents/document_import_source_reference.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/route_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../store/cruise_store.dart';
import '../../store/document_store.dart';
import 'document_attachment_service.dart';

class RouteItemSavedDocumentAttachmentService {
  RouteItemSavedDocumentAttachmentService({
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
    required String routeItemId,
    required DocumentImportSourceReference? sourceReference,
  }) async {
    final documentId = resolveImportedDocumentId(sourceReference);
    if (documentId == null) {
      return false;
    }

    await _cruiseStore.load();
    final cruise = _cruiseStore.getCruise(cruiseId);
    final routeItem = _findRouteItem(cruise?.route, routeItemId);
    if (routeItem == null) {
      return false;
    }

    final document = await _documentStore.getDocumentById(documentId);
    if (document == null || document.deleted) {
      return false;
    }

    if (routeItem is PortCallItem) {
      final alreadyLinked = await _attachmentService.isDocumentLinkedToPortCall(
        portCallId: routeItemId,
        documentId: documentId,
      );
      if (alreadyLinked) {
        return false;
      }

      return _attachmentService.attachDocumentToPortCall(
        portCallId: routeItemId,
        documentId: documentId,
      );
    }

    if (routeItem is SeaDayItem) {
      final alreadyLinked = await _attachmentService.isDocumentLinkedToSeaDay(
        seaDayId: routeItemId,
        documentId: documentId,
      );
      if (alreadyLinked) {
        return false;
      }

      return _attachmentService.attachDocumentToSeaDay(
        seaDayId: routeItemId,
        documentId: documentId,
      );
    }

    return false;
  }

  RouteItem? _findRouteItem(List<RouteItem>? routeItems, String routeItemId) {
    if (routeItems == null) {
      return null;
    }

    for (final routeItem in routeItems) {
      if (routeItem.id == routeItemId) {
        return routeItem;
      }
    }

    return null;
  }
}
