import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../store/cruise_store.dart';
import '../../sync/app_sync_service.dart';
import '../../sync/app_sync_progress.dart';

class SyncProgressScreen extends StatefulWidget {
  const SyncProgressScreen({
    required this.store,
    super.key,
  });

  final CruiseStore store;

  static const List<AppSyncProgressStage> _visibleStages =
      <AppSyncProgressStage>[
    AppSyncProgressStage.preparing,
    AppSyncProgressStage.cruiseDataSync,
    AppSyncProgressStage.documentMetadataAnalysis,
    AppSyncProgressStage.documentUploads,
    AppSyncProgressStage.documentDownloads,
    AppSyncProgressStage.localDocumentRecovery,
    AppSyncProgressStage.deletionPropagation,
    AppSyncProgressStage.cleanup,
  ];

  @override
  State<SyncProgressScreen> createState() => _SyncProgressScreenState();
}

class _SyncProgressScreenState extends State<SyncProgressScreen> {
  AppSyncResult? _syncResult;
  AppSyncProgress? _progressOverride;

  @override
  void initState() {
    super.initState();
    unawaited(_startSync());
  }

  Future<void> _startSync() async {
    try {
      final result = await widget.store.runAppSync();
      if (!mounted) {
        return;
      }
      setState(() {
        _syncResult = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _syncResult = AppSyncResult.failed(
          failureMessage: error.toString(),
        );
        _progressOverride = _failedProgressForUnexpectedError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.syncProgressTitle),
      ),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final progress = _effectiveProgress();
          final isActive = _syncResult == null;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusTitle(loc, progress),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _statusDescription(loc, progress),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (isActive) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 20),
                ] else
                  const SizedBox(height: 4),
                Expanded(
                  child: ListView.separated(
                    itemCount: SyncProgressScreen._visibleStages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final stage = SyncProgressScreen._visibleStages[index];
                      final stageVisualState = _stageVisualState(
                        stage,
                        progress,
                      );
                      return _StageTile(
                        label: _stageLabel(loc, stage),
                        countLabel: _stageCountLabel(loc, stage, progress),
                        visualState: stageVisualState,
                      );
                    },
                  ),
                ),
                if (!isActive) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(loc.syncProgressClose),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusTitle(
    AppLocalizations loc,
    AppSyncProgress? progress,
  ) {
    if (progress == null || !progress.isTerminal) {
      return loc.syncProgressRunning;
    }

    return switch (progress.stage) {
      AppSyncProgressStage.completed => loc.syncProgressCompleted,
      AppSyncProgressStage.skipped => loc.syncProgressSkipped,
      AppSyncProgressStage.failed => loc.syncProgressFailed,
      _ => loc.syncProgressRunning,
    };
  }

  String _statusDescription(
    AppLocalizations loc,
    AppSyncProgress? progress,
  ) {
    if (_syncResult?.failureMessage case final failureMessage?) {
      return failureMessage;
    }

    if (progress == null || !progress.isTerminal) {
      return loc.syncProgressRunningDescription;
    }

    return switch (progress.stage) {
      AppSyncProgressStage.completed => loc.syncProgressCompletedDescription,
      AppSyncProgressStage.skipped => loc.syncProgressSkippedDescription,
      AppSyncProgressStage.failed => loc.syncProgressFailedDescription,
      _ => loc.syncProgressRunningDescription,
    };
  }

  _StageVisualState _stageVisualState(
    AppSyncProgressStage stage,
    AppSyncProgress? progress,
  ) {
    if (progress == null) {
      return _StageVisualState.pending;
    }

    final currentStage = progress.displayStage;
    final stageIndex = SyncProgressScreen._visibleStages.indexOf(stage);
    final currentIndex = SyncProgressScreen._visibleStages.indexOf(currentStage);

    if (progress.stage == AppSyncProgressStage.failed &&
        progress.failedStage == stage) {
      return _StageVisualState.failed;
    }

    if (stageIndex < currentIndex) {
      return _StageVisualState.completed;
    }

    if (stageIndex > currentIndex) {
      return _StageVisualState.pending;
    }

    if (!progress.isTerminal) {
      return _StageVisualState.active;
    }

    return _StageVisualState.completed;
  }

  String? _stageCountLabel(
    AppLocalizations loc,
    AppSyncProgressStage stage,
    AppSyncProgress? progress,
  ) {
    if (progress == null || progress.displayStage != stage) {
      return null;
    }

    final totalItems = progress.totalItems;
    if (totalItems == null) {
      return null;
    }

    return loc.syncProgressItemCount(totalItems);
  }

  String _stageLabel(AppLocalizations loc, AppSyncProgressStage stage) {
    return switch (stage) {
      AppSyncProgressStage.preparing => loc.syncProgressPreparing,
      AppSyncProgressStage.cruiseDataSync => loc.syncProgressCruiseDataSync,
      AppSyncProgressStage.documentMetadataAnalysis =>
        loc.syncProgressDocumentMetadataAnalysis,
      AppSyncProgressStage.documentUploads => loc.syncProgressDocumentUploads,
      AppSyncProgressStage.documentDownloads =>
        loc.syncProgressDocumentDownloads,
      AppSyncProgressStage.localDocumentRecovery =>
        loc.syncProgressLocalDocumentRecovery,
      AppSyncProgressStage.deletionPropagation =>
        loc.syncProgressDeletionPropagation,
      AppSyncProgressStage.cleanup => loc.syncProgressCleanup,
      _ => '',
    };
  }
}

enum _StageVisualState {
  pending,
  active,
  completed,
  failed,
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.label,
    required this.visualState,
    this.countLabel,
  });

  final String label;
  final String? countLabel;
  final _StageVisualState visualState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final icon = switch (visualState) {
      _StageVisualState.completed => Icon(
        Icons.check_circle,
        color: colorScheme.primary,
      ),
      _StageVisualState.active => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colorScheme.primary,
        ),
      ),
      _StageVisualState.failed => Icon(
        Icons.error_outline,
        color: colorScheme.error,
      ),
      _StageVisualState.pending => Icon(
        Icons.radio_button_unchecked,
        color: colorScheme.outline,
      ),
    };

    final textColor = switch (visualState) {
      _StageVisualState.pending => theme.textTheme.bodyLarge?.color
          ?.withValues(alpha: 0.7),
      _StageVisualState.failed => colorScheme.error,
      _ => theme.textTheme.bodyLarge?.color,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Center(child: icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: visualState == _StageVisualState.active
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (countLabel != null)
                    TextSpan(
                      text: '  $countLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension on _SyncProgressScreenState {
  AppSyncProgress? _effectiveProgress() {
    final progressOverride = _progressOverride;
    if (progressOverride != null) {
      return progressOverride;
    }

    final storeProgress = widget.store.appSyncProgress;
    if (_syncResult == null && storeProgress != null && storeProgress.isTerminal) {
      return AppSyncProgress(
        stage: storeProgress.displayStage,
        totalItems: storeProgress.totalItems,
      );
    }

    return storeProgress;
  }

  AppSyncProgress _failedProgressForUnexpectedError() {
    final storeProgress = widget.store.appSyncProgress;
    final lastActiveStage = storeProgress?.displayStage ??
        AppSyncProgressStage.preparing;
    return AppSyncProgress.failed(
      lastActiveStage: lastActiveStage,
    );
  }
}
