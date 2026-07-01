import '../../models/cruise.dart';
import '../../models/documents/document_ids.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../store/cruise_store.dart';
import '../../store/document_store.dart';

class DocumentReferenceCleanupService {
  DocumentReferenceCleanupService({
    CruiseStore? cruiseStore,
    DocumentStore? documentStore,
  })  : _cruiseStore = cruiseStore ?? CruiseStore(),
        _documentStore = documentStore ?? DocumentStore();

  final CruiseStore _cruiseStore;
  final DocumentStore _documentStore;

  Future<void> softDeleteDocumentsIfUnreferenced(
    Iterable<String> documentIds,
  ) async {
    for (final documentId in _normalizeDocumentIds(documentIds)) {
      if (await isDocumentReferenced(documentId)) {
        continue;
      }

      await _documentStore.deleteDocumentSoft(documentId);
    }
  }

  Future<int> countDocumentReferences(String documentId) async {
    await _ensureCruisesLoaded();

    final normalizedDocumentIds = _normalizeDocumentIds(<String>[documentId]);
    if (normalizedDocumentIds.isEmpty) {
      return 0;
    }

    final normalizedDocumentId = normalizedDocumentIds.first;
    var references = 0;

    for (final cruise in _cruiseStore.cruises) {
      references += _countDocumentId(cruise.documentIds, normalizedDocumentId);

      for (final excursion in cruise.excursions) {
        references += _countDocumentId(
          excursion.documentIds,
          normalizedDocumentId,
        );
      }

      for (final travelItem in cruise.travel) {
        references += _countDocumentId(
          travelItem.documentIds,
          normalizedDocumentId,
        );
      }

      for (final portCall in cruise.route.whereType<PortCallItem>()) {
        references += _countDocumentId(
          portCall.documentIds,
          normalizedDocumentId,
        );
      }

      for (final seaDay in cruise.route.whereType<SeaDayItem>()) {
        references += _countDocumentId(
          seaDay.documentIds,
          normalizedDocumentId,
        );
      }
    }

    return references;
  }

  Future<bool> isDocumentReferenced(String documentId) async {
    return (await countDocumentReferences(documentId)) > 0;
  }

  List<String> collectCruiseDocumentIds(Cruise cruise) {
    final documentIds = <String>[
      ...cruise.documentIds,
      for (final excursion in cruise.excursions) ...excursion.documentIds,
      for (final travelItem in cruise.travel) ...travelItem.documentIds,
      for (final portCall in cruise.route.whereType<PortCallItem>())
        ...portCall.documentIds,
      for (final seaDay in cruise.route.whereType<SeaDayItem>())
        ...seaDay.documentIds,
    ];

    return List.unmodifiable(_normalizeDocumentIds(documentIds));
  }

  Future<void> _ensureCruisesLoaded() async {
    await _cruiseStore.load();
  }

  List<String> _normalizeDocumentIds(Iterable<String> documentIds) {
    return DocumentIds.fromJsonValue(documentIds.toList(growable: false));
  }

  int _countDocumentId(List<String> documentIds, String documentId) {
    var count = 0;
    for (final currentId in documentIds) {
      if (currentId == documentId) {
        count++;
      }
    }
    return count;
  }
}
