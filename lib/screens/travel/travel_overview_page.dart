import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cruise_app/gen/l10n/app_localizations.dart';
import 'package:cruise_app/models/cruise.dart';
import 'package:cruise_app/models/travel.dart';

import 'travel_type_picker.dart';
import 'travel_wizard_stubs.dart';

class TravelOverviewPage extends StatefulWidget {
  final Cruise cruise;
  final bool startWithAddFlow;

  const TravelOverviewPage({
    super.key,
    required this.cruise,
    this.startWithAddFlow = false,
  });

  @override
  State<TravelOverviewPage> createState() => _TravelOverviewPageState();
}

class _TravelOverviewPageState extends State<TravelOverviewPage> {
  late Cruise _cruise;

  @override
  void initState() {
    super.initState();
    _cruise = widget.cruise;
    if (widget.startWithAddFlow) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _onAdd();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final items = List<TravelItem>.from(_cruise.travel)..sort((a, b) => a.start.compareTo(b.start));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.travelOverviewTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(t.travelOverviewSubtitle(_cruise.title), style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: t.travelAddNew, onPressed: _onAdd),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: MaterialLocalizations.of(context).saveButtonLabel,
            onPressed: () => Navigator.of(context).pop(_cruise),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(t.travelEmptyHint)))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _groupByDate(items, locale).length,
              itemBuilder: (context, index) {
                final group = _groupByDate(items, locale)[index];
                return _DateGroup(
                  label: group.label,
                  children: group.items.map((i) {
                    return _TravelTile(
                      item: i,
                      onTap: () async {
                        final edited = await openEditWizard(context, i);
                        if (edited == null) return;
                        setState(() {
                          final list = List<TravelItem>.from(_cruise.travel);
                          final idx = list.indexWhere((x) => x.id == i.id);
                          if (idx >= 0) {
                            list[idx] = edited;
                            list.sort((a, b) => a.start.compareTo(b.start));
                            _cruise = _cruise.copyWith(travel: list);
                          }
                        });
                      },
                      onDelete: () {
                        setState(() {
                          final list = List<TravelItem>.from(_cruise.travel)
                            ..removeWhere((x) => x.id == i.id);
                          _cruise = _cruise.copyWith(travel: list);
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAdd,
        icon: const Icon(Icons.add),
        label: Text(t.travelAddNew),
      ),
    );
  }

  Future<void> _onAdd() async {
    final kind = await showTravelTypePicker(context);
    if (kind == null) return;

    final created = await openCreateWizard(context, kind);
    if (created == null) return;

    setState(() {
      final list = [..._cruise.travel, created]..sort((a, b) => a.start.compareTo(b.start));
      _cruise = _cruise.copyWith(travel: list);
    });
  }
}

/// ---- grouping helpers ----
class _Group {
  final String label;
  final List<TravelItem> items;
  _Group(this.label, this.items);
}

List<_Group> _groupByDate(List<TravelItem> items, String locale) {
  final df = DateFormat.yMMMMd(locale);
  final map = <String, List<TravelItem>>{};
  for (final i in items) {
    final k = df.format(i.start);
    (map[k] ??= []).add(i);
  }
  final groups = map.entries.map((e) => _Group(e.key, e.value)).toList();
  groups.sort((a, b) => a.items.first.start.compareTo(b.items.first.start));
  return groups;
}

class _DateGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _DateGroup({required this.label, required this.children});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 12),
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}

class _TravelTile extends StatelessWidget {
  final TravelItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TravelTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.Hm(locale);
    final title = item.end != null
        ? t.label_timeRange(time.format(item.start), time.format(item.end!))
        : time.format(item.start);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: _icon(item.type, context),
        title: Text(title),
        subtitle: Text(_subtitle(item)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.price != null && item.currency != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    NumberFormat.currency(locale: locale, name: item.currency!).format(item.price),
                  ),
                ),
              ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  static Widget _icon(TravelKind type, BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    switch (type) {
      case TravelKind.flight:
        return Icon(Icons.flight, color: c);
      case TravelKind.train:
        return Icon(Icons.train, color: c);
      case TravelKind.transfer:
        return Icon(Icons.airport_shuttle, color: c);
      case TravelKind.rentalCar:
        return Icon(Icons.directions_car, color: c);
    }
  }

  static String _subtitle(TravelItem i) {
    final a = (i.from ?? '').trim();
    final b = (i.to ?? '').trim();
    final route = (a.isEmpty && b.isEmpty) ? '—' : (a.isEmpty ? b : (b.isEmpty ? a : '$a → $b'));
    final id = i.summaryId();
    if (id.isEmpty) return route;
    return '$route · $id';
  }
}
