// Regenerated screens v2 – ID-only navigation, aligned with current models.

import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/cruise.dart';
import '../../models/period.dart';
import '../../utils/format.dart';
import '../../l10n/app_localizations.dart';

class CruiseDetailsScreen extends StatefulWidget {
  final String cruiseId;
  const CruiseDetailsScreen({super.key, required this.cruiseId});

  @override
  State<CruiseDetailsScreen> createState() => _CruiseDetailsScreenState();
}

class _CruiseDetailsScreenState extends State<CruiseDetailsScreen> {
  Cruise? _cruise;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _shipName;
  late TextEditingController _shipOperator;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = CruiseStore();
    await s.load();
    final c = s.getCruise(widget.cruiseId);
    setState(() {
      _cruise = c;
      _title = TextEditingController(text: c?.title ?? '');
      _shipName = TextEditingController(text: c?.ship.name ?? '');
      _shipOperator = TextEditingController(text: c?.ship.operatorName ?? '');
      _start = c?.period.start;
      _end = c?.period.end;
    });
  }

  Future<void> _save() async {
    final c = _cruise;
    if (c == null) return;
    if (!_formKey.currentState!.validate()) return;
    final s = CruiseStore();
    await s.load();
    final next = c.copyWith(
      title: _title.text.trim(),
      ship: c.ship.copyWith(
        name: _shipName.text.trim(),
        operatorName: _shipOperator.text.trim().isEmpty ? null : _shipOperator.text.trim(),
      ),
      period: Period(start: _start ?? c.period.start, end: _end ?? c.period.end),
    );
    await s.upsertCruise(next);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _start : _end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = _cruise;
    return Scaffold(
      appBar: AppBar(title: Text(loc.cruiseDetails)),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(labelText: loc.title),
                    validator: (v) => (v == null || v.trim().isEmpty) ? loc.requiredField : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shipName,
                    decoration: InputDecoration(labelText: loc.ship),
                    validator: (v) => (v == null || v.trim().isEmpty) ? loc.requiredField : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shipOperator,
                    decoration: InputDecoration(labelText: loc.chatterOptional),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _DateTile(label: loc.start, date: _start, onTap: () => _pickDate(true))),
                    const SizedBox(width: 12),
                    Expanded(child: _DateTile(label: loc.end, date: _end, onTap: () => _pickDate(false))),
                  ]),
                  const SizedBox(height: 24),
                  FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Speichern')),
                ],
              ),
            ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final text = date == null ? '-' : fmtDate(context, date);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(text),
      trailing: const Icon(Icons.edit_calendar),
      onTap: onTap,
    );
  }
}
