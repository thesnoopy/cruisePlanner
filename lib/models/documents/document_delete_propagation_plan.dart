import 'document_record.dart';

class PlannedLocalDocumentSoftDelete {
  const PlannedLocalDocumentSoftDelete({
    required this.documentId,
    required this.localRecord,
    required this.remoteRecord,
  });

  final String documentId;
  final DocumentRecord localRecord;
  final DocumentRecord remoteRecord;
}

class PlannedRemoteDocumentSoftDelete {
  const PlannedRemoteDocumentSoftDelete({
    required this.documentId,
    required this.localRecord,
    required this.remoteRecord,
  });

  final String documentId;
  final DocumentRecord localRecord;
  final DocumentRecord remoteRecord;
}

class DocumentDeletePropagationPlan {
  const DocumentDeletePropagationPlan({
    required this.plannedLocalSoftDeletes,
    required this.plannedRemoteSoftDeletes,
  });

  final List<PlannedLocalDocumentSoftDelete> plannedLocalSoftDeletes;
  final List<PlannedRemoteDocumentSoftDelete> plannedRemoteSoftDeletes;

  bool get hasActions =>
      plannedLocalSoftDeletes.isNotEmpty || plannedRemoteSoftDeletes.isNotEmpty;
}
