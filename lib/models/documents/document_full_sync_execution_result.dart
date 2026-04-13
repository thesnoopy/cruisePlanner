import 'document_sync_analysis_result.dart';
import 'document_sync_execution_result.dart';

enum DocumentSyncExecutionPhase {
  phase3UploadDownload,
  phase4LocalFileRecovery,
  phase5SoftDeletePropagation,
  phase6CleanupHardDelete,
}

class DocumentFullSyncExecutionResult {
  const DocumentFullSyncExecutionResult({
    required this.analysis,
    required this.analysisErrorMessage,
    required this.executedPhases,
    required this.phase3Result,
    required this.phase4Result,
    required this.phase5Result,
    required this.phase6Result,
  });

  final DocumentSyncAnalysisResult? analysis;
  final String? analysisErrorMessage;
  final List<DocumentSyncExecutionPhase> executedPhases;
  final DocumentSyncExecutionResult? phase3Result;
  final DocumentSyncExecutionResult? phase4Result;
  final DocumentSyncExecutionResult? phase5Result;
  final DocumentSyncExecutionResult? phase6Result;

  bool get hasAnalysisError => analysisErrorMessage != null;

  bool get hasFailures =>
      hasAnalysisError ||
      (phase3Result?.hasFailures ?? false) ||
      (phase4Result?.hasFailures ?? false) ||
      (phase5Result?.hasFailures ?? false) ||
      (phase6Result?.hasFailures ?? false);

  bool get hasSuccessfulActions =>
      completedUploadDocumentIds.isNotEmpty ||
      completedDownloadDocumentIds.isNotEmpty ||
      completedLocalFileRecoveryDocumentIds.isNotEmpty ||
      completedLocalSoftDeleteDocumentIds.isNotEmpty ||
      completedRemoteSoftDeleteDocumentIds.isNotEmpty ||
      completedHardDeleteDocumentIds.isNotEmpty;

  List<String> get completedUploadDocumentIds =>
      phase3Result?.completedUploadDocumentIds ?? const <String>[];

  List<String> get completedDownloadDocumentIds =>
      phase3Result?.completedDownloadDocumentIds ?? const <String>[];

  List<String> get completedLocalFileRecoveryDocumentIds =>
      phase4Result?.completedLocalFileRecoveryDocumentIds ?? const <String>[];

  List<String> get completedLocalSoftDeleteDocumentIds =>
      phase5Result?.completedLocalSoftDeleteDocumentIds ?? const <String>[];

  List<String> get completedRemoteSoftDeleteDocumentIds =>
      phase5Result?.completedRemoteSoftDeleteDocumentIds ?? const <String>[];

  List<String> get completedHardDeleteDocumentIds =>
      phase6Result?.completedHardDeleteDocumentIds ?? const <String>[];

  List<DocumentSyncExecutionFailure> get failures =>
      List<DocumentSyncExecutionFailure>.unmodifiable(
        <DocumentSyncExecutionFailure>[
          ...(phase3Result?.failures ?? const <DocumentSyncExecutionFailure>[]),
          ...(phase4Result?.failures ?? const <DocumentSyncExecutionFailure>[]),
          ...(phase5Result?.failures ?? const <DocumentSyncExecutionFailure>[]),
          ...(phase6Result?.failures ?? const <DocumentSyncExecutionFailure>[]),
        ],
      );
}
