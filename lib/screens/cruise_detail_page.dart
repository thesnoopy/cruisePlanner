// lib/screens/cruise_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';

import 'package:cruiseplanner/data/cruise_repository.dart';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/models/travel.dart';
import 'package:cruiseplanner/models/route_item.dart';

import 'package:cruiseplanner/screens/cruise_details_read_only_page.dart';
import 'package:cruiseplanner/screens/excursion_list_page.dart';
import 'package:cruiseplanner/screens/route_detail_read_only_page.dart';
import 'package:cruiseplanner/screens/travel/travel_overview_page.dart';

import 'package:cruiseplanner/utils/route_utils.dart';

class CruiseDetailPage extends StatefulWidget {
  final Cruise cruise;
  final CruiseRepository repo;

  const CruiseDetailPage({
    super.key,
    required this.cruise,
    required this.repo,
  });

  @override
  State<CruiseDetailPage> createState() => _CruiseDetailPageState();
}

class _CruiseDetailPageState extends State<CruiseDetailPage> {
  late Cruise _current; // lokaler Bearbeitungsstand
  bool _dirty = false;  // wurde etwas geändert?

  @override
  void initState() {
    super.initState();
    _current = widget.cruise;
  }

  Future<void> _applyUpdatedCruise(Cruise updated) async {
    setState(() {
      _current = updated;
      _dirty = true; // damit beim Back ein aktualisiertes Objekt nach oben gereicht wird
    });

    try {
      // Passe den Methodennamen bei Bedarf an dein tatsächliches Repo an.
      await widget.repo.upsertCruise(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.savedSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final df = DateFormat.yMMMMd(localeTag);

    final cruise = _current;
    final start = cruise.period.start;
    final end = cruise.period.end;

    final excursions = List<Excursion>.from(cruise.excursions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    final nextExcursions =
        excursions.where((e) => !e.date.isBefore(today0)).toList();
    final Excursion? next =
        nextExcursions.isNotEmpty ? nextExcursions.first : null;

    final total = excursions.length;
    final futureCount = nextExcursions.length;

    String rangeText(DateTime s, DateTime e) =>
        "${df.format(s)} → ${df.format(e)}";

    String? formatMoney(num? value, String? code) {
      if (value == null || code == null || code.isEmpty) return null;
      return NumberFormat.currency(locale: localeTag, name: code).format(value);
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _dirty) {
          Navigator.of(context).pop(_current);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cruise.title),
              Text(
                "${cruise.ship.name} • ${cruise.ship.shippingLine}",
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Cruise-Details ---
            _OverviewCard(
              title: t.cruiseDetailsTitle,
              rows: [
                _IconText(Icons.directions_boat,
                    "${cruise.ship.name} • ${cruise.ship.shippingLine}"),
                _IconText(Icons.event, rangeText(start, end)),
                _IconText(Icons.flag, "$total ${t.excursionsCountLabel}"),
              ],
              trailingLabel: t.seeDetailsCta,
              onTap: () async {
                final updated = await Navigator.of(context).push<Cruise>(
                  MaterialPageRoute(
                    builder: (_) =>
                        CruiseDetailsReadOnlyPage(cruise: cruise, repo: widget.repo),
                  ),
                );
                if (updated != null) {
                  await _applyUpdatedCruise(updated);
                } else {
                  setState(() {});
                }
              },
            ),

            const SizedBox(height: 16),

            // --- NEU: Route (Heute/Morgen) ---
            RouteSectionCard(
              cruise: cruise,
              onSaveCruise: (updated) async {
                await _applyUpdatedCruise(updated);
              },
            ),

            const SizedBox(height: 16),

            // --- Nächster Ausflug ---
            _OverviewCard(
              title: t.nextExcursionTitle,
              rows: [
                _IconText(Icons.text_fields, next?.title ?? t.dash),
                _IconText(Icons.event, next != null ? df.format(next.date) : t.nonePlanned),
                _IconText(Icons.place, (next?.port?.isNotEmpty ?? false) ? next!.port! : t.dash),
                _IconText(Icons.meeting_room, (next?.meetingPoint?.isNotEmpty ?? false) ? next!.meetingPoint! : t.dash),
                _IconText(Icons.attach_money, formatMoney(next?.price, next?.currency) ?? t.dash),
              ],
              chips: [
                "$total ${t.totalLabel}",
                "$futureCount ${t.upcomingLabel}",
              ],
              trailingLabel: t.seeAllExcursionsCta,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExcursionListPage(cruise: cruise, repo: widget.repo),
                  ),
                );
                setState(() {});
              },
            ),

            const SizedBox(height: 16),

            // --- Travel-Teaser ---
            _TravelSectionTeaser(
              cruise: cruise,
              onUpdated: (updatedCruise) async {
                await _applyUpdatedCruise(updatedCruise);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// Route-Section Card (Heute / Morgen + "Alle anzeigen")
// ===================================================================
class RouteSectionCard extends StatelessWidget {
  final Cruise cruise;
  final ValueChanged<Cruise>? onSaveCruise;

  const RouteSectionCard({
    super.key,
    required this.cruise,
    this.onSaveCruise,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final routeSorted = sortRoute(cruise.route);
    final current = routeForToday(now, routeSorted);
    final next = routeForTomorrow(now, routeSorted);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
            title: Text(t.routeSectionTitle),
            trailing: TextButton.icon(
              onPressed: () => _openDetail(context),
              icon: const Icon(Icons.chevron_right),
              label: Text(t.routeShowAll),
            ),
            onTap: () => _openDetail(context),
          ),
          const Divider(height: 0),
          _RouteDayRow(label: t.routeToday, item: current),
          const Divider(height: 0),
          _RouteDayRow(label: t.routeTomorrow, item: next),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    final updated = await Navigator.of(context).push<Cruise>(
      MaterialPageRoute(
        builder: (_) => RouteDetailReadOnlyPage(cruise: cruise),
      ),
    );
    if (updated != null && onSaveCruise != null) {
      onSaveCruise!(updated);
    }
  }
}

class _RouteDayRow extends StatelessWidget {
  final String label;
  final RouteItem? item;
  const _RouteDayRow({required this.label, required this.item});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.yMMMMd(locale);
    final timeFmt = DateFormat.Hm(locale);

    IconData icon = Icons.help_outline;
    String title = t.routeEmptyHint;
    String subtitle = '';

    if (item != null) {
      if (item!.isSea) {
        icon = Icons.waves;
        title = t.routeSeaDayLabel;
        subtitle = dateFmt.format(item!.date);
      } else if (item!.isPort) {
        final p = item as PortCallItem;
        icon = Icons.anchor;
        final cityCountry = [
          if ((p.city ?? '').isNotEmpty) p.city,
          if ((p.country ?? '').isNotEmpty) p.country,
        ].whereType<String>().join(', ');
        title = cityCountry.isNotEmpty
            ? cityCountry
            : (p.portName.isNotEmpty ? p.portName : t.routePortCallLabel);
        subtitle =
            '${timeFmt.format(p.arrival)} – ${timeFmt.format(p.departure)} · ${dateFmt.format(p.date)}';
      }
    }

    return ListTile(
      leading: Icon(icon),
      title: Text('$label: $title'),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ===================================================================
// Allgemeine Übersichtskarte (bestehend) – unverändert
// ===================================================================
class _OverviewCard extends StatelessWidget {
  final String title;
  final List<_IconText> rows;
  final List<String>? chips;
  final String trailingLabel;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.title,
    required this.rows,
    required this.trailingLabel,
    required this.onTap,
    this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...rows.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(r.icon),
                        const SizedBox(width: 12),
                        Expanded(child: Text(r.text)),
                      ],
                    ),
                  )),
              if (chips != null && chips!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips!
                      .map((c) => Chip(
                            label: Text(c),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(trailingLabel, style: theme.textTheme.labelLarge),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText {
  final IconData icon;
  final String text;
  const _IconText(this.icon, this.text);
}

// ===================================================================
// Kompakter Travel-Teaser (tap -> TravelOverviewPage)
// ===================================================================
class _TravelSectionTeaser extends StatelessWidget {
  final Cruise cruise;
  final ValueChanged<Cruise> onUpdated;
  const _TravelSectionTeaser({required this.cruise, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final df = DateFormat.yMMMMd(locale).add_Hm();

    final items = List<TravelItem>.from(cruise.travel)
      ..sort((a, b) => a.start.compareTo(b.start));
    final next = cruise.nextTravelItem(DateTime.now());

    Widget body;
    if (items.isEmpty) {
      body = Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(t.travelEmptyHint)),
        ],
      );
    } else {
      final i = next ?? items.first;
      final hasEnd = i.end != null;
      final timeStr = hasEnd
          ? t.label_timeRange(df.format(i.start), df.format(i.end!))
          : df.format(i.start);
      final route = _route(i);

      body = Row(
        children: [
          _travelIcon(i.type, context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeStr, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(route, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(i.summaryId(), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (i.price != null && i.currency != null) ...[
            const SizedBox(width: 8),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                NumberFormat.currency(locale: locale, name: i.currency!).format(i.price),
              ),
            ),
          ],
        ],
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final updated = await Navigator.of(context).push<Cruise>(
            MaterialPageRoute(builder: (_) => TravelOverviewPage(cruise: cruise)),
          );
          if (updated != null && context.mounted) { onUpdated(updated); }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(t.travelSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 10),
              body,
            ],
          ),
        ),
      ),
    );
  }

  static String _route(TravelItem i) {
    final a = (i.from ?? '').trim();
    final b = (i.to ?? '').trim();
    if (a.isEmpty && b.isEmpty) return '—';
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a → $b';
    }

  static Widget _travelIcon(TravelKind type, BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    switch (type) {
      case TravelKind.flight:
        return Icon(Icons.flight_takeoff, color: color);
      case TravelKind.train:
        return Icon(Icons.train, color: color);
      case TravelKind.transfer:
        return Icon(Icons.airport_shuttle, color: color);
      case TravelKind.rentalCar:
        return Icon(Icons.directions_car, color: color);
    }
  }
}
