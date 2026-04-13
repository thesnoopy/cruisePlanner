import 'document_sync_analysis_result.dart';

enum DocumentSyncExecutionAction {
  upload,
  download,
}

class DocumentSyncExecutionFailure {
  const DocumentSyncExecutionFailure({
    required this.documentId,
    required this.action,
    required this.errorMessage,
  });

  final String documentId;
  final DocumentSyncExecutionAction action;
  final String errorMessage;
}

class DocumentSyncExecutionResult {
  const DocumentSyncExecutionResult({
    required this.analysis,
    required this.analysisErrorMessage,
    required this.completedUploadDocumentIds,
    required this.completedDownloadDocumentIds,
    required this.failures,
  });

  final DocumentSyncAnalysisResult? analysis;
  final String? analysisErrorMessage;
  final List<String> completedUploadDocumentIds;
  final List<String> completedDownloadDocumentIds;
  final List<DocumentSyncExecutionFailure> failures;

  bool get hasAnalysisError => analysisErrorMessage != null;

  bool get hasFailures => hasAnalysisError || failures.isNotEmpty;

  bool get hasSuccessfulActions =>
      completedUploadDocumentIds.isNotEmpty ||
      completedDownloadDocumentIds.isNotEmpty;
}
