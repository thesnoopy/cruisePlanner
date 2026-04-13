import 'document_record.dart';

class PlannedDocumentHardDelete {
  const PlannedDocumentHardDelete({
    required this.documentId,
    required this.localRecord,
    required this.remoteRecord,
  });

  final String documentId;
  final DocumentRecord localRecord;
  final DocumentRecord remoteRecord;
}

class DocumentCleanupPlan {
  const DocumentCleanupPlan({
    required this.plannedHardDeletes,
  });

  final List<PlannedDocumentHardDelete> plannedHardDeletes;

  bool get hasCandidates => plannedHardDeletes.isNotEmpty;
}
