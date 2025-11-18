// RouteEditScreen – supports Date+Time and 'Alle Mann an Bord'; fixes getRef, mounted.
import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/route/route_item.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../utils/format.dart';
import '../../l10n/app_localizations.dart';

class RouteEditScreen extends StatefulWidget {
  final String routeItemId;
  final String cruiseId; // pass from list to avoid store lookup
  const RouteEditScreen({super.key, required this.routeItemId, required this.cruiseId});

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> {
  RouteItem? _item;
  final _portName = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _date; // anchor day
  DateTime? _arrival;
  DateTime? _departure;
  DateTime? _allAboard;

  bool get isPort => _item is PortCallItem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = CruiseStore();
    await s.load();
    final it = s.getById<RouteItem>(widget.routeItemId);
    if (!mounted) return;
    setState(() {
      _item = it;
      _date = it?.date;
      if (it is PortCallItem) {
        _portName.text = it.portName;
        _arrival = it.arrival;
        _departure = it.departure;
        _allAboard = it.allAboard;
        _notes.text = it.notes ?? '';
      } else if (it is SeaDayItem) {
        _notes.text = it.notes ?? '';
      }
    });
  }

  Future<void> _save() async {
    final it = _item;
    if (it == null) return;
    final s = CruiseStore();
    await s.load();
    late RouteItem next;
    if (it is PortCallItem) {
      next = it.copyWith(
        date: _date ?? it.date,
        portName: _portName.text.trim(),
        arrival: _arrival,
        departure: _departure,
        allAboard: _allAboard,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    } else if (it is SeaDayItem) {
      next = it.copyWith(
        date: _date ?? it.date,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    } else {
      return;
    }
    await s.upsertRouteItem(cruiseId: widget.cruiseId, item: next);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final base = _date ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) {
      setState(() => _date = DateTime(d.year, d.month, d.day));
    }
  }

  Future<void> _pickDateTime(String field) async {
    final current = {
      'arrival': _arrival,
      'departure': _departure,
      'allAboard': _allAboard,
    }[field];

    final baseDay = current ?? _date ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: baseDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? DateTime(baseDay.year, baseDay.month, baseDay.day, 18, 0)),
    );
    if (t == null) return;

    if (!mounted) return;
    setState(() {
      final combined = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      switch (field) {
        case 'arrival':
          _arrival = combined;
          break;
        case 'departure':
          _departure = combined;
          break;
        case 'allAboard':
          _allAboard = combined;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final it = _item;
    final loc = AppLocalizations.of(context)!;
    if (it == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(isPort ? loc.editPort : loc.editSeaDay)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(loc.date),
            subtitle: Text(fmtDate(context, _date)),
            leading: const Icon(Icons.event),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          if (isPort) ...[
            TextField(controller: _portName, decoration: InputDecoration(labelText: loc.harbour)),
            const SizedBox(height: 12),
            ListTile(
              title: Text('${loc.arrivalOptional} – ${loc.dateAndTime}'),
              subtitle: Text(fmtDate(context, _arrival, includeTime: true)),
              leading: const Icon(Icons.login),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => _pickDateTime('arrival'),
            ),
            ListTile(
              title: Text('${loc.departureOptional} – ${loc.dateAndTime}'),
              subtitle: Text(fmtDate(context, _departure, includeTime: true)),
              leading: const Icon(Icons.logout),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => _pickDateTime('departure'),
            ),
            ListTile(
              title: Text('${loc.allOnBoardOptional} – ${loc.dateAndTime}'),
              subtitle: Text(fmtDate(context, _allAboard, includeTime: true)),
              leading: const Icon(Icons.warning_amber_outlined),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => _pickDateTime('allAboard'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(controller: _notes, decoration: InputDecoration(labelText: loc.notesOptional), maxLines: 3),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(loc.save)),
        ],
      ),
    );
  }
}
