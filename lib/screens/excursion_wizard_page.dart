import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/cruise.dart';
import '../../models/excursion.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';


class ExcursionWizardPage extends StatefulWidget {
  final Cruise cruise;
  final Excursion? initial; // null => neu, sonst edit

  const ExcursionWizardPage({
    super.key,
    required this.cruise,
    this.initial,
  });

  @override
  State<ExcursionWizardPage> createState() => _ExcursionWizardPageState();
}

class _ExcursionWizardPageState extends State<ExcursionWizardPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _meetingPointCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _currencyCtrl;

  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _portCtrl = TextEditingController(text: e?.port ?? '');
    _meetingPointCtrl = TextEditingController(text: e?.meetingPoint ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _priceCtrl = TextEditingController(text: e?.price?.toString() ?? '');
    _currencyCtrl = TextEditingController(text: e?.currency ?? '');
    _date = e?.date ?? widget.cruise.period.start;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _portCtrl.dispose();
    _meetingPointCtrl.dispose();
    _notesCtrl.dispose();
    _priceCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final period = widget.cruise.period;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: period.start,
      lastDate: period.end,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

void _save() {
  final t = AppLocalizations.of(context)!;
  if (!_formKey.currentState!.validate()) return;

  // --- NEU: Locale-aware Parsing -------------------------------------------
  final raw = _priceCtrl.text.trim();

  num? price;
  if (raw.isEmpty) {
    price = null;
  } else {
    final locale = Localizations.localeOf(context).toString();
    final f = NumberFormat.decimalPattern(locale);
    final symbols = f.symbols;

    // NBSP -> Space; Tausendertrennzeichen entfernen; nur Ziffern, Dezimal- und Minus behalten
    final cleaned = raw
        .replaceAll('\u00A0', ' ')
        .replaceAll(symbols.GROUP_SEP, '')
        .replaceAll(RegExp('[^0-9${RegExp.escape(symbols.DECIMAL_SEP)}-]'), '');

    try {
      price = f.parse(cleaned); // versteht Komma/Punkt je nach Locale
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.invalidPrice)),
      );
      return;
    }

    // optional: keine negativen Preise erlauben
    if (price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.invalidPrice)),
      );
      return;
    }
  }

    final excursion = (widget.initial ?? Excursion(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      date: _date,
    )).copyWith(
      title: _titleCtrl.text.trim(),
      date: _date,
      port: _portCtrl.text.trim().isEmpty ? null : _portCtrl.text.trim(),
      meetingPoint: _meetingPointCtrl.text.trim().isEmpty ? null : _meetingPointCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      price: price,
      currency: _currencyCtrl.text.trim().isEmpty
        ? null
        : _currencyCtrl.text.trim().toUpperCase(),
    );
    Navigator.of(context).pop<Excursion>(excursion); 
  }

  String _formatDate(DateTime d) => DateFormat.yMMMd().format(d);

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final period = widget.cruise.period;
    final translations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final symbols = NumberFormat.decimalPattern(locale).symbols;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? translations.changeExcursion : translations.createExcursion),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: translations.titleStar,
                  hintText: translations.titelStarHintText,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? translations.titleMustNotBeEmpty : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text( '${translations.dateLabel} ${_formatDate(_date)}'),
                subtitle: Text(
                  '${translations.mustBeBetween} ${_formatDate(period.start)} ${translations.and} ${_formatDate(period.end)} ${translations.lie}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _portCtrl,
                decoration: InputDecoration(
                  labelText: translations.harbourOptional,
                  hintText: translations.harbourOptionalHintText,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _meetingPointCtrl,
                decoration: InputDecoration(
                  labelText: translations.meetingPoint,
                  hintText: translations.meetingPointHintText,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: translations.notesOptional,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: translations.priceOptional,
                  hintText: translations.priceOptionalHintText,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                  RegExp('[0-9${RegExp.escape(symbols.DECIMAL_SEP)}${RegExp.escape(symbols.GROUP_SEP)}\\u00A0]'),
                  ),
                ],
                validator: (txt) {
                  final v = (txt ?? '').trim();
                  if (v.isEmpty) return null; // optionales Feld
                  try {
                    // nutzt dein locales Parsing – kurz & robust:
                    final f = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
                    final s = f.symbols;
                    final cleaned = v
                        .replaceAll('\u00A0', ' ')
                        .replaceAll(s.GROUP_SEP, '')
                        .replaceAll(RegExp('[^0-9${RegExp.escape(s.DECIMAL_SEP)}-]'), '');
                    f.parse(cleaned);
                    return null;
                  } catch (_) {
                    return translations.invalidPrice;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currencyCtrl,
                decoration: InputDecoration(
                  labelText: translations.currencyOptional,
                  hintText: translations.currencyOptionalHintText,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(isEdit ? translations.store : translations.create),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
