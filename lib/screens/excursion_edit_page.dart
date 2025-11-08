import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/excursion.dart';

class ExcursionEditPage extends StatefulWidget {
  final Excursion? initial;
  const ExcursionEditPage({super.key, this.initial});

  @override
  State<ExcursionEditPage> createState() => _ExcursionEditPageState();
}

class _ExcursionEditPageState extends State<ExcursionEditPage> {
  final _title = TextEditingController();
  final _port = TextEditingController();
  final _meeting = TextEditingController();
  final _notes = TextEditingController();
  final _price = TextEditingController();
  final _currency = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (e != null) {
      _title.text = e.title;
      _port.text = e.port ?? '';
      _meeting.text = e.meetingPoint ?? '';
      _notes.text = e.notes ?? '';
      _price.text = e.price?.toString() ?? '';
      _currency.text = e.currency ?? '';
      _date = e.date;
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(()=>_date = d);
  }

  void _save() {
    final x = Excursion(
      id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title.text.trim().isEmpty ? 'Excursion' : _title.text.trim(),
      date: _date,
      port: _port.text.trim().isEmpty ? null : _port.text.trim(),
      meetingPoint: _meeting.text.trim().isEmpty ? null : _meeting.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      price: _price.text.trim().isEmpty ? null : num.tryParse(_price.text.trim()),
      currency: _currency.text.trim().isEmpty ? null : _currency.text.trim(),
    );
    Navigator.pop(context, x);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Excursion'), actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.check)),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          ListTile(title: const Text('Date'), subtitle: Text(df.format(_date)), onTap: _pickDate),
          TextField(controller: _port, decoration: const InputDecoration(labelText: 'Port (optional)')),
          TextField(controller: _meeting, decoration: const InputDecoration(labelText: 'Meeting point (optional)')),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price (optional)'), keyboardType: TextInputType.number),
          TextField(controller: _currency, decoration: const InputDecoration(labelText: 'Currency (optional)')),
        ],
      ),
    );
  }
}
