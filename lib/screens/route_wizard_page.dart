// lib/screens/route_wizard_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';

import '../models/route_item.dart';

class RouteWizardPage extends StatefulWidget {
  final RouteItem? initial;
  const RouteWizardPage({super.key, this.initial});

  @override
  State<RouteWizardPage> createState() => _RouteWizardPageState();
}

class _RouteWizardPageState extends State<RouteWizardPage> {
  final _formKey = GlobalKey<FormState>();

  // State
  late bool _isSeaDay;

  // Gemeinsame Felder
  late DateTime _date;

  // PortCall Felder
  final _portNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _terminalCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TimeOfDay _arrival = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _departure = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.initial == null) {
      _isSeaDay = false;
      _date = DateTime(now.year, now.month, now.day);
    } else {
      _isSeaDay = widget.initial!.isSea;
      _date = DateTime(widget.initial!.date.year, widget.initial!.date.month, widget.initial!.date.day);
      if (widget.initial!.isPort) {
        final p = widget.initial as PortCallItem;
        _portNameCtrl.text = p.portName;
        _cityCtrl.text = p.city ?? '';
        _countryCtrl.text = p.country ?? '';
        _terminalCtrl.text = p.terminal ?? '';
        _descriptionCtrl.text = p.description ?? '';
        _notesCtrl.text = p.notes ?? '';
        _arrival = TimeOfDay(hour: p.arrival.hour, minute: p.arrival.minute);
        _departure = TimeOfDay(hour: p.departure.hour, minute: p.departure.minute);
      }
    }
  }

  @override
  void dispose() {
    _portNameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _terminalCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.yMMMMd(locale);

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.initial == null ? t.routeWizardNewTitle : t.routeWizardEditTitle),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Umschalter
              SwitchListTile(
                value: _isSeaDay,
                onChanged: (v) => setState(() => _isSeaDay = v),
                title: Text(t.routeWizardSwitchSeaDay),
              ),
              const SizedBox(height: 8),
              // Datum
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.routeDateLabel),
                subtitle: Text(dateFmt.format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const Divider(height: 24),

              if (!_isSeaDay) ...[
                // Zeiten
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.routeArrivalTimeLabel),
                        subtitle: Text(_arrival.format(context)),
                        trailing: const Icon(Icons.schedule),
                        onTap: () => _pickTime(isArrival: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.routeDepartureTimeLabel),
                        subtitle: Text(_departure.format(context)),
                        trailing: const Icon(Icons.schedule),
                        onTap: () => _pickTime(isArrival: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Pflichtfelder (mind. eins von beiden)
                TextFormField(
                  controller: _cityCtrl,
                  decoration: InputDecoration(labelText: t.routeCityLabel),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _portNameCtrl,
                  decoration: InputDecoration(labelText: t.routePortNameLabel),
                  validator: (v) {
                    if ((_cityCtrl.text.trim().isEmpty) && (v == null || v.trim().isEmpty)) {
                      return t.routeErrorCityOrPort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Optional
                TextFormField(
                  controller: _countryCtrl,
                  decoration: InputDecoration(labelText: t.routeCountryLabel),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _terminalCtrl,
                  decoration: InputDecoration(labelText: t.routeTerminalLabel),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: InputDecoration(labelText: t.routeDescriptionLabel),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(labelText: t.routeNotesLabel),
                  maxLines: 2,
                ),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text(t.routeCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSave,
                      child: Text(t.routeSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTime({required bool isArrival}) async {
    final initial = isArrival ? _arrival : _departure;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isArrival) {
          _arrival = picked;
        } else {
          _departure = picked;
        }
      });
    }
  }

  void _onSave() {
    if (!_isSeaDay && !_formKey.currentState!.validate()) return;

    final id = widget.initial?.id ?? const Uuid().v4();

    if (_isSeaDay) {
      final sea = SeaDayItem(id: id, date: _date);
      Navigator.of(context).pop<RouteItem>(sea);
      return;
    }

    // Arrival/Departure auf _date mappen
    DateTime _merge(TimeOfDay tod) => DateTime(_date.year, _date.month, _date.day, tod.hour, tod.minute);

    final port = PortCallItem(
      id: id,
      date: _date,
      portName: _portNameCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
      arrival: _merge(_arrival),
      departure: _merge(_departure),
      terminal: _terminalCtrl.text.trim().isEmpty ? null : _terminalCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    Navigator.of(context).pop<RouteItem>(port);
  }
}
