import 'document_record.dart';

class PlannedLocalDocumentFileRecovery {
  const PlannedLocalDocumentFileRecovery({
    required this.documentId,
    required this.localRecord,
    required this.remoteRecord,
  });

  final String documentId;
  final DocumentRecord localRecord;
  final DocumentRecord remoteRecord;
}

class DocumentLocalFileRecoveryPlan {
  const DocumentLocalFileRecoveryPlan({
    required this.recoveries,
  });

  final List<PlannedLocalDocumentFileRecovery> recoveries;

  bool get hasRecoveries => recoveries.isNotEmpty;
}
