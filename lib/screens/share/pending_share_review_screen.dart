import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/share/share_intake_payload.dart';
import '../../services/share/pending_share_assignment_service.dart';
import '../../services/share/share_intake_service.dart';
import '../../utils/format.dart';
import 'pending_share_assignment_screen.dart';

class PendingShareReviewScreen extends StatelessWidget {
  const PendingShareReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ShareIntakeService();
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.shareReviewTitle),
        actions: [
          AnimatedBuilder(
            animation: service,
            builder: (context, _) {
              if (!service.hasPendingBatches) {
                return const SizedBox.shrink();
              }

              return TextButton(
                onPressed: service.clearAllPending,
                child: Text(loc.sharePendingClearAllAction),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final batches = service.pendingBatches.reversed.toList(growable: false);
          if (batches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  loc.shareReviewEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: batches.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final batch = batches[index];
              return _PendingShareBatchCard(
                batch: batch,
                onClear: () => service.clearPendingBatch(batch.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _PendingShareBatchCard extends StatelessWidget {
  const _PendingShareBatchCard({
    required this.batch,
    required this.onClear,
  });

  final ShareIntakeBatch batch;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final receivedAt = fmtDate(context, batch.receivedAt.toLocal(), includeTime: true);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.shareReviewBatchTitle(batch.items.length),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.shareReviewReceivedAt(receivedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: Text(loc.shareReviewClearBatchAction),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final entry in batch.items.indexed) ...[
              _PendingShareItemTile(
                batchId: batch.id,
                itemIndex: entry.$1,
                item: entry.$2,
              ),
              if (entry.$1 != batch.items.length - 1)
                const Divider(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingShareItemTile extends StatelessWidget {
  const _PendingShareItemTile({
    required this.batchId,
    required this.itemIndex,
    required this.item,
  });

  final String batchId;
  final int itemIndex;
  final ShareIntakeItem item;

  static final PendingShareAssignmentService _assignmentService =
      PendingShareAssignmentService();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final title = _itemTitle(item);
    final subtitle = _itemSubtitle(item);
    final canAssign = _assignmentService.canAssignItem(
      batchId: batchId,
      itemIndex: itemIndex,
      item: item,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconForItem(item), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: canAssign ? () => _openAssignment(context) : null,
            icon: Icon(
              canAssign ? Icons.link_outlined : Icons.block_outlined,
              size: 18,
            ),
            label: Text(
              canAssign
                  ? loc.shareAssignAction
                  : loc.shareAssignUnsupportedShort,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAssignment(BuildContext context) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PendingShareAssignmentScreen(
          batchId: batchId,
          itemIndex: itemIndex,
        ),
      ),
    );
    if (message == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

IconData _iconForItem(ShareIntakeItem item) {
  switch (item.kind) {
    case ShareIntakeItemKind.image:
      return Icons.image_outlined;
    case ShareIntakeItemKind.url:
      return Icons.link_outlined;
    case ShareIntakeItemKind.text:
      return Icons.notes_outlined;
    case ShareIntakeItemKind.file:
      return Icons.insert_drive_file_outlined;
  }
}

String _itemTitle(ShareIntakeItem item) {
  final candidate = switch (item.kind) {
    ShareIntakeItemKind.file || ShareIntakeItemKind.image =>
      item.fileName?.trim(),
    ShareIntakeItemKind.text || ShareIntakeItemKind.url => item.value.trim(),
  };

  if (candidate != null && candidate.isNotEmpty) {
    return candidate;
  }

  return item.value.trim();
}

String? _itemSubtitle(ShareIntakeItem item) {
  final details = <String>[];
  final rawValue = item.value.trim();
  final fileName = item.fileName?.trim();
  final message = item.message?.trim();
  final mimeType = item.mimeType?.trim();

  if (fileName != null && fileName.isNotEmpty && fileName != rawValue) {
    details.add(rawValue);
  }
  if (message != null && message.isNotEmpty) {
    details.add(message);
  }
  if (mimeType != null && mimeType.isNotEmpty) {
    details.add(mimeType);
  }

  if (details.isEmpty) {
    return null;
  }

  return details.join(' | ');
}

