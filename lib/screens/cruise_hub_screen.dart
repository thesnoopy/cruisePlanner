// CruiseHubScreen – Route & Details tiles use icon-rich subtitle widgets.
// - Route tile: icon-only time badges for arrival/departure/all aboard
// - Details tile: ship row (icon + name) and date pills for start/end
import 'package:cruiseplanner/models/travel/hotel_item.dart';
import 'package:cruiseplanner/models/travel/cruise_check_in_item.dart';
import 'package:cruiseplanner/models/travel/cruise_check_out_item.dart';
import 'package:cruiseplanner/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../store/cruise_store.dart';
import '../models/cruise.dart';
import '../models/route/route_item.dart';
import '../models/route/port_call_item.dart';
import '../models/travel/base_travel.dart';
import '../models/travel/flight_item.dart';
import '../models/travel/train_item.dart';
import '../models/travel/transfer_item.dart';
import '../models/travel/rental_car_item.dart';
import '../models/excursion.dart';
import 'details/cruise_details_screen.dart';
import 'route/route_list_screen.dart';
import 'excursions/excursion_list_screen.dart';
import 'travel/travel_list_screen.dart';
import '../l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    final c = _cruise;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?.title ?? loc.cruise),
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
                        title: loc.route,
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
                        title: loc.excursion,
                        subtitleWidget: _buildExcursionPreview(context, c.excursions),
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
                        title: loc.travel,
                        subtitleWidget: _buildTravelPreview(context, c.travel),
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
    final loc = AppLocalizations.of(context)!;

    return _HubTile(
      title: loc.cruiseDetails,
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
  final loc = AppLocalizations.of(context)!;

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
                (port.portName.isEmpty ? loc.unknownHarbour : port.portName),
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
    return Text(loc.noHarbour,
        style: Theme.of(context).textTheme.bodyMedium);
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
}

// ----- Helpers ---------------------------------------------------------------

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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 6),
        Text(fmtDate(context, time, timeOnly: true), style: Theme.of(context).textTheme.labelMedium),
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
  //String d(DateTime t) => '${_pad(t.day)}.${_pad(t.month)}.${t.year}';
  String d = fmtDate(context, date);
  final pill = Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 6),
        Text(d, style: Theme.of(context).textTheme.labelMedium),
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
  final loc = AppLocalizations.of(context)!;

  if (arrival != null) {
    chips.add(_timePill(
      context: context,
      icon: Icons.login, // oder: Icons.south_west, Icons.call_received
      time: arrival,
      tooltip: loc.arrival,
    ));
  }
  if (departure != null) {
    if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
    chips.add(_timePill(
      context: context,
      icon: Icons.logout, // oder: Icons.north_east, Icons.call_made
      time: departure,
      tooltip: loc.departure,
    ));
  }
  if (allAboard != null) {
    if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
    chips.add(_timePill(
      context: context,
      icon: Icons.warning_amber_outlined,
      time: allAboard,
      tooltip: loc.allOnBoard,
    ));
  }

  if (chips.isEmpty) return const SizedBox.shrink();
  return Wrap(spacing: 0, runSpacing: 8, children: chips);
}



