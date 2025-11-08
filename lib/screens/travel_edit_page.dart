import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/travel/base_travel.dart';
import '../models/travel/flight_item.dart';
import '../models/travel/train_item.dart';
import '../models/travel/transfer_item.dart';
import '../models/travel/rental_car_item.dart';

class TravelEditPage extends StatefulWidget {
  final TravelItem? initial;
  const TravelEditPage({super.key, this.initial});

  @override
  State<TravelEditPage> createState() => _TravelEditPageState();
}

class _TravelEditPageState extends State<TravelEditPage> {
  TravelKind _kind = TravelKind.flight;
  DateTime _start = DateTime.now(); DateTime? _end;
  final _from = TextEditingController(), _to = TextEditingController();
  final _notes = TextEditingController();
  // flight
  final _carrier = TextEditingController(), _flightNo = TextEditingController();
  // transfer
  TransferMode _mode = TransferMode.shuttle;
  // rental car
  final _company = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _kind = i.kind;
      _start = i.start; _end = i.end;
      _from.text = i.from ?? ''; _to.text = i.to ?? '';
      _notes.text = i.notes ?? '';
      if (i is FlightItem) { _carrier.text = i.carrier ?? ''; _flightNo.text = i.flightNo ?? ''; }
      if (i is TransferItem) { _mode = i.mode ?? TransferMode.shuttle; }
      if (i is RentalCarItem) { _company.text = i.company ?? ''; }
    }
  }

  Future<DateTime?> _pick(DateTime? base) async {
    final now = base ?? DateTime.now();
    final d = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d == null) return null;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    return DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
  }

  void _save() {
    final id = widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    switch (_kind) {
      case TravelKind.flight:
        Navigator.pop(context, FlightItem(
          id: id, start: _start, end: _end, from: _from.text.isEmpty?null:_from.text, to: _to.text.isEmpty?null:_to.text,
          notes: _notes.text.isEmpty?null:_notes.text, carrier: _carrier.text.isEmpty?'—':_carrier.text, flightNo: _flightNo.text.isEmpty?'—':_flightNo.text,
        )); return;
      case TravelKind.train:
        Navigator.pop(context, TrainItem(
          id: id, start: _start, end: _end, from: _from.text.isEmpty?null:_from.text, to: _to.text.isEmpty?null:_to.text,
          notes: _notes.text.isEmpty?null:_notes.text,
        )); return;
      case TravelKind.transfer:
        Navigator.pop(context, TransferItem(
          id: id, start: _start, end: _end, from: _from.text.isEmpty?null:_from.text, to: _to.text.isEmpty?null:_to.text,
          notes: _notes.text.isEmpty?null:_notes.text, mode: _mode,
        )); return;
      case TravelKind.rentalCar:
        Navigator.pop(context, RentalCarItem(
          id: id, start: _start, end: _end, from: _from.text.isEmpty?null:_from.text, to: _to.text.isEmpty?null:_to.text,
          notes: _notes.text.isEmpty?null:_notes.text, company: _company.text.isEmpty?'—':_company.text,
        )); return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMMd().add_Hm();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Travel'), actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.check)),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<TravelKind>(initialValue: _kind,
            items: TravelKind.values.map((k) => DropdownMenuItem(value: k, child: Text(k.name))).toList(),
            onChanged: (k) => setState(()=> _kind = k ?? _kind),
            decoration: const InputDecoration(labelText: 'Kind'),
          ),
          ListTile(title: const Text('Start'), subtitle: Text(df.format(_start)),
            onTap: () async { final d = await _pick(_start); if (d!=null) setState(()=>_start=d); }),
          ListTile(title: const Text('End (optional)'), subtitle: Text(_end==null?'—':df.format(_end!)),
            onTap: () async { final d = await _pick(_end ?? _start); setState(()=>_end=d); }),
          TextField(controller: _from, decoration: const InputDecoration(labelText: 'From (optional)')),
          TextField(controller: _to, decoration: const InputDecoration(labelText: 'To (optional)')),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          if (_kind == TravelKind.flight) ...[
            TextField(controller: _carrier, decoration: const InputDecoration(labelText: 'Carrier')),
            TextField(controller: _flightNo, decoration: const InputDecoration(labelText: 'Flight No')),
          ],
          if (_kind == TravelKind.transfer) ...[
            DropdownButtonFormField<TransferMode>(initialValue: _mode,
              items: TransferMode.values.map((m)=>DropdownMenuItem(value: m, child: Text(m.name))).toList(),
              onChanged: (m)=>setState(()=>_mode = m ?? TransferMode.shuttle),
              decoration: const InputDecoration(labelText: 'Mode'),
            ),
          ],
          if (_kind == TravelKind.rentalCar) ...[
            TextField(controller: _company, decoration: const InputDecoration(labelText: 'Company')),
          ],
        ],
      ),
    );
  }
}
