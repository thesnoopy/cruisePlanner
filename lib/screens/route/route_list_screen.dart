// RouteListScreen – passes cruiseId to editor; shows times including 'Alle an Bord'.
import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/cruise.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../models/identifiable.dart';
import 'route_edit_screen.dart';

class RouteListScreen extends StatefulWidget {
  final String cruiseId;
  const RouteListScreen({super.key, required this.cruiseId});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  Cruise? _cruise;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = CruiseStore();
    await s.load();
    setState(() => _cruise = s.getCruise(widget.cruiseId));
  }

  Future<void> _showCreateMenu() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.directions_boat), title: const Text('Hafen'), onTap: () => Navigator.pop(c, 'port')),
          ListTile(leading: const Icon(Icons.waves), title: const Text('Seetag'), onTap: () => Navigator.pop(c, 'sea')),
        ]),
      ),
    );
    if (type == null) return;
    final id = Identifiable.newId();
    final s = CruiseStore();
    await s.load();
    final cruise = s.getCruise(widget.cruiseId);
    if (cruise == null) return;
    final date = cruise.period.start;
    if (type == 'port') {
      final item = PortCallItem(id: id, date: date, portName: '', arrival: null, departure: null, allAboard: null, notes: null);
      await s.upsertRouteItem(cruiseId: cruise.id, item: item);
    } else {
      final item = SeaDayItem(id: id, date: date, notes: null);
      await s.upsertRouteItem(cruiseId: cruise.id, item: item);
    }
    await _load();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RouteEditScreen(routeItemId: id, cruiseId: widget.cruiseId)));
    await _load();
  }

  String _fmtDate(DateTime d) => '${_pad(d.day)}.${_pad(d.month)}.${d.year}';
  String _fmtTime(DateTime? d) => d == null ? '' : '${_pad(d.hour)}:${_pad(d.minute)}';
  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final c = _cruise;
    return Scaffold(
      appBar: AppBar(title: const Text('Route')),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: c.route.length,
              itemBuilder: (context, idx) {
                final r = c.route[idx];
                if (r is PortCallItem) {
                  final line2 = [
                    if (r.arrival != null) 'Ank. ${_fmtTime(r.arrival)}',
                    if (r.departure != null) 'Abf. ${_fmtTime(r.departure)}',
                    if (r.allAboard != null) 'Alle an Bord ${_fmtTime(r.allAboard)}',
                  ].join('   ');
                  return ListTile(
                    leading: const Icon(Icons.directions_boat),
                    title: Text(r.portName.isEmpty ? 'Unbenannter Hafen' : r.portName),
                    subtitle: Text([_fmtDate(r.date), if (line2.isNotEmpty) line2].join(' • ')),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RouteEditScreen(routeItemId: r.id, cruiseId: widget.cruiseId)));
                      await _load();
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final s = CruiseStore();
                        await s.load();
                        await s.deleteRouteItem(r.id);
                        await _load();
                      },
                    ),
                  );
                } else if (r is SeaDayItem) {
                  return ListTile(
                    leading: const Icon(Icons.waves),
                    title: const Text('Seetag'),
                    subtitle: Text(_fmtDate(r.date)),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RouteEditScreen(routeItemId: r.id, cruiseId: widget.cruiseId)));
                      await _load();
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final s = CruiseStore();
                        await s.load();
                        await s.deleteRouteItem(r.id);
                        await _load();
                      },
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateMenu, child: const Icon(Icons.add)),
    );
  }
}