// ----- Excursions preview (today or next) -----------------------------------
Widget _buildExcursionPreview(BuildContext context, List<Excursion> list) {
  final loc = AppLocalizations.of(context)!;
  if (list.isEmpty) {
    return Text(loc.noFutureExcursions, style: Theme.of(context).textTheme.bodyMedium);
  }
  // normalize to local midnight
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // sort by date ascending
  final items = List<Excursion>.from(list)..sort((a, b) => a.date.compareTo(b.date));

  Excursion? findToday(List<Excursion> src, DateTime day) {
    for (final e in src) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (d == day) return e;
    }
    return null;
  }

  Excursion? firstAfter(List<Excursion> src, DateTime day) {
    for (final e in src) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (d.isAfter(day)) return e;
    }
    return null;
  }

  final current = findToday(items, today);
  final nextExcursion = current == null ? firstAfter(items, today) : null;
  final e = current ?? nextExcursion;

  if (e == null) {
    return Text(loc.noFutureExcursions, style: Theme.of(context).textTheme.bodyMedium);
  }

  final isToday = DateTime(e.date.year, e.date.month, e.date.day) == today;

  final chips = <Widget>[];

  // Date pill
  chips.add(_datePill(
    context: context,
    icon: isToday ? Icons.today : Icons.event,
    date: e.date,
    tooltip: isToday ? loc.today : null,
  ));

  // Port chip
  if ((e.port ?? '').trim().isNotEmpty) {
    chips.add(const SizedBox(width: 8));
    chips.add(_iconTextChip(
      context: context,
      icon: Icons.location_on_outlined,
      text: e.port!.trim(),
      tooltip: loc.harbour,
    ));
  }

  // Meeting point chip
  if ((e.meetingPoint ?? '').trim().isNotEmpty) {
    chips.add(const SizedBox(width: 8));
    chips.add(_iconTextChip(
      context: context,
      icon: Icons.meeting_room_outlined,
      text: e.meetingPoint!.trim(),
      tooltip: loc.meetingPoint,
    ));
  }

  // Price chip
  if (e.price != null) {
    final cur = (e.currency ?? '').trim();
    final priceStr = cur.isEmpty ? '${e.price}' : '${e.price} $cur';
    chips.add(const SizedBox(width: 8));
    chips.add(_iconTextChip(
      context: context,
      icon: Icons.euro_symbol,
      text: priceStr,
      tooltip: loc.price,
    ));
  }

    // Title line (icon + excursion title)
  final titleLine = Row(
    children: [
      const Icon(Icons.directions_walk, size: 16),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          e.title,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    ],
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      titleLine,
      const SizedBox(height: 6),
      Wrap(spacing: 0, runSpacing: 8, children: chips),
    ],
  );
}

/// small rounded chip with icon + one-line text
Widget _iconTextChip({
  required BuildContext context,
  required IconData icon,
  required String text,
  String? tooltip,
}) {
  final chip = Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    ),
  );
  return tooltip == null ? chip : Tooltip(message: tooltip, child: chip);
}

// ----- Travel preview (today or next) ---------------------------------------
Widget _buildTravelPreview(BuildContext context, List<TravelItem> list) {
  final loc = AppLocalizations.of(context)!;
  if (list.isEmpty) {
    return Text(loc.noTravelItem, style: Theme.of(context).textTheme.bodyMedium);
  }
  final now = DateTime.now();
  final items = List<TravelItem>.from(list)..sort((a, b) => a.start.compareTo(b.start));

  TravelItem? selected;
  for (final t in items) {
    if (t.start.isAfter(now) || _isSameDay(t.start, now)) {
      selected = t;
      break;
    }
  }
  selected ??= items.last;

  final t = selected;
  final chips = <Widget>[];

  chips.add(_timePill(
    context: context,
    icon: Icons.schedule,
    time: t.start,
    tooltip: loc.start,
  ));
  if (t.end != null) {
    chips.add(const SizedBox(width: 8));
    chips.add(_timePill(
      context: context,
      icon: Icons.flag,
      time: t.end!,
      tooltip: loc.end,
    ));
  }

  if ((t.from ?? '').trim().isNotEmpty || (t.to ?? '').trim().isNotEmpty) {
    chips.add(const SizedBox(width: 8));
    chips.add(_iconTextChip(
      context: context,
      icon: Icons.swap_horiz,
      text: _compactFromTo(t.from, t.to),
      tooltip: '$loc.from → $loc.to',
    ));
  }

  final typeChip = _typeSpecificChip(context, t);
  if (typeChip != null) {
    chips.add(const SizedBox(width: 8));
    chips.add(typeChip);
  }

  if (t.price != null) {
    final cur = (t.currency ?? '').trim();
    final priceStr = cur.isEmpty ? '${t.price}' : '${t.price} $cur';
    chips.add(const SizedBox(width: 8));
    chips.add(_iconTextChip(
      context: context,
      icon: Icons.euro_symbol,
      text: priceStr,
      tooltip: loc.price,
    ));
  }

  final titleLine = Row(
    children: [
      Icon(_travelKindIcon(t.kind), size: 16),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          _travelTitle(t, loc),
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    ],
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      titleLine,
      const SizedBox(height: 6),
      Wrap(spacing: 0, runSpacing: 8, children: chips),
    ],
  );
}

