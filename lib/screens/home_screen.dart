// HomeScreen with Masonry grid (flutter_staggered_grid_view)
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../store/cruise_store.dart';
import '../models/cruise.dart';
import '../models/period.dart';
import '../models/ship.dart';
import '../models/identifiable.dart';
import 'cruise_hub_screen.dart';

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

  int _columnsForWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // min tile width ~ 300
    final cols = (w / 300).floor();
    return cols.clamp(1, 6);
  }

  Future<void> _createCruise() async {
    final id = Identifiable.newId();
    final now = DateTime.now();
    final cruise = Cruise(
      id: id,
      title: 'Neue Cruise',
      ship: const Ship(name: 'Ship'),
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cruises = _store?.cruises ?? const <Cruise>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Cruise Planner')),
      body: cruises.isEmpty
          ? const Center(child: Text('Keine Cruises – lege eine neue an.'))
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
        label: const Text('Neue Cruise'),
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
    final start = cruise.period.start.toLocal().toIso8601String().split('T').first;
    final end = cruise.period.end.toLocal().toIso8601String().split('T').first;

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
                    tooltip: 'Löschen',
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