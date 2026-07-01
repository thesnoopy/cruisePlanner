import '../../models/cruise.dart';
import '../../models/documents/document_ids.dart';
import '../../models/documents/document_record.dart';
import '../../models/excursion.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../models/travel/base_travel.dart';
import '../../models/travel/cruise_check_in_item.dart';
import '../../models/travel/cruise_check_out_item.dart';
import '../../models/travel/flight_item.dart';
import '../../models/travel/hotel_item.dart';
import '../../models/travel/rental_car_item.dart';
import '../../models/travel/train_item.dart';
import '../../models/travel/transfer_item.dart';
import '../../store/cruise_store.dart';
import '../../store/document_store.dart';
import 'document_reference_cleanup_service.dart';

class DocumentAttachmentService {
  DocumentAttachmentService({
    CruiseStore? cruiseStore,
    DocumentStore? documentStore,
    DocumentReferenceCleanupService? referenceCleanupService,
  })  : _cruiseStore = cruiseStore ?? CruiseStore(),
        _documentStore = documentStore ?? DocumentStore() {
    _referenceCleanupService =
        referenceCleanupService ??
        DocumentReferenceCleanupService(
          cruiseStore: _cruiseStore,
          documentStore: _documentStore,
        );
  }

  final CruiseStore _cruiseStore;
  final DocumentStore _documentStore;
  late final DocumentReferenceCleanupService _referenceCleanupService;

