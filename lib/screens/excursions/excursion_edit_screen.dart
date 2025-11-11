// Regenerated screens v2 – ID-only navigation, aligned with current models.

import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/excursion.dart';

class ExcursionEditScreen extends StatefulWidget {
  final String excursionId;
  const ExcursionEditScreen({super.key, required this.excursionId});

  @override
  State<ExcursionEditScreen> createState() => _ExcursionEditScreenState();
}

class _ExcursionEditScreenState extends State<ExcursionEditScreen> {
  Excursion? _ex;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _port;
  late TextEditingController _meeting;
  late TextEditingController _notes;
  late TextEditingController _price;
  late TextEditingController _currency;
  DateTime? _date;
  String? _cruiseId; // resolved via scan

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = CruiseStore();
    await s.load();
    final ex = s.getById<Excursion>(widget.excursionId);
    String? cid;
    for (final c in s.cruises) {
      if (c.excursions.any((e) => e.id == widget.excursionId)) {
        cid = c.id;
        break;
      }
    }
    setState(() {
      _ex = ex;
      _cruiseId = cid;
      _title = TextEditingController(text: ex?.title ?? '');
      _port = TextEditingController(text: ex?.port ?? '');
      _meeting = TextEditingController(text: ex?.meetingPoint ?? '');
      _notes = TextEditingController(text: ex?.notes ?? '');
      _price = TextEditingController(text: ex?.price?.toString() ?? '');
      _currency = TextEditingController(text: ex?.currency ?? '');
      _date = ex?.date;
    });
  }

  Future<void> _save() async {
    final ex = _ex;
    final cid = _cruiseId;
    if (ex == null || cid == null) return;
    if (!_formKey.currentState!.validate()) return;
    final next = Excursion(
      id: ex.id,
      title: _title.text.trim(),
      date: _date ?? ex.date,
      port: _port.text.trim().isEmpty ? null : _port.text.trim(),
      meetingPoint: _meeting.text.trim().isEmpty ? null : _meeting.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      price: _price.text.trim().isEmpty ? null : num.tryParse(_price.text.trim()),
      currency: _currency.text.trim().isEmpty ? null : _currency.text.trim(),
    );
    final s = CruiseStore();
    await s.load();
    await s.upsertExcursion(cruiseId: cid, excursion: next);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final initial = _date ?? DateTime.now();
    final picked = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: initial);
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = _ex;
    return Scaffold(
      appBar: AppBar(title: const Text('Excursion bearbeiten')),
      body: ex == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Titel'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null),
                  const SizedBox(height: 12),
                  ListTile(title: const Text('Datum'), subtitle: Text((_date ?? DateTime.now()).toLocal().toIso8601String().split('T').first), trailing: const Icon(Icons.edit_calendar), onTap: _pickDate),
                  const SizedBox(height: 12),
                  TextFormField(controller: _port, decoration: const InputDecoration(labelText: 'Hafen (optional)')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _meeting, decoration: const InputDecoration(labelText: 'Treffpunkt (optional)')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Notizen (optional)'), maxLines: 3),
                  const SizedBox(height: 12),
                  TextFormField(controller: _price, decoration: const InputDecoration(labelText: 'Preis (optional)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextFormField(controller: _currency, decoration: const InputDecoration(labelText: 'Währung (optional)')),
                  const SizedBox(height: 24),
                  FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Speichern')),
                ],
              ),
            ),
    );
  }
}
