// Regenerated screens v2 – ID-only navigation, aligned with current models.

import 'dart:ffi';

import 'package:cruiseplanner/models/travel/cruise_check_in_item.dart';
import 'package:cruiseplanner/models/travel/cruise_check_out_item.dart';
import 'package:cruiseplanner/models/travel/hotel_item.dart';
import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/travel/base_travel.dart';
import '../../models/travel/flight_item.dart';
import '../../models/travel/train_item.dart';
import '../../models/travel/transfer_item.dart';
import '../../models/travel/rental_car_item.dart';
import '../../utils/format.dart';
import '../../l10n/app_localizations.dart';

class TravelEditScreen extends StatefulWidget {
  final String travelItemId;
  const TravelEditScreen({super.key, required this.travelItemId});

  @override
  State<TravelEditScreen> createState() => _TravelEditScreenState();
}

class _TravelEditScreenState extends State<TravelEditScreen> {
  TravelItem? _item;
  String? _cruiseId;

  final _formKey = GlobalKey<FormState>();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _notes = TextEditingController();
  final _price = TextEditingController();
  final _currency = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  // kind-specific
  final _carrier = TextEditingController();
  final _flightNo = TextEditingController();
  final _recordLocator = TextEditingController();
  TransferMode? _transferMode;
  final _company = TextEditingController(); // rental car
  final _name = TextEditingController();
  final _location = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = CruiseStore();
    await s.load();
    final item = s.getById<TravelItem>(widget.travelItemId);
    debugPrint("$item");
    String? cid;
    for (final c in s.cruises) {
      if (c.travel.any((t) => t.id == widget.travelItemId)) {
        cid = c.id;
        break;
      }
    }
    setState(() {
      _item = item;
      _cruiseId = cid;
      if (item != null) {
        _from.text = item.from ?? '';
        _to.text = item.to ?? '';
        _notes.text = item.notes ?? '';
        _price.text = fmtNumber(context,item.price);
        _currency.text = item.currency ?? '';
        _start = item.start;
        _end = item.end;
        _recordLocator.text = item.recordLocator ?? '';
        switch (item.kind) {
          case TravelKind.flight:
            final f = item as FlightItem;
            _carrier.text = f.carrier ?? '';
            _flightNo.text = f.flightNo ?? '';
            break;
          case TravelKind.train:
            break;
          case TravelKind.transfer:
            final tr = item as TransferItem;
            _transferMode = tr.mode;
            break;
          case TravelKind.rentalCar:
            final r = item as RentalCarItem;
            _company.text = r.company ?? '';
            break;
          case TravelKind.hotel:
            final h = item as HotelItem;
            _name.text = h.name;
            _location.text = h.location ?? '';
            break;
          case TravelKind.cruiseCheckIn:
            break;
          case TravelKind.cruiseCheckOut:
            break;
        }
      }
    });
  }

  Future<void> 
