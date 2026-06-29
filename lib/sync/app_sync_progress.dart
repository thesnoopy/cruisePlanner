enum AppSyncProgressStage {
  preparing,
  cruiseDataSync,
  documentMetadataAnalysis,
  documentUploads,
  documentDownloads,
  localDocumentRecovery,
  deletionPropagation,
  cleanup,
  completed,
  skipped,
  failed,
}

typedef AppSyncProgressCallback = void Function(AppSyncProgress progress);

class AppSyncProgress {
  const AppSyncProgress({
    required this.stage,
    this.lastActiveStage,
    this.failedStage,
    this.totalItems,
  });

  final AppSyncProgressStage stage;
  final AppSyncProgressStage? lastActiveStage;
  final AppSyncProgressStage? failedStage;
  final int? totalItems;

  bool get isTerminal =>
      stage == AppSyncProgressStage.completed ||
      stage == AppSyncProgressStage.skipped ||
      stage == AppSyncProgressStage.failed;

  AppSyncProgressStage get displayStage =>
      isTerminal ? (lastActiveStage ?? AppSyncProgressStage.preparing) : stage;

  factory AppSyncProgress.preparing() =>
      const AppSyncProgress(stage: AppSyncProgressStage.preparing);

  factory AppSyncProgress.cruiseDataSync() =>
      const AppSyncProgress(stage: AppSyncProgressStage.cruiseDataSync);

  factory AppSyncProgress.documentMetadataAnalysis() => const AppSyncProgress(
        stage: AppSyncProgressStage.documentMetadataAnalysis,
      );

  factory AppSyncProgress.documentUploads({
    int? totalItems,
  }) =>
      AppSyncProgress(
        stage: AppSyncProgressStage.documentUploads,
        totalItems: totalItems,
      );

  factory AppSyncProgress.documentDownloads({
    int? totalItems,
  }) =>
      AppSyncProgress(
        stage: AppSyncProgressStage.documentDownloads,
        totalItems: totalItems,
      );

  factory AppSyncProgress.localDocumentRecovery({
    int? totalItems,
  }) =>
      AppSyncProgress(
        stage: AppSyncProgressStage.localDocumentRecovery,
        totalItems: totalItems,
      );

  factory AppSyncProgress.deletionPropagation({
    int? totalItems,
  }) =>
      AppSyncProgress(
        stage: AppSyncProgressStage.deletionPropagation,
        totalItems: totalItems,
      );

  factory AppSyncProgress.cleanup({
    int? totalItems,
  }) =>
      AppSyncProgress(
        stage: AppSyncProgressStage.cleanup,
        totalItems: totalItems,
      );

  factory AppSyncProgress.completed({
    required AppSyncProgressStage lastActiveStage,
  }) =>
      AppSyncProgress(
        stage: AppSyncProgressStage.completed,
        lastActiveStage: lastActiveStage,
      );

  factory AppSyncProgress.skipped({
    AppSyncProgressStage lastActiveStage = AppSyncProgressStage.preparing,
  }) =>
      AppSyncProgress(
        stage: AppSyncProgressStage.skipped,
        lastActiveStage: lastActiveStage,
      );

  factory AppSyncProgress.failed({
    required AppSyncProgressStage lastActiveStage,
    AppSyncProgressStage? failedStage,
  }) =>
      AppSyncProgress(
        stage: AppSyncProgressStage.failed,
        lastActiveStage: lastActiveStage,
        failedStage: failedStage,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppSyncProgress &&
        other.stage == stage &&
        other.lastActiveStage == lastActiveStage &&
        other.failedStage == failedStage &&
        other.totalItems == totalItems;
  }

  @override
  int get hashCode => Object.hash(stage, lastActiveStage, failedStage, totalItems);
}
