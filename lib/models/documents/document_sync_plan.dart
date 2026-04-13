import 'document_record.dart';

class PlannedDocumentUpload {
  const PlannedDocumentUpload({
    required this.localRecord,
  });

  final DocumentRecord localRecord;

  String get documentId => localRecord.id;
}

class PlannedDocumentDownload {
  const PlannedDocumentDownload({
    required this.remoteRecord,
  });

  final DocumentRecord remoteRecord;

  String get documentId => remoteRecord.id;
}

class DocumentSyncPlan {
  const DocumentSyncPlan({
    required this.uploads,
    required this.downloads,
  });

  final List<PlannedDocumentUpload> uploads;
  final List<PlannedDocumentDownload> downloads;

  bool get hasActions => uploads.isNotEmpty || downloads.isNotEmpty;
}
