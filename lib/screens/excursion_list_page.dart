import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cruise.dart';
import '../models/excursion.dart';
import '../store/cruise_store.dart';
import 'excursion_edit_page.dart';

class ExcursionListPage extends StatefulWidget {
  final Cruise cruise;
  final CruiseStore store;
  const ExcursionListPage({super.key, required this.cruise, required this.store});

  @override
  State<ExcursionListPage> createState() => _ExcursionListPageState();
}

class _ExcursionListPageState extends State<ExcursionListPage> {
  Future<void> _add() async {
    final e = await Navigator.push<Excursion>(context,
      MaterialPageRoute(builder: (_) => ExcursionEditPage(initial: null)),
    );
    if (e != null) await widget.store.upsertExcursion(cruiseId: widget.cruise.id, excursion: e);
  }

  Future<void> _edit(Excursion x) async {
    final e = await Navigator.push<Excursion>(context,
      MaterialPageRoute(builder: (_) => ExcursionEditPage(initial: x)),
    );
    if (e != null) await widget.store.upsertExcursion(cruiseId: widget.cruise.id, excursion: e);
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.cruise.excursions]..sort((a,b)=>a.date.compareTo(b.date));
    final df = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text('Excursions')),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: items.isEmpty
        ? const Center(child: Text('No excursions yet'))
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final x = items[i];
              return Dismissible(
                key: ValueKey(x.id),
                direction: DismissDirection.endToStart,
                background: Container(color: Colors.red, alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white)),
                confirmDismiss: (_) async => await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Delete excursion?'),
                    content: Text('Really delete “${x.title}”?'),
                    actions: [
                      TextButton(onPressed: ()=>Navigator.pop(d,false), child: const Text('Cancel')),
                      FilledButton.tonal(onPressed: ()=>Navigator.pop(d,true), child: const Text('Delete')),
                    ],
                  ),
                ) ?? false,
                onDismissed: (_) => widget.store.deleteExcursion(x.id),
                child: Card(child: ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(x.title),
                  subtitle: Text(df.format(x.date) + (x.port!=null ? ' • ${x.port}' : '')),
                  onTap: () => _edit(x),
                )),
              );
            },
          ),
    );
  }
}
