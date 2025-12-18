// Regenerated screens v2 – ID-only navigation, aligned with current models.

import 'package:cruiseplanner/models/travel/cruise_check_in_item.dart';
import 'package:cruiseplanner/models/travel/cruise_check_out_item.dart';
import 'package:cruiseplanner/models/travel/hotel_item.dart';
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
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/showMapAppPicker.dart';

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
    debugPrint("kind = $kind");
    switch (kind) {
      case TravelKind.flight:
        item = FlightItem(id: id, start: c.period.start, end: c.period.start, from: '', to: '', notes: null, price: null, currency: null, carrier: null, flightNo: null, recordLocator: null);
        break;
      case TravelKind.train:
        item = TrainItem(id: id, start: c.period.start, end: c.period.start, from: '', to: '', notes: null, price: null, currency: null);
        break;
      case TravelKind.transfer:
        item = TransferItem(id: id, start: c.period.start, end: c.period.start, from: '', to: '', notes: null, price: null, currency: null, mode: null);
        break;
      case TravelKind.rentalCar:
        item = RentalCarItem(id: id, start: c.period.start, end: c.period.start.add(const Duration(days: 1)), from: '', to: '', notes: null, price: null, currency: null, company: null, recordLocator: null);
        break;
      case TravelKind.hotel:
        item = HotelItem(id: id, start: c.period.start, end: c.period.start, from: '', to: '', notes: null, price: null, currency: null, name: '',recordLocator: '', location: '');
        debugPrint("$item");
        break;
      case TravelKind.cruiseCheckIn:
        item = CruiseCheckIn(id: id, start: c.period.start, end: c.period.start, from: '', to: '', notes: null, price: null, currency: null);
        break;
      case TravelKind.cruiseCheckOut:
        item = CruiseCheckOut(id: id, start: c.period.start, end: c.period.start, from: '', to: '', notes: null, price: null, currency: null);
        break;
    }
    debugPrint("Before upsert");
    await s.upsertTravelItem(cruiseId: widget.cruiseId, item: item);
    debugPrint("After upsert");
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
          ListTile(leading: const Icon(Icons.hotel), title: Text(loc.hotel), onTap: () { Navigator.pop(ctx); _create(TravelKind.hotel); }),
          ListTile(leading: const Icon(Icons.sailing), title: Text(loc.cruiseCheckIn), onTap: () { Navigator.pop(ctx); _create(TravelKind.cruiseCheckIn); }),
          ListTile(leading: const Icon(Icons.directions_boat), title: Text(loc.cruiseCheckOut), onTap: () { Navigator.pop(ctx); _create(TravelKind.cruiseCheckOut); }),
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
                String address = "";
                if(t.kind == TravelKind.hotel) {
                  final hotel = t as HotelItem;
                  address = hotel.location ?? '';
                }
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TravelEditScreen(travelItemId: t.id),
                        ),
                      );
                      await _load();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                            child: Icon(
                              _travelKindIcon(t.kind), // gibt es schon im cruise_hub_screen.dart
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _subtitleTravelitemPerKind(context, t, c.id),
                          ),
                          if (address != '')   
                            IconButton(
                              icon: const Icon(Icons.navigation_outlined),
                              onPressed: () => showMapAppPicker(
                                        context: context,
                                        address: address,
                                        title: loc.startNavigation,
                                      ),
                            ),
                          // neuer Lösch-Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final s = CruiseStore();
                              await s.load();
                                final loc = AppLocalizations.of(context)!;
                                final confirmed = await showConfirmationDialog(
                                  context: context,
                                  title: loc.deleteTravelItemTitle,              // optional
                                  message: loc.deleteTravelItemQuestionmark, // optional
                                  okText: loc.delete,                     // optional
                                  cancelText: loc.confirmCancel,               // optional
                                  icon: Icons.warning_amber_rounded,     // optional
                                  destructive: true,                     // optional (OK Button rot)
                                );

                                if (!confirmed) return;
                              await s.deleteTravelItem(t.id);
                              await _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMenu,
        child: const Icon(Icons.add),
      ),
    );
  }


  Widget _subtitleTravelitemPerKind(BuildContext context, TravelItem t, String cruiseId) {
    final CruiseStore cs = CruiseStore();
    final c = cs.getCruise(cruiseId);
    List<Widget> childs = [];
    if(t.from != '' || t.to != '') {
      childs.add(
        Row(
          children: [
            const Icon(Icons.location_on, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${t.from} → ${t.to}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        )
      );
    }
    if(t.start != c?.period.start){
      childs.add(
        Row(
          children: [
            const Icon(Icons.event, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                fmtDate(context, t.start),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        )
      );
    }
    if(t.start != c?.period.start){
      final startTimeStr = 
          fmtDate(context, t.start, timeOnly: true);
      final endTimeStr =
          t.end != null ? fmtDate(context, t.end, timeOnly: true) : null;
      final timeText =
          endTimeStr != null ? '$startTimeStr – $endTimeStr' : startTimeStr;
      childs.add(
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
        )
      );
    }
    if(t.price != null){
      // Row 4: Price
      childs.add(
        Row(
          children: [
            const Icon(Icons.money, size: 14,),
            const SizedBox(width: 4),
            Flexible(
              child: Text(fmtMoney(context, t.price, currency: t.currency), overflow: TextOverflow.ellipsis),
              )
          ],)
      );
    }
    /////
    //Special handling for sub items
    /////
    switch (t.kind){
      case TravelKind.flight:
        final flight = t as FlightItem;
        if (flight.carrier != null) {
          childs.add(
            Row(
              children: [
                const Icon(Icons.airlines, size: 14,),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(flight.carrier ?? '', overflow: TextOverflow.ellipsis),
                  )
              ],
            )
          );
        }
        if (flight.flightNo != null) {
          childs.add(
            Row(
              children: [
                const Icon(Icons.flight, size: 14,),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(flight.flightNo ?? '', overflow: TextOverflow.ellipsis),
                  )
              ],
            )
          );
        }
        if (flight.recordLocator != null) {
          childs.add(
            Row(
              children: [
                const Icon(Icons.receipt, size: 14,),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(flight.recordLocator ?? '', overflow: TextOverflow.ellipsis),
                  )
              ],
            )
          );
        }
      case TravelKind.hotel:
        final hotel = t as HotelItem;
          childs.add(
          Row(
            children: [
              const Icon(Icons.location_city, size: 14,),
              const SizedBox(width: 4),
              Flexible(
                child: Text(hotel.name, overflow: TextOverflow.ellipsis),
                )
            ],
          )
        );
          childs.add(
          Row(
            children: [
              const Icon(Icons.location_pin, size: 14,),
              const SizedBox(width: 4),
              Flexible(
                child: Text(hotel.location ?? '', overflow: TextOverflow.ellipsis),
                )
            ],
          )
        );
        break;
      case TravelKind.rentalCar:
        final rentalCar = t as RentalCarItem;
        if (rentalCar.recordLocator != null) {
          childs.add(
            Row(
              children: [
                const Icon(Icons.receipt, size: 14,),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(rentalCar.recordLocator ?? '', overflow: TextOverflow.ellipsis),
                  )
              ],
            )
          );
        }
      default:
        break;
    }


    return ListTile(
      //leading: Icon(_travelKindIcon(t.kind)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: childs
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
    case TravelKind.hotel:
      return Icons.hotel;
    case TravelKind.cruiseCheckIn:
      return Icons.sailing_outlined;
    case TravelKind.cruiseCheckOut:
      return Icons.sailing_outlined;
  }
}