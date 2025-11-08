import 'package:flutter/material.dart';
import '../store/cruise_store.dart';
import '../models/cruise.dart';
import '../models/ship.dart';
import '../models/period.dart';
import 'cruise_hub_page.dart';

class HomeScreen extends StatefulWidget {
  final CruiseStore store;
  const HomeScreen({super.key, required this.store});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.store.isLoaded) {
      widget.store.load();
    }
    widget.store.addListener(_onChange);
  }
  @override
  void dispose() {
    widget.store.removeListener(_onChange);
    super.dispose();
  }
  void _onChange() { if (mounted) setState(() {}); }

  Future<void> _addCruise() async {
    final now = DateTime.now();
    final c = Cruise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Cruise',
      ship: const Ship(name: 'Ship', operatorName: 'Line'),
      period: Period(start: now, end: now.add(const Duration(days: 7))),
      excursions: const [], travel: const [], route: const [],
    );
    await widget.store.upsertCruise(c);
  }

  Future<void> _openCruise(Cruise c) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => CruiseHubPage(cruise: c, store: widget.store),
    ));
    // after returning, reload from store snapshot (listener will refresh list)
  }

  @override
  Widget build(BuildContext context) {
    final cruises = widget.store.cruises;
    return Scaffold(
      appBar: AppBar(title: const Text('Cruises')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCruise, child: const Icon(Icons.add),
      ),
      body: cruises.isEmpty
        ? const Center(child: Text('No cruises yet'))
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: cruises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final c = cruises[i];
              return Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red, alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('Delete cruise?'),
                      content: Text('Really delete “${c.title}”?'),
                      actions: [
                        TextButton(onPressed: ()=>Navigator.pop(d,false), child: const Text('Cancel')),
                        FilledButton.tonal(onPressed: ()=>Navigator.pop(d,true), child: const Text('Delete')),
                      ],
                    ),
                  ) ?? false;
                },
                onDismissed: (_) => widget.store.deleteCruise(c.id),
                child: Card(
                  child: ListTile(
                    title: Text(c.title),
                    subtitle: Text('${c.ship.name} • ${c.ship.operatorName}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openCruise(c),
                  ),
                ),
              );
            },
          ),
    );
  }
}
