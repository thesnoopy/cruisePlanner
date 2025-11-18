// HomeScreen with Masonry grid (flutter_staggered_grid_view)
import 'package:cruiseplanner/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../store/cruise_store.dart';
import '../models/cruise.dart';
import '../models/period.dart';
import '../models/ship.dart';
import '../models/identifiable.dart';
import 'cruise_hub_screen.dart';
import 'settings/webdav_settings_screen.dart';
import '../settings/webdav_settings_store.dart';
import '../sync/webdav_sync.dart';
import '../sync/cruise_sync_service.dart';
import 'package:cruiseplanner/l10n/app_localizations.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CruiseStore? _store;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = CruiseStore();
    await s.load();
    if (!mounted) return;
    setState(() {
      _store = s;
      _loading = false;
    });
  }

  Future<void> _runCloudSync() async {
  // Hier den Namen verwenden, den du aktuell benutzt:
  // z.B. cruiseStore, _store, widget.store, ...
  final store = _store;

  if (store == null) {
    if (mounted) {
      final loc = AppLocalizations.of(context)!;            
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.homeCloudSyncNoStore),
        ),
      );
    }
    return;
  }

  final settingsStore = const WebDavSettingsStore();
  final settings = await settingsStore.load();

  if (settings == null || !settings.isValid) {
    if (mounted) {
      final loc = AppLocalizations.of(context)!;   
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.homeCloudSyncNoWebdav)),
      );
    }
    return;
  }

  try {
    final webDav = WebDavSync(settings);
    final syncService = CruiseSyncService(webDav);

    // jetzt ist store **non-null**
    final local = store.cruises;

    final merged = await syncService.sync(local);

    await store.replaceAll(merged);
    await store.load();
    setState(() {
      _store = store;
    });

    if (mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.homeCloudSyncDone)),
      );
    }
  } catch (e) {
    if (mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.homeCloudSyncFailed} $e')),
      );
    }
  }
}


  int _columnsForWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // min tile width ~ 300
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
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CruiseHubScreen(cruiseId: id),
    ));
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
            onPressed: _runCloudSync
          ),
        ],
      ),
      body: cruises.isEmpty
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
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CruiseHubScreen(cruiseId: c.id),
                    ));
                    await _reload();
                  },
                  onDelete: () async {
                    final s = CruiseStore();
                    await s.load();
                    await s.deleteCruise(c.id);
                    await _reload();
                  },
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

class _CruiseTile extends StatelessWidget {
  final Cruise cruise;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CruiseTile({
    required this.cruise,
    required this.onTap,
    required this.onDelete,
  });

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
            mainAxisSize: MainAxisSize.min, // grow with content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cruise.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              if ((cruise.ship.operatorName ?? '').isNotEmpty)
                Text(
                  '${cruise.ship.operatorName} — ${cruise.ship.name}',
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
                  Expanded(child: Text('$start – $end')),
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