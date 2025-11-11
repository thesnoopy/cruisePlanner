// CruiseHubScreen – Route & Details tiles use icon-rich subtitle widgets.
// - Route tile: icon-only time badges for arrival/departure/all aboard
// - Details tile: ship row (icon + name) and date pills for start/end
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../store/cruise_store.dart';
import '../models/cruise.dart';
import '../models/route/route_item.dart';
import '../models/route/port_call_item.dart';
import 'details/cruise_details_screen.dart';
import 'route/route_list_screen.dart';
import 'excursions/excursion_list_screen.dart';
import 'travel/travel_list_screen.dart';

class CruiseHubScreen extends StatefulWidget {
  final String cruiseId;
  const CruiseHubScreen({super.key, required this.cruiseId});

  @override
  State<CruiseHubScreen> createState() => _CruiseHubScreenState();
}

class _CruiseHubScreenState extends State<CruiseHubScreen> {
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

  int _columnsForWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // min tile width ~ 300
    final cols = (w / 300).floor();
    return cols.clamp(1, 6);
  }

  @override
  Widget build(BuildContext context) {
    final c = _cruise;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?.title ?? 'Cruise'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: MasonryGridView.count(
                // gleiche Logik wie im HomeScreen (breiteabhängig)
                crossAxisCount: _columnsForWidth(context),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                itemCount: 4,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _DetailsTile(
                        cruise: c,
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CruiseDetailsScreen(cruiseId: c.id),
                          ));
                          await _load();
                        },
                      );
                    case 1:
                      final preview = _routePreview(c.route);
                      return _HubTile(
                        title: 'Route',
                        subtitleWidget: _buildRouteSubtitleWidget(preview, context),
                        icon: Icons.map_outlined,
                        color: Colors.blue,
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => RouteListScreen(cruiseId: c.id),
                          ));
                          await _load();
                        },
                      );
                    case 2:
                      return _HubTile(
                        title: 'Excursions',
                        subtitle: '${c.excursions.length}',
                        icon: Icons.directions_walk,
                        color: Colors.teal,
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ExcursionListScreen(cruiseId: c.id),
                          ));
                          await _load();
                        },
                      );
                    default:
                      return _HubTile(
                        title: 'Travel',
                        subtitle: '${c.travel.length}',
                        icon: Icons.flight_takeoff,
                        color: Colors.indigo,
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TravelListScreen(cruiseId: c.id),
                          ));
                          await _load();
                        },
                      );
                  }
                },
              ),
            ),
    );
  }
}

// ----- Tiles -----------------------------------------------------------------

class _HubTile extends StatelessWidget {
  final String title;
  final String? subtitle;          // klassischer Text-Subtitle
  final Widget? subtitleWidget;    // NEU: Rich-Subtitle (Icons etc.)
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HubTile({
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    if (subtitleWidget != null) ...[
                      subtitleWidget!,
                    ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----- Details Tile with icons ----------------------------------------------

class _DetailsTile extends StatelessWidget {
  final Cruise cruise;
  final VoidCallback onTap;
  const _DetailsTile({required this.cruise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = cruise.period;
    final start = p.start;
    final end = p.end;
    final ship = cruise.ship.name.isEmpty ? '—' : cruise.ship.name;

    return _HubTile(
      title: 'Details',
      subtitleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ship row (icon + name, minimal Text)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.directions_boat, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ship,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date pills (start / end) – icon + date
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _datePill(context: context, icon: Icons.event, date: start, tooltip: 'Start'),
              _datePill(context: context, icon: Icons.event_available, date: end, tooltip: 'Ende'),
            ],
          ),
        ],
      ),
      icon: Icons.info_outline,
      color: Colors.orange,
      onTap: onTap,
    );
  }
}

// ----- Route preview helpers -------------------------------------------------

class _RoutePreview {
  final PortCallItem? today;
  final PortCallItem? next;
  const _RoutePreview({this.today, this.next});
}

_RoutePreview _routePreview(List<RouteItem> items) {
  final ports = items.whereType<PortCallItem>().toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  PortCallItem? today;
  for (final p in ports) {
    if (!p.date.isBefore(todayStart) && p.date.isBefore(todayEnd)) {
      today = p;
      break;
    }
  }

  PortCallItem? next;
  for (final p in ports) {
    if (p.date.isAfter(todayEnd.subtract(const Duration(milliseconds: 1)))) {
      if (today != null && p.id == today.id) continue;
      next = p;
      break;
    }
  }

  return _RoutePreview(today: today, next: next);
}

// ----- Iconisierte Subtitle-Widgets (Route) ---------------------------------

Widget _buildRouteSubtitleWidget(_RoutePreview p, BuildContext context) {
  final rows = <Widget>[];

  Widget line({required IconData icon, required PortCallItem port}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (port.portName.isEmpty ? 'Unbenannter Hafen' : port.portName),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              _timeRow(
                context,
                arrival: port.arrival,
                departure: port.departure,
                allAboard: port.allAboard,
              ),
            ],
          ),
        ),
      ],
    );
  }

  if (p.today != null) {
    rows.add(line(icon: Icons.today, port: p.today!));
    rows.add(const SizedBox(height: 8));
  }
  if (p.next != null) {
    rows.add(line(icon: Icons.flag, port: p.next!));
  }

  if (rows.isEmpty) {
    return Text('Keine Häfen für heute oder zukünftig',
        style: Theme.of(context).textTheme.bodyMedium);
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
}

// ----- Helpers ---------------------------------------------------------------

String _fmtDate(DateTime d) => '${_pad(d.day)}.${_pad(d.month)}.${d.year}';
String _pad(int n) => n.toString().padLeft(2, '0');
String _hhmm(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';

// kleines Icon-Badge (ohne Text-Label) für eine Uhrzeit
Widget _timePill({
  required BuildContext context,
  required IconData icon,
  required DateTime time,
  String? tooltip,
}) {
  final pill = Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: Theme.of(context).colorScheme.surfaceVariant,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 6),
        Text(_hhmm(time), style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
  return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
}

// Date pill (icon + dd.MM.yyyy)
Widget _datePill({
  required BuildContext context,
  required IconData icon,
  required DateTime date,
  String? tooltip,
}) {
  String d(DateTime t) => '${_pad(t.day)}.${_pad(t.month)}.${t.year}';
  final pill = Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: Theme.of(context).colorScheme.surfaceVariant,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 6),
        Text(d(date), style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
  return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
}

// baut die Reihe aller vorhandenen Zeiten (Ankunft/Abfahrt/Alle an Bord)
Widget _timeRow(
  BuildContext context, {
  DateTime? arrival,
  DateTime? departure,
  DateTime? allAboard,
}) {
  final chips = <Widget>[];
  if (arrival != null) {
    chips.add(_timePill(
      context: context,
      icon: Icons.login, // Alternativen: Icons.south_west, Icons.call_received
      time: arrival,
      tooltip: 'Ankunft',
    ));
  }
  if (departure != null) {
    if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
    chips.add(_timePill(
      context: context,
      icon: Icons.logout, // Alternativen: Icons.north_east, Icons.call_made
      time: departure,
      tooltip: 'Abfahrt',
    ));
  }
  if (allAboard != null) {
    if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
    chips.add(_timePill(
      context: context,
      icon: Icons.warning_amber_outlined,
      time: allAboard,
      tooltip: 'Alle an Bord',
    ));
  }
  if (chips.isEmpty) return const SizedBox.shrink();
  return Wrap(spacing: 0, runSpacing: 8, children: chips);
}
