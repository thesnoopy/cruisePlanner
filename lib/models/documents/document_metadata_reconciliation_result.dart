import 'document_record.dart';

class DocumentMetadataReconciliationMatch {
  const DocumentMetadataReconciliationMatch({
    required this.documentId,
    required this.localRecord,
    required this.remoteRecord,
  });

  final String documentId;
  final DocumentRecord localRecord;
  final DocumentRecord remoteRecord;
}

class DocumentMetadataReconciliationResult {
  const DocumentMetadataReconciliationResult({
    required this.localOnly,
    required this.remoteOnly,
    required this.both,
  });

  final List<DocumentRecord> localOnly;
  final List<DocumentRecord> remoteOnly;
  final List<DocumentMetadataReconciliationMatch> both;
}
