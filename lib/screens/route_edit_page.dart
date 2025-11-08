import 'package:flutter/material.dart';
import '../models/route/route_item.dart';
import '../models/route/port_call_item.dart';
import '../models/route/sea_day_item.dart';

class RouteEditPage extends StatefulWidget {
  final RouteItem? initial;
  const RouteEditPage({super.key, this.initial});

  @override
  State<RouteEditPage> createState() => _RouteEditPageState();
}

class _RouteEditPageState extends State<RouteEditPage> {
  bool _isPort = true;
  final _portName = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _arrival;
  DateTime? _departure;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i is PortCallItem) {
      _isPort = true;
      _portName.text = i.portName;
      _date = i.date;
      _arrival = i.arrival;
      _departure = i.departure;
      _notes.text = i.notes ?? '';
    } else if (i is SeaDayItem) {
      _isPort = false;
      _date = i.date;
      _notes.text = i.notes ?? '';
    }
  }

  Future<DateTime?> _pickDateTime(DateTime? base) async {
    final now = base ?? DateTime.now();
    final d = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d == null) return null;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    return DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
  }

  void _save() {
    if (_isPort) {
      final item = PortCallItem(
        id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: _date,
        portName: _portName.text.trim().isEmpty ? 'Port' : _portName.text.trim(),
        arrival: _arrival,
        departure: _departure,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      Navigator.pop<RouteItem>(context, item);
    } else {
      final item = SeaDayItem(
        id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: _date,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      Navigator.pop<RouteItem>(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Route Item'), actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.check)),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Port call'),
            value: _isPort,
            onChanged: (v) => setState(() => _isPort = v),
          ),
          ListTile(
            title: const Text('Date'),
            subtitle: Text(_date.toString()),
            onTap: () async { final d = await _pickDateTime(_date); if (!mounted) return; if (d != null) setState(()=>_date = d); },
          ),
          if (_isPort) ...[
            TextField(controller: _portName, decoration: const InputDecoration(labelText: 'Port name')),
            ListTile(
              title: const Text('Arrival (optional)'),
              subtitle: Text(_arrival?.toString() ?? '—'),
              onTap: () async { final d = await _pickDateTime(_arrival ?? _date); if (!mounted) return; setState(()=>_arrival = d); },
            ),
            ListTile(
              title: const Text('Departure (optional)'),
              subtitle: Text(_departure?.toString() ?? '—'),
              onTap: () async { final d = await _pickDateTime(_departure ?? _date); if (!mounted) return; setState(()=>_departure = d); },
            ),
          ],
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        ],
      ),
    );
  }
}
