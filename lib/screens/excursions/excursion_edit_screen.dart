// Regenerated screens v2 – ID-only navigation, aligned with current models.

import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/excursion.dart';
import '../../utils/format.dart';
import '../../l10n/app_localizations.dart';

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
      _price = TextEditingController(text: fmtNumber(context, ex?.price));
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
      price: _price.text.trim().isEmpty ? null : parseLocalizedNumber(context, _price.text.trim()),
      currency: _currency.text.trim().isEmpty ? null : _currency.text.trim(),
    );
    final s = CruiseStore();
    await s.load();
    await s.upsertExcursion(cruiseId: cid, excursion: next);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickDateTime(bool start) async {
    final initial = DateTime.now();

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
    if (value != null) {
      setState(() => _date = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = _ex;
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.editExcursion)),
      body: ex == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(controller: _title, decoration: InputDecoration(labelText: loc.title), validator: (v) => (v == null || v.trim().isEmpty) ? loc.requiredField : null),
                  const SizedBox(height: 12),
                  ListTile(title: const Text('Datum'), subtitle: Text(fmtDate(context, _date, includeTime: true)), trailing: const Icon(Icons.edit_calendar), onTap: () => _pickDateTime(true)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _port, decoration: InputDecoration(labelText: loc.harbour)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _meeting, decoration: InputDecoration(labelText: loc.meetingPoint)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _notes, decoration: InputDecoration(labelText: loc.notesOptional), maxLines: 3),
                  const SizedBox(height: 12),
                  TextFormField(controller: _price, decoration: InputDecoration(labelText: loc.price), keyboardType: TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _currency, decoration: InputDecoration(labelText: loc.currencyOptional)),
                  const SizedBox(height: 24),
                  FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(loc.save)),
                ],
              ),
            ),
    );
  }
}
