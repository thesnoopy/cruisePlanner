// RouteListScreen – list & edit route items with rich subtitles.
import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/cruise.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../models/identifiable.dart';
import '../../utils/format.dart';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.directions_boat),
              title: const Text('Hafen'),
              onTap: () => Navigator.pop(c, 'port'),
            ),
            ListTile(
              leading: const Icon(Icons.waves),
              title: const Text('Seetag'),
              onTap: () => Navigator.pop(c, 'sea'),
            ),
          ],
        ),
      ),
    );
    if (type == null) return;

    final s = CruiseStore();
    await s.load();
    final cruise = s.getCruise(widget.cruiseId);
    if (cruise == null) return;

    final id = Identifiable.newId();
    final date = cruise.period.start;

    if (type == 'port') {
      final item = PortCallItem(
        id: id,
        date: date,
        portName: '',
        arrival: null,
        departure: null,
        allAboard: null,
        notes: null,
      );
      await s.upsertRouteItem(cruiseId: cruise.id, item: item);
    } else {
      final item = SeaDayItem(
        id: id,
        date: date,
        notes: null,
      );
      await s.upsertRouteItem(cruiseId: cruise.id, item: item);
    }

    await _load();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RouteEditScreen(routeItemId: id, cruiseId: widget.cruiseId),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cruise = _cruise;
    return Scaffold(
      appBar: AppBar(title: const Text('Route')),
      body: cruise == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: cruise.route.length,
              itemBuilder: (context, idx) {
                final r = cruise.route[idx];
                if (r is PortCallItem) {
                  return ListTile(
                    leading: const Icon(Icons.directions_boat),
                    title: Text(
                      r.portName.isEmpty ? 'Unbenannter Hafen' : r.portName,
                    ),
                    subtitle: _buildPortSubtitle(context, r),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RouteEditScreen(
                            routeItemId: r.id,
                            cruiseId: widget.cruiseId,
                          ),
                        ),
                      );
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
                    subtitle: _buildSeaDaySubtitle(context, r),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RouteEditScreen(
                            routeItemId: r.id,
                            cruiseId: widget.cruiseId,
                          ),
                        ),
                      );
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPortSubtitle(BuildContext context, PortCallItem r) {
    final dateStr = fmtDate(context, r.date);
    final arrival = fmtDate(context, r.arrival, timeOnly: true);
    final departure = fmtDate(context, r.departure, timeOnly: true);
    final allAboard = fmtDate(context, r.allAboard, timeOnly: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event, size: 14),
            const SizedBox(width: 4),
            Text(dateStr),
          ],
        ),
        const SizedBox(height: 2),
        if (arrival.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.login, size: 14),
              const SizedBox(width: 4),
              Text('Ankunft $arrival'),
            ],
          ),
        if (arrival.isNotEmpty) const SizedBox(height: 2),
        if (departure.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.logout, size: 14),
              const SizedBox(width: 4),
              Text('Abfahrt $departure'),
            ],
          ),
        if (departure.isNotEmpty) const SizedBox(height: 2),
        if (allAboard.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.schedule, size: 14),
              const SizedBox(width: 4),
              Text('Alle an Bord $allAboard'),
            ],
          ),
      ],
    );
  }

  Widget _buildSeaDaySubtitle(BuildContext context, SeaDayItem r) {
    final dateStr = fmtDate(context, r.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event, size: 14),
            const SizedBox(width: 4),
            Text(dateStr),
          ],
        ),
        if (r.notes != null && r.notes!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.notes, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  r.notes!,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
