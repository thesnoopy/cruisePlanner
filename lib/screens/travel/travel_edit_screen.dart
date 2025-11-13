// Regenerated screens v2 – ID-only navigation, aligned with current models.

import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/travel/base_travel.dart';
import '../../models/travel/flight_item.dart';
import '../../models/travel/train_item.dart';
import '../../models/travel/transfer_item.dart';
import '../../models/travel/rental_car_item.dart';
import '../../utils/format.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = CruiseStore();
    await s.load();
    final item = s.getById<TravelItem>(widget.travelItemId);
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
        _price.text = item.price?.toString() ?? '';
        _currency.text = item.currency ?? '';
        _start = item.start;
        _end = item.end;
        switch (item.kind) {
          case TravelKind.flight:
            final f = item as FlightItem;
            _carrier.text = f.carrier ?? '';
            _flightNo.text = f.flightNo ?? '';
            _recordLocator.text = f.recordLocator ?? '';
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
          price: _price.text.isEmpty ? null : num.tryParse(_price.text),
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
          price: _price.text.isEmpty ? null : num.tryParse(_price.text),
          currency: _currency.text.isEmpty ? null : _currency.text,
        );
        break;
      case TravelKind.transfer:
        next = (item as TransferItem).copyWith(
          start: _start ?? item.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: _price.text.isEmpty ? null : num.tryParse(_price.text),
          currency: _currency.text.isEmpty ? null : _currency.text,
          mode: _transferMode,
        );
        break;
      case TravelKind.rentalCar:
        next = (item as RentalCarItem).copyWith(
          start: _start ?? item.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: _price.text.isEmpty ? null : num.tryParse(_price.text),
          currency: _currency.text.isEmpty ? null : _currency.text,
          company: _company.text.isEmpty ? null : _company.text,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Reise bearbeiten')),
      body: item == null ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _row('Von', TextFormField(controller: _from, validator: (v) => (v == null || v.isEmpty) ? 'Pflichtfeld' : null)),
            const SizedBox(height: 12),
            _row('Nach', TextFormField(controller: _to, validator: (v) => (v == null || v.isEmpty) ? 'Pflichtfeld' : null)),
            const SizedBox(height: 12),
            ListTile(title: const Text('Start'), subtitle: Text(fmtDate(context, _start ?? DateTime.now(), pattern: 'yMMMd HH:mm')), trailing: const Icon(Icons.edit_calendar), onTap: () => _pickDateTime(true)),
            ListTile(title: const Text('Ende'), subtitle: Text(fmtDate(context, _end ?? _start ?? DateTime.now(), pattern: 'yMMMd HH:mm')), trailing: const Icon(Icons.edit_calendar), onTap: () => _pickDateTime(false)),
            const SizedBox(height: 12),
            TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Notizen (optional)'), maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: TextFormField(controller: _price, decoration: const InputDecoration(labelText: 'Preis'), keyboardType: TextInputType.number)), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _currency, decoration: const InputDecoration(labelText: 'Währung')))]),
            const Divider(height: 32),
            if (item.kind == TravelKind.flight) ...[
              TextFormField(controller: _carrier, decoration: const InputDecoration(labelText: 'Airline (optional)')),
              const SizedBox(height: 12),
              TextFormField(controller: _flightNo, decoration: const InputDecoration(labelText: 'Flugnummer (optional)')),
              const SizedBox(height: 12),
              TextFormField(controller: _recordLocator, decoration: const InputDecoration(labelText: 'Buchungscode (optional)')),
            ] else if (item.kind == TravelKind.transfer) ...[
              DropdownButtonFormField<TransferMode>(
                value: _transferMode,
                items: [for (final m in TransferMode.values) DropdownMenuItem(value: m, child: Text(m.name))],
                onChanged: (v) => setState(() => _transferMode = v),
                decoration: const InputDecoration(labelText: 'Modus (optional)'),
              ),
            ] else if (item.kind == TravelKind.rentalCar) ...[
              TextFormField(controller: _company, decoration: const InputDecoration(labelText: 'Vermieter (optional)')),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, Widget field) => Row(children: [Expanded(child: Text(label)), const SizedBox(width: 12), Expanded(flex: 2, child: field)]);
}