import 'document_sync_analysis_result.dart';
import 'document_sync_execution_result.dart';

enum DocumentSyncExecutionPhase {
  phase3UploadDownload,
  phase4LocalFileRecovery,
}

class DocumentFullSyncExecutionResult {
  const DocumentFullSyncExecutionResult({
    required this.analysis,
    required this.analysisErrorMessage,
    required this.executedPhases,
    required this.phase3Result,
    required this.phase4Result,
  });

  final DocumentSyncAnalysisResult? analysis;
  final String? analysisErrorMessage;
  final List<DocumentSyncExecutionPhase> executedPhases;
  final DocumentSyncExecutionResult? phase3Result;
  final DocumentSyncExecutionResult? phase4Result;

  bool get hasAnalysisError => analysisErrorMessage != null;

  bool get hasFailures =>
      hasAnalysisError ||
      (phase3Result?.hasFailures ?? false) ||
      (phase4Result?.hasFailures ?? false);

  bool get hasSuccessfulActions =>
      completedUploadDocumentIds.isNotEmpty ||
      completedDownloadDocumentIds.isNotEmpty ||
      completedLocalFileRecoveryDocumentIds.isNotEmpty;

  List<String> get completedUploadDocumentIds =>
      phase3Result?.completedUploadDocumentIds ?? const <String>[];

  List<String> get completedDownloadDocumentIds =>
      phase3Result?.completedDownloadDocumentIds ?? const <String>[];

  List<String> get completedLocalFileRecoveryDocumentIds =>
      phase4Result?.completedLocalFileRecoveryDocumentIds ?? const <String>[];

  List<DocumentSyncExecutionFailure> get failures =>
      List<DocumentSyncExecutionFailure>.unmodifiable(
        <DocumentSyncExecutionFailure>[
          ...(phase3Result?.failures ?? const <DocumentSyncExecutionFailure>[]),
          ...(phase4Result?.failures ?? const <DocumentSyncExecutionFailure>[]),
        ],
      );
}
