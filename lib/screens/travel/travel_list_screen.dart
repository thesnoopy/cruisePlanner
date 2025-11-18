// Regenerated screens v2 – ID-only navigation, aligned with current models.

import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/cruise.dart';
import '../../models/travel/base_travel.dart';
import '../../models/travel/flight_item.dart';
import '../../models/travel/train_item.dart';
import '../../models/travel/transfer_item.dart';
import '../../models/travel/rental_car_item.dart';
import '../../models/identifiable.dart';
import '../../utils/format.dart';
import 'travel_edit_screen.dart';
import '../../l10n/app_localizations.dart';

class TravelListScreen extends StatefulWidget {
  final String cruiseId;
  const TravelListScreen({super.key, required this.cruiseId});

  @override
  State<TravelListScreen> createState() => _TravelListScreenState();
}

class _TravelListScreenState extends State<TravelListScreen> {
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

  Future<void> _create(TravelKind kind) async {
    final id = Identifiable.newId();
    final s = CruiseStore();
    await s.load();
    final c = s.getCruise(widget.cruiseId);
    if (c == null) return;
    final now = c.period.start;
    TravelItem item;
    switch (kind) {
      case TravelKind.flight:
        item = FlightItem(id: id, start: now, end: now, from: '', to: '', notes: null, price: null, currency: null, carrier: null, flightNo: null, recordLocator: null);
        break;
      case TravelKind.train:
        item = TrainItem(id: id, start: now, end: now, from: '', to: '', notes: null, price: null, currency: null);
        break;
      case TravelKind.transfer:
        item = TransferItem(id: id, start: now, end: now, from: '', to: '', notes: null, price: null, currency: null, mode: null);
        break;
      case TravelKind.rentalCar:
        item = RentalCarItem(id: id, start: now, end: now.add(const Duration(days: 1)), from: '', to: '', notes: null, price: null, currency: null, company: null);
        break;
    }
    await s.upsertTravelItem(cruiseId: widget.cruiseId, item: item);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TravelEditScreen(travelItemId: id)));
    await _load();
  }

  void _showCreateMenu() {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.flight), title: Text(loc.flight), onTap: () { Navigator.pop(ctx); _create(TravelKind.flight); }),
          ListTile(leading: const Icon(Icons.train), title: Text(loc.train), onTap: () { Navigator.pop(ctx); _create(TravelKind.train); }),
          ListTile(leading: const Icon(Icons.directions_bus), title: Text(loc.transfer), onTap: () { Navigator.pop(ctx); _create(TravelKind.transfer); }),
          ListTile(leading: const Icon(Icons.directions_car), title: Text(loc.rentalCar), onTap: () { Navigator.pop(ctx); _create(TravelKind.rentalCar); }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _cruise;
    final loc = AppLocalizations.of(context)!;
    c?.travel.sort((a, b) => a.start.compareTo(b.start));
    return Scaffold(
      appBar: AppBar(title: Text(loc.travel)),
      body: c == null || c.travel.isEmpty
          ? Center(child: Text(loc.noTravelItem))
          : ListView.builder(
              itemCount: c.travel.length,
              itemBuilder: (_, i) {
                final t = c.travel[i];
                return ListTile(
                  subtitle: _subtitleFor(context, t),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TravelEditScreen(travelItemId: t.id)));
                    await _load();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final s = CruiseStore();
                      await s.load();
                      await s.deleteTravelItem(t.id);
                      await _load();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateMenu, child: const Icon(Icons.add)),
    );
  }

  Widget _subtitleFor(BuildContext context, TravelItem t) {
    final from = t.from ?? '';
    final to = t.to ?? '';

    final dateStr = fmtDate(context, t.start);
    final startTimeStr = fmtDate(context, t.start, timeOnly: true);
    final endTimeStr =
        t.end != null ? fmtDate(context, t.end, timeOnly: true) : null;
    final timeText =
        endTimeStr != null ? '$startTimeStr – $endTimeStr' : startTimeStr;

    return ListTile(
      leading: Icon(_travelKindIcon(t.kind)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeile 1: Von → Nach
          Row(
            children: [
              const Icon(Icons.location_on, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$from → $to',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Zeile 2: Datum
          Row(
            children: [
              const Icon(Icons.event, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  dateStr,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Zeile 3: Zeit / Zeitraum
          Row(
            children: [
              const Icon(Icons.schedule, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  timeText,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      )
    );
  }

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
  }
}