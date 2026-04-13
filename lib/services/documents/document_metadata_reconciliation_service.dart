import '../../models/documents/document_metadata_reconciliation_result.dart';
import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_remote_store.dart';

class DocumentMetadataReconciliationService {
  DocumentMetadataReconciliationService({
    DocumentStore? documentStore,
    required DocumentRemoteStore remoteStore,
  })  : _documentStore = documentStore ?? DocumentStore(),
        _remoteStore = remoteStore;

  final DocumentStore _documentStore;
  final DocumentRemoteStore _remoteStore;

  Future<DocumentMetadataReconciliationResult> reconcile() async {
    final localDocuments = await _documentStore.loadDocuments(
      includeDeleted: true,
    );
    final remoteDocuments = await _remoteStore.readDocuments();

    final localById = _indexById(localDocuments);
    final remoteById = _indexById(remoteDocuments);
    final documentIds = <String>{
      ...localById.keys,
      ...remoteById.keys,
    }.toList()
      ..sort();

    final localOnly = <DocumentRecord>[];
    final remoteOnly = <DocumentRecord>[];
    final both = <DocumentMetadataReconciliationMatch>[];

    for (final documentId in documentIds) {
      final localRecord = localById[documentId];
      final remoteRecord = remoteById[documentId];

      if (localRecord != null && remoteRecord != null) {
        both.add(
          DocumentMetadataReconciliationMatch(
            documentId: documentId,
            localRecord: localRecord,
            remoteRecord: remoteRecord,
          ),
        );
        continue;
      }

      if (localRecord != null) {
        localOnly.add(localRecord);
        continue;
      }

      if (remoteRecord != null) {
        remoteOnly.add(remoteRecord);
      }
    }

    return DocumentMetadataReconciliationResult(
      localOnly: List<DocumentRecord>.unmodifiable(localOnly),
      remoteOnly: List<DocumentRecord>.unmodifiable(remoteOnly),
      both: List<DocumentMetadataReconciliationMatch>.unmodifiable(both),
    );
  }

  Map<String, DocumentRecord> _indexById(List<DocumentRecord> documents) {
    final result = <String, DocumentRecord>{};
    for (final document in documents) {
      result[document.id] = document;
    }
    return result;
  }
}
