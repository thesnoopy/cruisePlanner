import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:cruiseplanner/gen/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/travel.dart';

String _newId() => const Uuid().v4();
String _locale(BuildContext c) => Localizations.localeOf(c).toLanguageTag();
DateFormat _dateFmt(BuildContext c) => DateFormat.yMMMMd(_locale(c)).add_Hm();

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool optional;
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = _dateFmt(context);
    final text = value == null ? '—' : fmt.format(value!);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(text),
      trailing: IconButton(
        icon: const Icon(Icons.edit_calendar),
        onPressed: () async {
          final initial = value ?? DateTime.now();
          final d = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (d == null) {
            if (optional) onChanged(null);
            return;
          }
          final t = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(initial),
          );
          final selected = DateTime(
            d.year, d.month, d.day,
            (t?.hour ?? initial.hour),
            (t?.minute ?? initial.minute),
          );
          onChanged(selected);
        },
      ),
    );
  }
}

/// ---------- PUBLIC HELPERS ----------
Future<TravelItem?> openCreateWizard(BuildContext context, TravelKind kind) {
  switch (kind) {
    case TravelKind.flight:
      return Navigator.of(context).push(MaterialPageRoute(builder: (_) => FlightWizardPage()));
    case TravelKind.train:
      return Navigator.of(context).push(MaterialPageRoute(builder: (_) => TrainWizardPage()));
    case TravelKind.transfer:
      return Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransferWizardPage()));
    case TravelKind.rentalCar:
      return Navigator.of(context).push(MaterialPageRoute(builder: (_) => RentalCarWizardPage()));
  }
}

Future<TravelItem?> openEditWizard(BuildContext context, TravelItem item) {
  switch (item.type) {
    case TravelKind.flight:
      return Navigator.of(context).push(MaterialPageRoute(builder: (_) => FlightWizardPage(initial: item as FlightItem)));
    case TravelKind.train:
      return Navigator.of(context).push(MaterialPageRoute(builder: (_) => TrainWizardPage(initial: item as TrainItem)));
    case TravelKind.transfer:
      return Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransferWizardPage(initial: item as TransferItem)));
    case TravelKind.rentalCar:
      return Navigator.of(context).push(MaterialPageRoute(builder: (_) => RentalCarWizardPage(initial: item as RentalCarItem)));
  }
}

class _WizardScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  const _WizardScaffold({
    required this.title,
    required this.child,
    required this.onSave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onDelete != null)
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: t.action_delete, onPressed: onDelete),
          IconButton(icon: const Icon(Icons.check), tooltip: t.action_save, onPressed: onSave),
        ],
      ),
      body: SafeArea(minimum: const EdgeInsets.all(16), child: child),
    );
  }
}

