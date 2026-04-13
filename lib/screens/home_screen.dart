import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/cruise.dart';
import '../models/identifiable.dart';
import '../models/period.dart';
import '../models/share/share_intake_payload.dart';
import '../models/ship.dart';
import '../services/share/share_intake_service.dart';
import '../store/cruise_store.dart';
import '../widgets/confirmation_dialog.dart';
import 'cruise_hub_screen.dart';
import 'share/pending_share_review_screen.dart';
import 'settings/webdav_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ShareIntakeService _shareIntakeService = ShareIntakeService();
  CruiseStore? _store;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAutoSyncOnAppOpen();
    });
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerAutoSyncOnAppOpen();
    }
  }

  Future<void> _triggerAutoSyncOnAppOpen() async {
    final s = CruiseStore();
    await s.load();
    await s.triggerAutoSyncOnAppOpen();
  }

  Future<void> _reload() async {
    final s = CruiseStore();
    await s.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _store = s;
      _loading = false;
    });
  }

  Future<void> _runCloudSync() async {
    final store = _store;

    if (store == null) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.homeCloudSyncNoStore)),
        );
      }
      return;
    }

    final result = await store.runAppSync();
    if (!mounted) {
      return;
    }

    final loc = AppLocalizations.of(context)!;
    if (result.wasSkipped) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.homeCloudSyncNoWebdav)),
      );
      return;
    }

    setState(() {
      _store = store;
    });

    if (result.hasFailures) {
      final errorMessage =
          result.failureMessage ?? 'App sync failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.homeCloudSyncFailed(errorMessage))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.homeCloudSyncDone)),
    );
  }

  int _columnsForWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = (w / 300).floor();
    return cols.clamp(1, 6);
  }

  Future<void> _createCruise() async {
    final loc = AppLocalizations.of(context)!;
    final id = Identifiable.newId();
    final now = DateTime.now();
    final cruise = Cruise(
      id: id,
      title: loc.homeNewCruiseLabel,
      ship: Ship(name: loc.ship),
      period: Period(start: now, end: now.add(const Duration(days: 7))),
      excursions: const [],
      travel: const [],
      route: const [],
    );
    final s = CruiseStore();
    await s.load();
    await s.upsertCruise(cruise);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CruiseHubScreen(cruiseId: id),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cruises = _store?.cruises ?? const <Cruise>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        actions: [
          IconButton(
            tooltip: loc.homeWebdavSettingsTooltip,
            icon: const Icon(Icons.cloud_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WebDavSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: loc.homeCloudSyncTooltip,
            icon: const Icon(Icons.sync),
            onPressed: _runCloudSync,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _shareIntakeService,
        builder: (context, _) {
          final hasPendingShares = _shareIntakeService.hasPendingBatches;

          return Column(
            children: [
              if (hasPendingShares)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: _PendingShareSummaryCard(
                    service: _shareIntakeService,
                    onReview: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PendingShareReviewScreen(),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: cruises.isEmpty
                    ? Center(child: Text(loc.homeNoCruises))
                    : MasonryGridView.count(
                        key: const PageStorageKey('home_masonry'),
                        padding: const EdgeInsets.all(12),
                        crossAxisCount: _columnsForWidth(context),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: cruises.length,
                        itemBuilder: (context, index) {
                          final c = cruises[index];
                          return _CruiseTile(
                            cruise: c,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CruiseHubScreen(cruiseId: c.id),
                                ),
                              );
                              await _reload();
                            },
                            onDelete: () async {
                              final confirmed = await showConfirmationDialog(
                                context: context,
                                title: loc.deleteCruiseTitle,
                                message: loc.deleteCruiseQuestionmark,
                                okText: loc.delete,
                                cancelText: loc.confirmCancel,
                                icon: Icons.warning_amber_rounded,
                                destructive: true,
                              );

                              if (!confirmed) {
                                return;
                              }
                              final s = CruiseStore();
                              await s.load();
                              await s.deleteCruise(c.id);
                              await _reload();
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCruise,
        label: Text(loc.homeNewCruiseLabel),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _PendingShareSummaryCard extends StatelessWidget {
  const _PendingShareSummaryCard({
    required this.service,
    required this.onReview,
  });

  final ShareIntakeService service;
  final Future<void> Function() onReview;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final latestBatch = service.latestPendingBatch;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.share_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.sharePendingTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              loc.sharePendingSummary(
                service.pendingBatches.length,
                service.pendingItemCount,
              ),
            ),
            if (latestBatch != null) ...[
              const SizedBox(height: 8),
              Text(loc.sharePendingLatest(_describeBatch(context, latestBatch))),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(loc.sharePendingReviewAction),
                ),
                TextButton(
                  onPressed: service.clearAllPending,
                  child: Text(loc.sharePendingClearAllAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CruiseTile extends StatelessWidget {
  const _CruiseTile({
    required this.cruise,
    required this.onTap,
    required this.onDelete,
  });

  final Cruise cruise;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final start = fmtDate(context, cruise.period.start);
    final end = fmtDate(context, cruise.period.end);
    final loc = AppLocalizations.of(context)!;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cruise.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              if ((cruise.ship.operatorName ?? '').isNotEmpty)
                Text(
                  '${cruise.ship.operatorName} \u2014 ${cruise.ship.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Text(
                  cruise.ship.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text('$start \u2013 $end')),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    tooltip: loc.homeDeleteTooltip,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _describeBatch(BuildContext context, ShareIntakeBatch batch) {
  final firstItem = batch.items.first;
  final primaryLabel = _describeItem(firstItem);
  final additionalCount = batch.items.length - 1;

  if (additionalCount <= 0) {
    return primaryLabel;
  }

  final loc = AppLocalizations.of(context)!;
  return loc.sharePendingAdditionalItems(primaryLabel, additionalCount);
}

String _describeItem(ShareIntakeItem item) {
  final preferredLabel = switch (item.kind) {
    ShareIntakeItemKind.file || ShareIntakeItemKind.image =>
      item.fileName?.trim(),
    ShareIntakeItemKind.text || ShareIntakeItemKind.url => item.value.trim(),
  };

  if (preferredLabel != null && preferredLabel.isNotEmpty) {
    return preferredLabel;
  }

  return item.value.trim();
}
