import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/cruise.dart';
import '../../models/period.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';
import '../../widgets/documents/cruise_documents_section.dart';

class CruiseEditScreen extends StatefulWidget {
  const CruiseEditScreen({
    super.key,
    required this.cruiseId,
  });

  final String cruiseId;

  @override
  State<CruiseEditScreen> createState() => _CruiseEditScreenState();
}

class _CruiseEditScreenState extends State<CruiseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _shipName = TextEditingController();
  final _shipOperator = TextEditingController();
  final _cabinNumber = TextEditingController();
  final _deckNumber = TextEditingController();
  final _deckName = TextEditingController();

  Cruise? _cruise;
  DateTime? _start;
  DateTime? _end;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _shipName.dispose();
    _shipOperator.dispose();
    _cabinNumber.dispose();
    _deckNumber.dispose();
    _deckName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = CruiseStore();
    await store.load();
    final cruise = store.getCruise(widget.cruiseId);

    if (!mounted) {
      return;
    }

    setState(() {
      _cruise = cruise;
      _title.text = cruise?.title ?? '';
      _shipName.text = cruise?.ship.name ?? '';
      _shipOperator.text = cruise?.ship.operatorName ?? '';
      _cabinNumber.text = cruise?.cabinNumber ?? '';
      _deckNumber.text = cruise?.deckNumber ?? '';
      _deckName.text = cruise?.deckname ?? '';
      _start = cruise?.period.start;
      _end = cruise?.period.end;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final cruise = _cruise;
    if (cruise == null) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final store = CruiseStore();
    await store.load();
    final latestCruise = store.getCruise(widget.cruiseId) ?? cruise;
    final next = latestCruise.copyWith(
      title: _title.text.trim(),
      ship: latestCruise.ship.copyWith(
        name: _shipName.text.trim(),
        operatorName: _shipOperator.text.trim().isEmpty
            ? null
            : _shipOperator.text.trim(),
      ),
      period: Period(
        start: _start ?? latestCruise.period.start,
        end: _end ?? latestCruise.period.end,
      ),
      cabinNumber: _emptyToNull(_cabinNumber.text),
      deckNumber: _emptyToNull(_deckNumber.text),
      deckname: _emptyToNull(_deckName.text),
    );
    await store.upsertCruise(next);

    if (!mounted) {
      return;
    }

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
    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cruise = _cruise;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.editCruise)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (cruise == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.editCruise)),
        body: Center(child: Text(loc.cruise)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.editCruise)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: loc.title),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shipName,
              decoration: InputDecoration(labelText: loc.ship),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shipOperator,
              decoration: InputDecoration(labelText: loc.travelCompany),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cabinNumber,
              decoration: InputDecoration(labelText: loc.cabinNumber),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deckNumber,
              decoration: InputDecoration(labelText: loc.deckNumber),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deckName,
              decoration: InputDecoration(labelText: loc.deckname),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: loc.start,
                    date: _start,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: loc.end,
                    date: _end,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CruiseDocumentsSection(cruiseId: cruise.id),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(loc.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

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
