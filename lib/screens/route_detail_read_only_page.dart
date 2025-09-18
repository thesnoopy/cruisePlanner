// lib/screens/route_detail_read_only_page.dart (mit Swipe-to-Delete, ohne saveCruise-Aufrufe)
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
    _route = List<RouteItem>.from(widget.cruise.route ?? const <RouteItem>[]);
    _route = sortRoute(_route);
  }

  List<RouteItem> _sorted(List<RouteItem> list) => sortRoute(list);

  String _titleFor(RouteItem item, AppLocalizations t) {
    if (item is PortCallItem) {
      final city = item.city?.trim();
      if (city != null && city.isNotEmpty) return city;
      final pn = item.portName.trim();
      return pn.isNotEmpty ? pn : t.routePortCallLabel;
    }
    return t.routeSeaDayLabel;
  }

  String _subtitleFor(RouteItem item, String localeTag) {
    final dateStr = DateFormat.yMMMd(localeTag).format(item.date);
    if (item is PortCallItem) {
      final timeFmt = DateFormat.Hm(localeTag);
      final arr = timeFmt.format(item.arrival);
      final dep = timeFmt.format(item.departure);
      return '$dateStr • $arr – $dep';
    }
    return dateStr;
  }

  Future<void> _createPort() async {
    final created = await Navigator.of(context).push<RouteItem>(
      MaterialPageRoute(
        builder: (_) => const RouteWizardPage(initial: null),
      ),
    );
    if (created == null) return;
    setState(() {
      _route = _sorted([..._route, created]);
    });
  }

  Future<void> _edit(RouteItem item) async {
    final edited = await Navigator.of(context).push<RouteItem>(
      MaterialPageRoute(
        builder: (_) => RouteWizardPage(initial: item),
      ),
    );
    if (edited == null) return;
    setState(() {
      _route = _sorted([
        for (final r in _route) if (r.id == item.id) edited else r,
      ]);
    });
  }

  Future<bool> _confirmDelete(BuildContext context, RouteItem item) async {
    final t = AppLocalizations.of(context)!;
    final name = _titleFor(item, t);
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t.deleteCruiseTitle), // temporär wiederverwendet
            content: Text(t.deleteCruiseMessage(name)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.deleteCancel)),
              FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: Text(t.deleteConfirm)),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
        if (!isCurrent) return;

        final updatedCruise = widget.cruise.copyWith(route: _route);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pop<Cruise>(updatedCruise);
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.routeTitle),
          actions: [
            IconButton(
              tooltip: t.routeAddTooltip,
              onPressed: _createPort,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: _route.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.routeEmptyHint, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _createPort,
                      icon: const Icon(Icons.add),
                      label: Text(t.routeAddFirstPortCta),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _route.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, i) {
                  final item = _route[i];
                  final title = _titleFor(item, t);
                  final subtitle = _subtitleFor(item, localeTag);
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) => _confirmDelete(context, item),
                    onDismissed: (_) {
                      setState(() {
                        _route.removeAt(i);
                      });
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _edit(item),
                      ),
                    )
                  );
                },
              ),
      ),
    );
  }
}