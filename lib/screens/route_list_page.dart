import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cruise.dart';
import '../models/route/route_item.dart';
import '../models/route/port_call_item.dart';
import '../store/cruise_store.dart';
import 'route_edit_page.dart';

class RouteListPage extends StatefulWidget {
  final Cruise cruise;
  final CruiseStore store;
  const RouteListPage({super.key, required this.cruise, required this.store});

  @override
  State<RouteListPage> createState() => _RouteListPageState();
}

class _RouteListPageState extends State<RouteListPage> {
  Future<void> _add() async {
    final item = await Navigator.push<RouteItem>(context,
      MaterialPageRoute(builder: (_) => RouteEditPage(initial: null)),
    );
    if (item != null) await widget.store.upsertRouteItem(cruiseId: widget.cruise.id, item: item);
  }

  Future<void> _edit(RouteItem item) async {
    final edited = await Navigator.push<RouteItem>(context,
      MaterialPageRoute(builder: (_) => RouteEditPage(initial: item)),
    );
    if (edited != null) await widget.store.upsertRouteItem(cruiseId: widget.cruise.id, item: edited);
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.cruise.route]..sort((a,b)=>a.date.compareTo(b.date));
    final df = DateFormat.yMMMMd().add_Hm();
    return Scaffold(
      appBar: AppBar(title: const Text('Route')),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: items.isEmpty
        ? const Center(child: Text('No route items yet'))
        : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final r = items[i];
            final title = r is PortCallItem ? r.portName : 'Sea day';
            final when = r is PortCallItem
              ? '${df.format(r.arrival ?? r.date)} – ${r.departure != null ? df.format(r.departure!) : '—'}'
              : df.format(r.date);
            return Dismissible(
              key: ValueKey(r.id),
              direction: DismissDirection.endToStart,
              background: Container(color: Colors.red, alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(Icons.delete, color: Colors.white)),
              confirmDismiss: (_) async => await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Delete item?'),
                  content: Text('Really delete “$title”?'),
                  actions: [
                    TextButton(onPressed: ()=>Navigator.pop(d,false), child: const Text('Cancel')),
                    FilledButton.tonal(onPressed: ()=>Navigator.pop(d,true), child: const Text('Delete')),
                  ],
                ),
              ) ?? false,
              onDismissed: (_) => widget.store.deleteRouteItem(r.id),
              child: Card(child: ListTile(
                leading: Icon(r is PortCallItem ? Icons.anchor : Icons.waves),
                title: Text(title),
                subtitle: Text(when),
                onTap: () => _edit(r),
              )),
            );
          },
        ),
    );
  }
}