_pickDateTime(bool start) async {
  final initial = start ? (_start ?? DateTime.now()) : (_end ?? _start ?? DateTime.now());

  final date = await showDatePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    initialDate: initial,
  );
  if (date == null) return;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return;

  final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);

  setState(() {
    if (start) {
      _start = value;
      if (_end != null && _end!.isBefore(_start!)) {
        _end = _start;
      }
    } else {
      _end = value;
    }
  });
}

  Future<void> _save() async {
    final item = _item;
    final cid = _cruiseId;
    if (item == null || cid == null) return;
    if (!_formKey.currentState!.validate()) return;
    TravelItem next;
    switch (item.kind) {
      case TravelKind.flight:
        next = (item as FlightItem).copyWith(
          start: _start ?? item.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: _price.text.isEmpty ? null : parseLocalizedNumber(context, _price.text),
          currency: _currency.text.isEmpty ? null : _currency.text,
          carrier: _carrier.text.isEmpty ? null : _carrier.text,
          flightNo: _flightNo.text.isEmpty ? null : _flightNo.text,
          recordLocator: _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.train:
        next = (item as TrainItem).copyWith(
          start: _start ?? item.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: _price.text.isEmpty ? null : parseLocalizedNumber(context, _price.text),
          currency: _currency.text.isEmpty ? null : _currency.text,
          recordLocator: _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.transfer:
        next = (item as TransferItem).copyWith(
          start: _start ?? item.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: _price.text.isEmpty ? null : parseLocalizedNumber(context, _price.text),
          currency: _currency.text.isEmpty ? null : _currency.text,
          mode: _transferMode,
          recordLocator: _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.rentalCar:
        next = (item as RentalCarItem).copyWith(
          start: _start ?? item.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: _price.text.isEmpty ? null : parseLocalizedNumber(context, _price.text),
          currency: _currency.text.isEmpty ? null : _currency.text,
          company: _company.text.isEmpty ? null : _company.text,
          recordLocator: _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.hotel:
        next = (item as HotelItem).copyWith(
          start: _start ?? item.start,
          end: _end,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: _price.text.isEmpty ? null : parseLocalizedNumber(context, _price.text),
          currency: _currency.text.isEmpty ? null : _currency.text,
          company: _company.text.isEmpty ? null : _company.text,
          name: _name.text.isEmpty ? null : _name.text,
          location: _location.text.isEmpty ? null : _location.text,
          recordLocator: _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
      case TravelKind.cruiseCheckIn:
        next = (item as CruiseCheckIn).copyWith(
          start: _start ?? item.start,
          end: _end,
          notes: _notes.text.isEmpty ? null : _notes.text,
          recordLocator: _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
      case TravelKind.cruiseCheckOut:
        next = (item as CruiseCheckOut).copyWith(
          start: _start ?? item.start,
          end: _end,
          notes: _notes.text.isEmpty ? null : _notes.text,
          recordLocator: _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
    }
    final s = CruiseStore();
    await s.load();
    await s.upsertTravelItem(cruiseId: cid, item: next);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final loc = AppLocalizations.of(context)!;

    final title = switch (item?.kind) {
      TravelKind.flight     => loc.editFlight,
      TravelKind.train      => loc.editTrain,
      TravelKind.transfer   => loc.editTransfer,
      TravelKind.rentalCar  => loc.editRentalCar,
      TravelKind.hotel      => loc.hotel,
      TravelKind.cruiseCheckIn      => loc.cruiseCheckIn,
      TravelKind.cruiseCheckOut      => loc.cruiseCheckOut,
      _                     => loc.editTravel,
    };


    List<Widget> writeScreen({
      String from = "",
      String to = "",
      String start = "",
      String end = "",
      String notes = "",
      String price = "",
      String carrier = "",
      String flightNo = "",
      String recordLocator = "",
      String transferMode = "",
      String company = "",
      String name = "",
      String location = "",

    }){
      final List<Widget> collection = [];
      if(from != "") {
        collection.add(_row(from, TextFormField(controller: _from, validator: (v) => (v == null || v.isEmpty) ? loc.requiredField : null)));
        collection.add(const SizedBox(height: 12));
      }
      if(to != ""){
        collection.add(_row(to, TextFormField(controller: _to, validator: (v) => (v == null || v.isEmpty) ? to : null)));
        collection.add(const SizedBox(height: 12));
      }
      if(start != ""){
        collection.add(ListTile(title: Text(start), subtitle: Text(fmtDate(context, _start ?? DateTime.now(), includeTime: true)), trailing: const Icon(Icons.edit_calendar), onTap: () => _pickDateTime(true)));
      }
      if(end != ""){
        collection.add(ListTile(title: Text(end), subtitle: Text(fmtDate(context, _end ?? _start ?? DateTime.now(), includeTime: true)), trailing: const Icon(Icons.edit_calendar), onTap: () => _pickDateTime(false)));
      }
      collection.add(const SizedBox(height: 12));
      if(notes != ""){
        collection.add(TextFormField(controller: _notes, decoration: InputDecoration(labelText: notes), maxLines: 3));
        collection.add(const SizedBox(height: 12));
      }
      if(price != ""){
        collection.add(Row(children: [Expanded(child: TextFormField(controller: _price, decoration: InputDecoration(labelText: loc.price), keyboardType: TextInputType.numberWithOptions(decimal: true))), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _currency, decoration: InputDecoration(labelText: loc.currencyOptional)))]));
        collection.add(const Divider(height: 32));
      }
      if(carrier != ""){
        collection.add(TextFormField(controller: _carrier, decoration: InputDecoration(labelText: carrier)));
        collection.add(const SizedBox(height: 12));
      }
      if(flightNo != ""){
        collection.add(TextFormField(controller: _flightNo, decoration: InputDecoration(labelText: flightNo)));
      }
      if(recordLocator != ""){
        collection.add(TextFormField(controller: _recordLocator, decoration: InputDecoration(labelText: recordLocator)));
      }
      if(transferMode != ""){
        collection.add(
          DropdownButtonFormField<TransferMode>(
                value: _transferMode,
                items: [for (final m in TransferMode.values) DropdownMenuItem(value: m, child: Text(m.name))],
                onChanged: (v) => setState(() => _transferMode = v),
                decoration: InputDecoration(labelText: transferMode),
              )
        );
      }
        if(company != ""){
          collection.add(TextFormField(controller: _company, decoration: InputDecoration(labelText: company)));
        }
      if(name != ""){
        collection.add(TextFormField(controller: _name, decoration: InputDecoration(labelText: loc.hotel)));
      }
      if(location != ""){
        collection.add(TextFormField(controller: _location, decoration: InputDecoration(labelText: loc.location)));
      }
      collection.add(const SizedBox(height: 24));
      collection.add(FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(loc.save)));
      return collection;
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: item == null ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if(item.kind == TravelKind.flight) ...writeScreen(
              from: loc.from,
              to: loc.to,
              start: loc.start,
              end: loc.end,
              notes: loc.notesOptional,
              price: loc.price,
              carrier: loc.airlineOptional,
              flightNo: loc.flightnumber,
              recordLocator: loc.bookingNumberOptional
            ),
            if(item.kind == TravelKind.train) ...writeScreen(
              from: loc.from,
              to: loc.to,
              start: loc.start,
              end: loc.end,
              notes: loc.notesOptional,
              price: loc.price
            ),
            if(item.kind == TravelKind.transfer) ...writeScreen(
              from: loc.from,
              to: loc.to,
              start: loc.start,
              end: loc.end,
              notes: loc.notesOptional,
              price: loc.price,
              transferMode: loc.modeOptional,
            ),
            if(item.kind == TravelKind.rentalCar) ...writeScreen(
              from: loc.from,
              to: loc.to,
              start: loc.start,
              end: loc.end,
              notes: loc.notesOptional,
              price: loc.price,
              recordLocator: loc.bookingNumberOptional,
              company: loc.rentalCarCompany
            ),
            if(item.kind == TravelKind.hotel) ...writeScreen(
              start: loc.start,
              end: loc.end,
              notes: loc.notesOptional,
              price: loc.price,
              name: loc.hotel,
              recordLocator: loc.bookingNumberOptional,
              location: loc.location,
            ),
            if(item.kind == TravelKind.cruiseCheckIn) ...writeScreen(
              start: loc.start,
              end: loc.end,
              notes: loc.notesOptional,
            ),
            if(item.kind == TravelKind.cruiseCheckOut) ...writeScreen(
              start: loc.start,
              end: loc.end,
              notes: loc.notesOptional,
            ),
          ]
        ),
      ),
    );
  }

  Widget _row(String label, Widget field) => Row(children: [Expanded(child: Text(label)), const SizedBox(width: 12), Expanded(flex: 2, child: field)]);
}