import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cruise.dart';
import '../models/ship.dart';
import '../models/period.dart';
import '../store/cruise_store.dart';

class CruiseDetailsPage extends StatefulWidget {
  final Cruise cruise;
  final CruiseStore store;
  const CruiseDetailsPage({super.key, required this.cruise, required this.store});

  @override
  State<CruiseDetailsPage> createState() => _CruiseDetailsPageState();
}

class _CruiseDetailsPageState extends State<CruiseDetailsPage> {
  late TextEditingController _title;
  late TextEditingController _ship;
  late TextEditingController _operator;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final c = widget.cruise;
    _title = TextEditingController(text: c.title);
    _ship = TextEditingController(text: c.ship.name);
    _operator = TextEditingController(text: c.ship.operatorName);
    _start = c.period.start;
    _end = c.period.end;
  }

  Future<void> _pick(bool start) async {
    final base = start ? _start : _end;
    final d = await showDatePicker(
      context: context,
      initialDate: base, firstDate: DateTime(2000), lastDate: DateTime(2100),
    );
    if (d == null) { return; }
    setState(() { if (start) _start = d; else _end = d; });
  }

  Future<void> _save() async {
    final updated = widget.cruise.copyWith(
      title: _title.text.trim().isEmpty ? 'Untitled' : _title.text.trim(),
      ship: Ship(name: _ship.text.trim(), operatorName: _operator.text.trim()),
      period: Period(start: _start, end: _end),
    );
    await widget.store.upsertCruise(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text('Cruise Details'), actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.check)),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: _ship, decoration: const InputDecoration(labelText: 'Ship name')),
          TextField(controller: _operator, decoration: const InputDecoration(labelText: 'Operator')),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Start date'),
            subtitle: Text(df.format(_start)),
            onTap: () => _pick(true),
          ),
          ListTile(
            title: const Text('End date'),
            subtitle: Text(df.format(_end)),
            onTap: () => _pick(false),
          ),
        ],
      ),
    );
  }
}