  Future<bool> attachDocumentToCruise({
    required String cruiseId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _cruiseStore.getCruise(cruiseId);
    if (cruise == null) {
      return false;
    }

    final nextDocumentIds = DocumentIds.appendUnique(
      cruise.documentIds,
      documentId,
    );
    if (_sameDocumentIds(cruise.documentIds, nextDocumentIds)) {
      return false;
    }

    await _cruiseStore.upsertCruise(
      cruise.copyWith(documentIds: nextDocumentIds),
    );
    return true;
  }

  Future<bool> detachDocumentFromCruise({
    required String cruiseId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _cruiseStore.getCruise(cruiseId);
    if (cruise == null) {
      return false;
    }

    final nextDocumentIds = DocumentIds.remove(
      cruise.documentIds,
      documentId,
    );
    if (_sameDocumentIds(cruise.documentIds, nextDocumentIds)) {
      return false;
    }

    await _cruiseStore.upsertCruise(
      cruise.copyWith(documentIds: nextDocumentIds),
    );
    await _softDeleteDocumentIfUnreferenced(documentId);
    return true;
  }

  Future<List<DocumentRecord>> getDocumentsForCruise({
    required String cruiseId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _cruiseStore.getCruise(cruiseId);
    if (cruise == null) {
      return const <DocumentRecord>[];
    }

    return _resolveDocuments(cruise.documentIds);
  }

  Future<bool> attachDocumentToExcursion({
    required String excursionId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _findCruiseWithExcursion(excursionId);
    final excursion = cruise?.excursions.firstWhereOrNull(
      (item) => item.id == excursionId,
    );
    if (cruise == null || excursion == null) {
      return false;
    }

    final nextDocumentIds = DocumentIds.appendUnique(
      excursion.documentIds,
      documentId,
    );
    if (_sameDocumentIds(excursion.documentIds, nextDocumentIds)) {
      return false;
    }

    await _cruiseStore.upsertExcursion(
      cruiseId: cruise.id,
      excursion: excursion.copyWith(documentIds: nextDocumentIds),
    );
    await _softDeleteDocumentIfUnreferenced(documentId);
    return true;
  }

  Future<bool> detachDocumentFromExcursion({
    required String excursionId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _findCruiseWithExcursion(excursionId);
    final excursion = cruise?.excursions.firstWhereOrNull(
      (item) => item.id == excursionId,
    );
    if (cruise == null || excursion == null) {
      return false;
    }

    final nextDocumentIds = DocumentIds.remove(
      excursion.documentIds,
      documentId,
    );
    if (_sameDocumentIds(excursion.documentIds, nextDocumentIds)) {
      return false;
    }

    await _cruiseStore.upsertExcursion(
      cruiseId: cruise.id,
      excursion: excursion.copyWith(documentIds: nextDocumentIds),
    );
    return true;
  }

  Future<List<DocumentRecord>> getDocumentsForExcursion({
    required String excursionId,
  }) async {
    await _ensureCruisesLoaded();

    final excursion = _findExcursion(excursionId);
    if (excursion == null) {
      return const <DocumentRecord>[];
    }

    return _resolveDocuments(excursion.documentIds);
  }

  Future<bool> attachDocumentToTravelItem({
    required String travelItemId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _findCruiseWithTravelItem(travelItemId);
    final travelItem = cruise?.travel.firstWhereOrNull(
      (item) => item.id == travelItemId,
    );
    if (cruise == null || travelItem == null) {
      return false;
    }

    final nextTravelItem = _copyTravelItemWithDocumentIds(
      travelItem,
      DocumentIds.appendUnique(travelItem.documentIds, documentId),
    );
    if (_sameDocumentIds(travelItem.documentIds, nextTravelItem.documentIds)) {
      return false;
    }

    await _cruiseStore.upsertTravelItem(
      cruiseId: cruise.id,
      item: nextTravelItem,
    );
    await _softDeleteDocumentIfUnreferenced(documentId);
    return true;
  }

  Future<bool> detachDocumentFromTravelItem({
    required String travelItemId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _findCruiseWithTravelItem(travelItemId);
    final travelItem = cruise?.travel.firstWhereOrNull(
      (item) => item.id == travelItemId,
    );
    if (cruise == null || travelItem == null) {
      return false;
    }

    final nextTravelItem = _copyTravelItemWithDocumentIds(
      travelItem,
      DocumentIds.remove(travelItem.documentIds, documentId),
    );
    if (_sameDocumentIds(travelItem.documentIds, nextTravelItem.documentIds)) {
      return false;
    }

    await _cruiseStore.upsertTravelItem(
      cruiseId: cruise.id,
      item: nextTravelItem,
    );
    return true;
  }

  Future<List<DocumentRecord>> getDocumentsForTravelItem({
    required String travelItemId,
  }) async {
    await _ensureCruisesLoaded();

    final travelItem = _findTravelItem(travelItemId);
    if (travelItem == null) {
      return const <DocumentRecord>[];
    }

    return _resolveDocuments(travelItem.documentIds);
  }

  Future<bool> attachDocumentToPortCall({
    required String portCallId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _findCruiseWithPortCall(portCallId);
    final portCall = cruise?.route.whereType<PortCallItem>().firstWhereOrNull(
      (item) => item.id == portCallId,
    );
    if (cruise == null || portCall == null) {
      return false;
    }

    final nextDocumentIds = DocumentIds.appendUnique(
      portCall.documentIds,
      documentId,
    );
    if (_sameDocumentIds(portCall.documentIds, nextDocumentIds)) {
      return false;
    }

    await _cruiseStore.upsertRouteItem(
      cruiseId: cruise.id,
      item: portCall.copyWith(documentIds: nextDocumentIds),
    );
    await _softDeleteDocumentIfUnreferenced(documentId);
    return true;
  }

  Future<bool> detachDocumentFromPortCall({
    required String portCallId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _findCruiseWithPortCall(portCallId);
    final portCall = cruise?.route.whereType<PortCallItem>().firstWhereOrNull(
      (item) => item.id == portCallId,
    );
    if (cruise == null || portCall == null) {
      return false;
    }

    final nextDocumentIds = DocumentIds.remove(
      portCall.documentIds,
      documentId,
    );
    if (_sameDocumentIds(portCall.documentIds, nextDocumentIds)) {
      return false;
    }

    await _cruiseStore.upsertRouteItem(
      cruiseId: cruise.id,
      item: portCall.copyWith(documentIds: nextDocumentIds),
    );
    return true;
  }

  Future<List<DocumentRecord>> getDocumentsForPortCall({
    required String portCallId,
  }) async {
    await _ensureCruisesLoaded();

    final portCall = _findPortCall(portCallId);
    if (portCall == null) {
      return const <DocumentRecord>[];
    }

    return _resolveDocuments(portCall.documentIds);
  }

  Future<bool> attachDocumentToSeaDay({
    required String seaDayId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _findCruiseWithSeaDay(seaDayId);
    final seaDay = cruise?.route.whereType<SeaDayItem>().firstWhereOrNull(
      (item) => item.id == seaDayId,
    );
    if (cruise == null || seaDay == null) {
      return false;
    }

    final nextDocumentIds = DocumentIds.appendUnique(
      seaDay.documentIds,
      documentId,
    );
    if (_sameDocumentIds(seaDay.documentIds, nextDocumentIds)) {
      return false;
    }

    await _cruiseStore.upsertRouteItem(
      cruiseId: cruise.id,
      item: seaDay.copyWith(documentIds: nextDocumentIds),
    );
    await _softDeleteDocumentIfUnreferenced(documentId);
    return true;
  }

  Future<bool> detachDocumentFromSeaDay({
    required String seaDayId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _findCruiseWithSeaDay(seaDayId);
    final seaDay = cruise?.route.whereType<SeaDayItem>().firstWhereOrNull(
      (item) => item.id == seaDayId,
    );
    if (cruise == null || seaDay == null) {
      return false;
    }

    final nextDocumentIds = DocumentIds.remove(
      seaDay.documentIds,
      documentId,
    );
    if (_sameDocumentIds(seaDay.documentIds, nextDocumentIds)) {
      return false;
    }

    await _cruiseStore.upsertRouteItem(
      cruiseId: cruise.id,
      item: seaDay.copyWith(documentIds: nextDocumentIds),
    );
    return true;
  }

  Future<List<DocumentRecord>> getDocumentsForSeaDay({
    required String seaDayId,
  }) async {
    await _ensureCruisesLoaded();

    final seaDay = _findSeaDay(seaDayId);
    if (seaDay == null) {
      return const <DocumentRecord>[];
    }

    return _resolveDocuments(seaDay.documentIds);
  }

  Future<bool> isDocumentLinkedToCruise({
    required String cruiseId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final cruise = _cruiseStore.getCruise(cruiseId);
    if (cruise == null) {
      return false;
    }

    return cruise.documentIds.contains(documentId);
  }

  Future<bool> isDocumentLinkedToExcursion({
    required String excursionId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final excursion = _findExcursion(excursionId);
    if (excursion == null) {
      return false;
    }

    return excursion.documentIds.contains(documentId);
  }

  Future<bool> isDocumentLinkedToTravelItem({
    required String travelItemId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final travelItem = _findTravelItem(travelItemId);
    if (travelItem == null) {
      return false;
    }

    return travelItem.documentIds.contains(documentId);
  }

  Future<bool> isDocumentLinkedToPortCall({
    required String portCallId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final portCall = _findPortCall(portCallId);
    if (portCall == null) {
      return false;
    }

    return portCall.documentIds.contains(documentId);
  }

  Future<bool> isDocumentLinkedToSeaDay({
    required String seaDayId,
    required String documentId,
  }) async {
    await _ensureCruisesLoaded();

    final seaDay = _findSeaDay(seaDayId);
    if (seaDay == null) {
      return false;
    }

    return seaDay.documentIds.contains(documentId);
  }

  Future<int> countDocumentReferences(String documentId) async {
    return _referenceCleanupService.countDocumentReferences(documentId);
  }

  Future<bool> isDocumentReferenced(String documentId) async {
    return _referenceCleanupService.isDocumentReferenced(documentId);
  }

  Future<void> _softDeleteDocumentIfUnreferenced(String documentId) async {
    await _referenceCleanupService.softDeleteDocumentsIfUnreferenced(
      <String>[documentId],
    );
  }

  Future<void> _ensureCruisesLoaded() async {
    await _cruiseStore.load();
  }

  Future<List<DocumentRecord>> _resolveDocuments(List<String> documentIds) async {
    final result = <DocumentRecord>[];

    for (final documentId in documentIds) {
      final record = await _documentStore.getDocumentById(documentId);
      if (record == null) {
        continue;
      }
      result.add(record);
    }

    return List.unmodifiable(result);
  }

  Cruise? _findCruiseWithExcursion(String excursionId) {
    return _cruiseStore.activeCruises.firstWhereOrNull(
      (cruise) => cruise.excursions.any((excursion) => excursion.id == excursionId),
    );
  }

  Cruise? _findCruiseWithTravelItem(String travelItemId) {
    return _cruiseStore.activeCruises.firstWhereOrNull(
      (cruise) => cruise.travel.any((travelItem) => travelItem.id == travelItemId),
    );
  }

  Cruise? _findCruiseWithPortCall(String portCallId) {
    return _cruiseStore.activeCruises.firstWhereOrNull(
      (cruise) => cruise.route.whereType<PortCallItem>().any((portCall) => portCall.id == portCallId),
    );
  }

  Cruise? _findCruiseWithSeaDay(String seaDayId) {
    return _cruiseStore.activeCruises.firstWhereOrNull(
      (cruise) => cruise.route.whereType<SeaDayItem>().any((seaDay) => seaDay.id == seaDayId),
    );
  }

  Excursion? _findExcursion(String excursionId) {
    final cruise = _findCruiseWithExcursion(excursionId);
    return cruise?.excursions.firstWhereOrNull(
      (excursion) => excursion.id == excursionId,
    );
  }

  TravelItem? _findTravelItem(String travelItemId) {
    final cruise = _findCruiseWithTravelItem(travelItemId);
    return cruise?.travel.firstWhereOrNull(
      (travelItem) => travelItem.id == travelItemId,
    );
  }

  PortCallItem? _findPortCall(String portCallId) {
    final cruise = _findCruiseWithPortCall(portCallId);
    return cruise?.route.whereType<PortCallItem>().firstWhereOrNull(
      (portCall) => portCall.id == portCallId,
    );
  }

  SeaDayItem? _findSeaDay(String seaDayId) {
    final cruise = _findCruiseWithSeaDay(seaDayId);
    return cruise?.route.whereType<SeaDayItem>().firstWhereOrNull(
      (seaDay) => seaDay.id == seaDayId,
    );
  }

  TravelItem _copyTravelItemWithDocumentIds(
    TravelItem item,
    List<String> documentIds,
  ) {
    if (item is FlightItem) {
      return item.copyWith(documentIds: documentIds);
    }
    if (item is TrainItem) {
      return item.copyWith(documentIds: documentIds);
    }
    if (item is TransferItem) {
      return item.copyWith(documentIds: documentIds);
    }
    if (item is RentalCarItem) {
      return item.copyWith(documentIds: documentIds);
    }
    if (item is HotelItem) {
      return item.copyWith(documentIds: documentIds);
    }
    if (item is CruiseCheckIn) {
      return item.copyWith(documentIds: documentIds);
    }
    if (item is CruiseCheckOut) {
      return item.copyWith(documentIds: documentIds);
    }

    throw ArgumentError.value(item, 'item', 'Unsupported travel item type.');
  }

  bool _sameDocumentIds(List<String> left, List<String> right) {
    if (identical(left, right)) {
      return true;
    }

    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E value) test) {
    for (final value in this) {
      if (test(value)) {
        return value;
      }
    }

    return null;
  }
}