String _compactFromTo(String? from, String? to) {
  final f = (from ?? '').trim();
  final t = (to ?? '').trim();
  if (f.isEmpty && t.isEmpty) return '';
  if (f.isEmpty) return '→ $t';
  if (t.isEmpty) return '$f →';
  return '$f → $t';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

IconData _travelKindIcon(TravelKind k) {
  switch (k) {
    case TravelKind.flight:
      return Icons.flight_takeoff;
    case TravelKind.train:
      return Icons.train;
    case TravelKind.transfer:
      return Icons.local_taxi;
    case TravelKind.rentalCar:
      return Icons.directions_car;
    case TravelKind.hotel:
      return Icons.hotel;
    case TravelKind.cruiseCheckIn:
      return Icons.sailing_outlined;
    case TravelKind.cruiseCheckOut:
      return Icons.directions_boat;
  }
}

String _travelTitle(TravelItem t, AppLocalizations loc) {
  switch (t.kind) {
    case TravelKind.flight:
      final f = t as FlightItem;
      final flightNo = (f.flightNo ?? '').trim();
      final carrier = (f.carrier ?? '').trim();
      final numPart = flightNo.isEmpty ? '' : ' $flightNo';
      return (carrier + numPart).trim().isEmpty ? loc.flight : (carrier + numPart).trim();
    case TravelKind.train:
      return loc.train;
    case TravelKind.transfer:
      final tr = t as TransferItem;
      final mode = tr.mode?.name ?? loc.transfer;
      return mode[0].toUpperCase() + mode.substring(1);
    case TravelKind.rentalCar:
      final rc = t as RentalCarItem;
      final company = (rc.company ?? '').trim();
      return company.isEmpty ? loc.rentalCar : company;
    case TravelKind.hotel:
      final h = t as HotelItem;
      return h.name;
    case TravelKind.cruiseCheckIn:
      return loc.cruiseCheckIn;
    case TravelKind.cruiseCheckOut:
      return loc.cruiseCheckOut;
  }
}

Widget? _typeSpecificChip(BuildContext context, TravelItem t) {
  final loc = AppLocalizations.of(context)!;
  switch (t.kind) {
    case TravelKind.flight:
      final f = t as FlightItem;
      final flightNo = (f.flightNo ?? '').trim();
      if (flightNo.isNotEmpty) {
        return _iconTextChip(
          context: context,
          icon: Icons.flight,
          text: flightNo,
          tooltip: loc.flightnumber,
        );
      }
      return null;
    case TravelKind.train:
      return null;
    case TravelKind.transfer:
      final tr = t as TransferItem;
      if (tr.mode != null) {
        return _iconTextChip(
          context: context,
          icon: Icons.directions_car_filled,
          text: tr.mode!.name,
          tooltip: loc.transfer,
        );
      }
      return null;
    case TravelKind.rentalCar:
      final rc = t as RentalCarItem;
      if ((rc.company ?? '').trim().isNotEmpty) {
        return _iconTextChip(
          context: context,
          icon: Icons.directions_car_filled,
          text: rc.company!.trim(),
          tooltip: loc.rentalCarCompany,
        );
      }
      return null;
    case TravelKind.hotel:
      final ht = t as HotelItem;
      if (ht.name.trim().isNotEmpty) {
        return _iconTextChip(
          context: context,
          icon: Icons.hotel,
          text: ht.name.trim(),
          tooltip: loc.hotel,
        );
      }
      return null;
    case TravelKind.cruiseCheckIn:
      final cci = t as CruiseCheckIn;
      final timestring = fmtDate(context, cci.start);
      if (timestring.trim().isNotEmpty) {
        return _iconTextChip(
          context: context,
          icon: Icons.hotel,
          text: timestring.trim(),
          tooltip: loc.hotel,
        );
      }
      return null;
    case TravelKind.cruiseCheckOut:
      final cco = t as CruiseCheckOut;
      final timestring = fmtDate(context, cco.end);
      if (timestring.trim().isNotEmpty) {
        return _iconTextChip(
          context: context,
          icon: Icons.hotel,
          text: timestring.trim(),
          tooltip: loc.hotel,
        );
      }
      return null;
  }
}
