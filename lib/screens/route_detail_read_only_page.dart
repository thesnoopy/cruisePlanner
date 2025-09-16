// lib/screens/route_detail_read_only_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';

import '../models/cruise.dart';
import '../models/route_item.dart';
import '../utils/route_utils.dart';
import 'route_wizard_page.dart';

class RouteDetailReadOnlyPage extends StatefulWidget {
  final Cruise cruise;
  const RouteDetailReadOnlyPage({super.key, required this.cruise});

  @override
  State<RouteDetailReadOnlyPage> createState() => _RouteDetailReadOnlyPageState();
}

class _RouteDetailReadOnlyPageState extends State<RouteDetailReadOnlyPage> {
  late List<RouteItem> _route;

  @override
  void initState() {
    super.initState();
    _route = sortRoute(widget.cruise.route);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeFmt = DateFormat.Hm(locale);
    final dateFmt = DateFormat.yMMMMd(locale);

    return Scaffold(
      appBar: AppBar(title: Text(t.routeTitle)),
      body: _route.isEmpty
          ? _EmptyRoute(t: t, onAddFirst: _createPort)
          : ListView.separated(
              itemCount: _route.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) {
                final item = _route[i];
                final day = DateTime(item.date.year, item.date.month, item.date.day);
                final isToday = day == today;
                final isTomorrow = day == tomorrow;

                return ListTile(
                  leading: Icon(item.isSea ? Icons.waves : Icons.anchor),
                  title: Text(_titleFor(item, t)),
                  subtitle: Text(_subtitleFor(item, dateFmt, timeFmt, t)),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      if (isToday) Chip(label: Text(t.routeChipToday)),
                      if (isTomorrow) Chip(label: Text(t.routeChipTomorrow)),
                    ],
                  ),
                  onTap: () => _edit(item),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPort,
        tooltip: t.routeAddTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _titleFor(RouteItem item, AppLocalizations t) {
    if (item.isSea) return t.routeSeaDayLabel;
    final p = item as PortCallItem;
    final cityCountry = [
      if ((p.city ?? '').isNotEmpty) p.city,
      if ((p.country ?? '').isNotEmpty) p.country,
    ].whereType<String>().join(', ');
    return cityCountry.isNotEmpty ? cityCountry : (p.portName.isNotEmpty ? p.portName : t.routePortCallLabel);
  }

  String _subtitleFor(RouteItem item, DateFormat dateFmt, DateFormat timeFmt, AppLocalizations t) {
    if (item.isSea) return dateFmt.format(item.date);
    final p = item as PortCallItem;
    final time = '${timeFmt.format(p.arrival)} – ${timeFmt.format(p.departure)}';
    final extra = (p.terminal?.isNotEmpty == true) ? ' · ${p.terminal}' : '';
    return '$time · ${dateFmt.format(p.date)}$extra';
  }

  Future<void> _createPort() async {
    final newItem = await Navigator.of(context).push<RouteItem>(
      MaterialPageRoute(builder: (_) => RouteWizardPage()),
    );
    if (newItem != null) {
      setState(() {
        _route = sortRoute([..._route, newItem]);
      });
      _returnUpdatedCruise();
    }
  }

  Future<void> _edit(RouteItem item) async {
    final edited = await Navigator.of(context).push<RouteItem?>(
      MaterialPageRoute(builder: (_) => RouteWizardPage(initial: item)),
    );
    if (edited == null) return; // Abgebrochen
    setState(() {
      _route = sortRoute([
        for (final r in _route) if (r.id == item.id) edited else r,
      ]);
    });
    _returnUpdatedCruise();
  }

  void _returnUpdatedCruise() {
    final updated = widget.cruise.copyWith(route: _route);
    // Übergibt die aktualisierte Cruise zurück an die aufrufende Seite,
    // damit dort sofort ins Repo gespeichert werden kann.
    Navigator.of(context).pop(updated);
  }
}

class _EmptyRoute extends StatelessWidget {
  final AppLocalizations t;
  final VoidCallback onAddFirst;
  const _EmptyRoute({required this.t, required this.onAddFirst});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 48),
            const SizedBox(height: 12),
            Text(t.routeEmptyHint, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAddFirst,
              icon: const Icon(Icons.add),
              label: Text(t.routeAddFirstPortCta),
            ),
          ],
        ),
      ),
    );
  }
}