/// ---------- Flight ----------
class FlightWizardPage extends StatefulWidget {
  final FlightItem? initial;
  const FlightWizardPage({super.key, this.initial});
  @override
  State<FlightWizardPage> createState() => _FlightWizardPageState();
}
class _FlightWizardPageState extends State<FlightWizardPage> {
  final _form = GlobalKey<FormState>();
  late DateTime _start; DateTime? _end;
  final _from = TextEditingController(), _to = TextEditingController();
  final _airline = TextEditingController(), _flightNo = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _start = i?.start ?? DateTime.now(); _end = i?.end;
    _from.text = i?.from ?? ''; _to.text = i?.to ?? '';
    _airline.text = i?.airline ?? ''; _flightNo.text = i?.flightNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _WizardScaffold(
      title: t.travelKind_flight,
      onSave: _save,
      onDelete: widget.initial == null ? null : () => Navigator.pop<TravelItem?>(context, null),
      child: Form(
        key: _form,
        child: ListView(
          children: [
            _DateTimeField(label: t.label_start, value: _start, onChanged: (v) => setState(() => _start = v ?? _start)),
            _DateTimeField(label: t.label_end, value: _end, onChanged: (v) => setState(() => _end = v), optional: true),
            TextFormField(controller: _from, decoration: InputDecoration(labelText: t.label_from)),
            TextFormField(controller: _to, decoration: InputDecoration(labelText: t.label_to)),
            TextFormField(controller: _airline, decoration: InputDecoration(labelText: t.flight_airline)),
            TextFormField(
              controller: _flightNo,
              decoration: InputDecoration(labelText: t.flight_number),
              validator: (v) => (v == null || v.trim().isEmpty) ? t.error_required : null,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      FlightItem(
        id: widget.initial?.id ?? _newId(),
        start: _start, end: _end,
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to: _to.text.trim().isEmpty ? null : _to.text.trim(),
        airline: _airline.text.trim().isEmpty ? '—' : _airline.text.trim(),
        flightNumber: _flightNo.text.trim().isEmpty ? '—' : _flightNo.text.trim(),
      ),
    );
  }
}

/// ---------- Train ----------
class TrainWizardPage extends StatefulWidget {
  final TrainItem? initial;
  const TrainWizardPage({super.key, this.initial});
  @override
  State<TrainWizardPage> createState() => _TrainWizardPageState();
}
class _TrainWizardPageState extends State<TrainWizardPage> {
  final _form = GlobalKey<FormState>();
  late DateTime _start; DateTime? _end;
  final _from = TextEditingController(), _to = TextEditingController();
  final _op = TextEditingController(), _trainNo = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _start = i?.start ?? DateTime.now(); _end = i?.end;
    _from.text = i?.from ?? ''; _to.text = i?.to ?? '';
    _op.text = i?.operatorName ?? ''; _trainNo.text = i?.trainNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _WizardScaffold(
      title: t.travelKind_train,
      onSave: _save,
      onDelete: widget.initial == null ? null : () => Navigator.pop<TravelItem?>(context, null),
      child: Form(
        key: _form,
        child: ListView(
          children: [
            _DateTimeField(label: t.label_start, value: _start, onChanged: (v) => setState(() => _start = v ?? _start)),
            _DateTimeField(label: t.label_end, value: _end, onChanged: (v) => setState(() => _end = v), optional: true),
            TextFormField(controller: _from, decoration: InputDecoration(labelText: t.label_from)),
            TextFormField(controller: _to, decoration: InputDecoration(labelText: t.label_to)),
            TextFormField(controller: _op, decoration: InputDecoration(labelText: t.train_operator)),
            TextFormField(
              controller: _trainNo,
              decoration: InputDecoration(labelText: t.train_number),
              validator: (v) => (v == null || v.trim().isEmpty) ? t.error_required : null,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      TrainItem(
        id: widget.initial?.id ?? _newId(),
        start: _start, end: _end,
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to: _to.text.trim().isEmpty ? null : _to.text.trim(),
        operatorName: _op.text.trim().isEmpty ? '—' : _op.text.trim(),
        trainNumber: _trainNo.text.trim().isEmpty ? '—' : _trainNo.text.trim(),
      ),
    );
  }
}

/// ---------- Transfer ----------
class TransferWizardPage extends StatefulWidget {
  final TransferItem? initial;
  const TransferWizardPage({super.key, this.initial});
  @override
  State<TransferWizardPage> createState() => _TransferWizardPageState();
}
class _TransferWizardPageState extends State<TransferWizardPage> {
  final _form = GlobalKey<FormState>();
  late DateTime _start; DateTime? _end;
  final _from = TextEditingController(), _to = TextEditingController();
  final _provider = TextEditingController();
  TransferMode _mode = TransferMode.shuttle;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _start = i?.start ?? DateTime.now(); _end = i?.end;
    _from.text = i?.from ?? ''; _to.text = i?.to ?? '';
    _provider.text = i?.provider ?? '';
    _mode = i?.mode ?? TransferMode.shuttle;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _WizardScaffold(
      title: t.travelKind_transfer,
      onSave: _save,
      onDelete: widget.initial == null ? null : () => Navigator.pop<TravelItem?>(context, null),
      child: Form(
        key: _form,
        child: ListView(
          children: [
            _DateTimeField(label: t.label_start, value: _start, onChanged: (v) => setState(() => _start = v ?? _start)),
            _DateTimeField(label: t.label_end, value: _end, onChanged: (v) => setState(() => _end = v), optional: true),
            TextFormField(controller: _from, decoration: InputDecoration(labelText: t.label_from)),
            TextFormField(controller: _to, decoration: InputDecoration(labelText: t.label_to)),
            TextFormField(
              controller: _provider,
              decoration: InputDecoration(labelText: t.transfer_provider),
              validator: (v) => (v == null || v.trim().isEmpty) ? t.error_required : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TransferMode>(
              value: _mode,
              items: TransferMode.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
              onChanged: (v) => setState(() => _mode = v ?? TransferMode.shuttle),
              decoration: InputDecoration(labelText: t.travelKind_transfer),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      TransferItem(
        id: widget.initial?.id ?? _newId(),
        start: _start, end: _end,
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to: _to.text.trim().isEmpty ? null : _to.text.trim(),
        provider: _provider.text.trim().isEmpty ? '—' : _provider.text.trim(),
        mode: _mode,
      ),
    );
  }
}

/// ---------- Rental Car ----------
class RentalCarWizardPage extends StatefulWidget {
  final RentalCarItem? initial;
  const RentalCarWizardPage({super.key, this.initial});
  @override
  State<RentalCarWizardPage> createState() => _RentalCarWizardPageState();
}
class _RentalCarWizardPageState extends State<RentalCarWizardPage> {
  final _form = GlobalKey<FormState>();
  late DateTime _start; late DateTime _end;
  final _pickup = TextEditingController(), _dropoff = TextEditingController();
  final _company = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    final now = DateTime.now();
    _start = i?.start ?? now;
    _end = i?.end ?? now.add(const Duration(days: 3));
    _pickup.text = i?.pickupLocation ?? i?.from ?? '';
    _dropoff.text = i?.dropoffLocation ?? i?.to ?? '';
    _company.text = i?.company ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _WizardScaffold(
      title: t.travelKind_rentalCar,
      onSave: _save,
      onDelete: widget.initial == null ? null : () => Navigator.pop<TravelItem?>(context, null),
      child: Form(
        key: _form,
        child: ListView(
          children: [
            _DateTimeField(label: t.label_start, value: _start, onChanged: (v) => setState(() => _start = v ?? _start)),
            _DateTimeField(label: t.label_end, value: _end, onChanged: (v) => setState(() => _end = v ?? _end)),
            TextFormField(controller: _pickup, decoration: InputDecoration(labelText: t.rental_pickupLocation)),
            TextFormField(controller: _dropoff, decoration: InputDecoration(labelText: t.rental_dropoffLocation)),
            TextFormField(
              controller: _company,
              decoration: InputDecoration(labelText: t.rental_company),
              validator: (v) => (v == null || v.trim().isEmpty) ? t.error_required : null,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final t = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.error_endBeforeStart)));
      return;
    }
    Navigator.pop(
      context,
      RentalCarItem(
        id: widget.initial?.id ?? _newId(),
        start: _start, end: _end,
        from: _pickup.text.trim().isEmpty ? null : _pickup.text.trim(),
        to: _dropoff.text.trim().isEmpty ? null : _dropoff.text.trim(),
        company: _company.text.trim().isEmpty ? '—' : _company.text.trim(),
        pickupLocation: _pickup.text.trim().isEmpty ? null : _pickup.text.trim(),
        dropoffLocation: _dropoff.text.trim().isEmpty ? null : _dropoff.text.trim(),
      ),
    );
  }
}
