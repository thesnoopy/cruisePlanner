import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cruise.dart';
import '../models/travel/base_travel.dart';
import '../store/cruise_store.dart';
import 'travel_edit_page.dart';

class TravelListPage extends StatefulWidget {
  final Cruise cruise;
  final CruiseStore store;
  const TravelListPage({super.key, required this.cruise, required this.store});

  @override
  State<TravelListPage> createState() => _TravelListPageState();
}

class _TravelListPageState extends State<TravelListPage> {
  Future<void> _add() async {
    final t = await Navigator.push<TravelItem>(context,
      MaterialPageRoute(builder: (_) => TravelEditPage(initial: null)),
    );
    if (t != null) await widget.store.upsertTravelItem(cruiseId: widget.cruise.id, item: t);
  }

  Future<void> _edit(TravelItem t) async {
    final edited = await Navigator.push<TravelItem>(context,
      MaterialPageRoute(builder: (_) => TravelEditPage(initial: t)),
    );
    if (edited != null) await widget.store.upsertTravelItem(cruiseId: widget.cruise.id, item: edited);
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.cruise.travel]..sort((a,b)=>a.start.compareTo(b.start));
    final df = DateFormat.yMMMMd().add_Hm();
    return Scaffold(
      appBar: AppBar(title: const Text('Travel')),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: items.isEmpty
        ? const Center(child: Text('No travel items yet'))
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final t = items[i];
              final title = t.from ?? t.to ?? t.id;
              final subtitle = t.end != null ? '${df.format(t.start)} – ${df.format(t.end!)}' : df.format(t.start);
              return Dismissible(
                key: ValueKey(t.id),
                direction: DismissDirection.endToStart,
                background: Container(color: Colors.red, alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white)),
                confirmDismiss: (_) async => await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Delete travel item?'),
                    content: Text('Really delete “$title”?'),
                    actions: [
                      TextButton(onPressed: ()=>Navigator.pop(d,false), child: const Text('Cancel')),
                      FilledButton.tonal(onPressed: ()=>Navigator.pop(d,true), child: const Text('Delete')),
                    ],
                  ),
                ) ?? false,
                onDismissed: (_) => widget.store.deleteTravelItem(t.id),
                child: Card(child: ListTile(
                  leading: Icon(_iconFor(t.kind)),
                  title: Text(title),
                  subtitle: Text(subtitle),
                  onTap: () => _edit(t),
                )),
              );
            },
          ),
    );
  }

  IconData _iconFor(TravelKind k) {
    switch (k) {
      case TravelKind.flight: return Icons.flight;
      case TravelKind.train: return Icons.train;
      case TravelKind.transfer: return Icons.signpost;
      case TravelKind.rentalCar: return Icons.directions_car;
    }
  }
}
