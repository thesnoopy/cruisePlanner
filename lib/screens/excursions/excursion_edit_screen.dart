// ExcursionEditScreen mit Payment-Plan Bearbeitung.

import 'package:flutter/material.dart';

import '../../store/cruise_store.dart';
import '../../models/excursion.dart';
import '../../models/excursions/excursion_payment_mode.dart';
import '../../models/excursions/excursion_payment_plan.dart';
import '../../models/excursions/excursion_payment_part.dart';
import '../../models/excursions/excursion_payment_trigger.dart';
import '../../models/excursions/excursion_payment_method.dart';
import '../../models/excursions/cash_currency_preference.dart';
import '../../utils/format.dart';
import '../../l10n/app_localizations.dart';

class ExcursionEditScreen extends StatefulWidget {
  final String excursionId;

  const ExcursionEditScreen({
    super.key,
    required this.excursionId,
  });

  @override
  State<ExcursionEditScreen> createState() => _ExcursionEditScreenState();
}

class _ExcursionEditScreenState extends State<ExcursionEditScreen> {
  final _formKey = GlobalKey<FormState>();

  Excursion? _ex;
  String? _cruiseId;

  // Basis-Felder
  final _title = TextEditingController();
  DateTime? _date;
  final _port = TextEditingController();
  final _meeting = TextEditingController();
  final _notes = TextEditingController();
  final _price = TextEditingController();
  final _currency = TextEditingController();

  // Payment-State (max. 2 Teile: Anzahlung + Rest)
  ExcursionPaymentMode _paymentMode = ExcursionPaymentMode.fullOnBooking;

  // Teil 1 (immer vorhanden)
  bool _part1Paid = false;

  // Teil 2 (nur bei den 3 Modi mit zweitem Teil)
  final _depositAmount = TextEditingController(); // Anzahlung
  final _restAmount = TextEditingController();    // Restbetrag (optional, sonst auto)
  DateTime? _restDueDate;
  bool _depositPaid = false;
  bool _restPaid = false;

  // Vor-Ort-Infos
  bool _onSiteCash = true;
  bool _onSiteCard = false;
  CashCurrencyPreference _cashPref = CashCurrencyPreference.localOnly;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _port.dispose();
    _meeting.dispose();
    _notes.dispose();
    _price.dispose();
    _currency.dispose();
    _depositAmount.dispose();
    _restAmount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = CruiseStore();
    await store.load();

    Excursion? ex;
    String? cruiseId;

    // Finde Excursion + zugehörige Cruise
    outer:
    for (final c in store.cruises) {
      for (final e in c.excursions) {
        if (e.id == widget.excursionId) {
          ex = e;
          cruiseId = c.id;
          break outer;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _ex = ex;
      _cruiseId = cruiseId;
    });

    if (ex == null) return;

    final context = this.context;
    _title.text = ex.title;
    _date = ex.date;
    _port.text = ex.port ?? '';
    _meeting.text = ex.meetingPoint ?? '';
    _notes.text = ex.notes ?? '';
    _price.text = fmtNumber(context, ex.price);
    _currency.text = ex.currency ?? '';

    _initPaymentFromExcursion(ex);
  }

  void _initPaymentFromExcursion(Excursion ex) {
    final plan = ex.paymentPlan;
    final totalPrice = (ex.price ?? 0).toDouble();

    if (plan == null || plan.parts.isEmpty) {
      _paymentMode = ExcursionPaymentMode.fullOnBooking;
      _part1Paid = false;
      _depositAmount.text = '';
      _restAmount.text = '';
      _restDueDate = null;
      _depositPaid = false;
      _restPaid = false;
      _onSiteCash = true;
      _onSiteCard = false;
      _cashPref = CashCurrencyPreference.localOnly;
      return;
    }

    _paymentMode = plan.mode;

    ExcursionPaymentPart? partOnBooking;
    ExcursionPaymentPart? partBeforeDate;
    ExcursionPaymentPart? partOnSite;

    for (final p in plan.parts) {
      switch (p.trigger) {
        case ExcursionPaymentTrigger.onBooking:
          partOnBooking = p;
          break;
        case ExcursionPaymentTrigger.beforeDate:
          partBeforeDate = p;
          break;
        case ExcursionPaymentTrigger.onSite:
          partOnSite = p;
          break;
      }
    }

    switch (plan.mode) {
      case ExcursionPaymentMode.fullOnBooking:
        final p = partOnBooking ??
            ExcursionPaymentPart(
              trigger: ExcursionPaymentTrigger.onBooking,
              amount: totalPrice,
            );
        _part1Paid = p.isPaid;
        break;

      case ExcursionPaymentMode.depositAndRestDate:
        final deposit = partOnBooking;
        final rest = partBeforeDate;

        _depositAmount.text =
            deposit != null ? fmtNumber(context, deposit.amount) : '';
        _restAmount.text =
            rest != null ? fmtNumber(context, rest.amount) : '';
        _restDueDate = rest?.dueDate;
        _depositPaid = deposit?.isPaid ?? false;
        _restPaid = rest?.isPaid ?? false;
        _part1Paid = false; // wird hier nicht genutzt
        break;

      case ExcursionPaymentMode.depositAndRestOnSite:
        final deposit2 = partOnBooking;
        final rest2 = partOnSite;

        _depositAmount.text =
            deposit2 != null ? fmtNumber(context, deposit2.amount) : '';
        _restAmount.text =
            rest2 != null ? fmtNumber(context, rest2.amount) : '';
        _depositPaid = deposit2?.isPaid ?? false;
        _restPaid = rest2?.isPaid ?? false;

        final methods = rest2?.paymentMethods ?? {};
        _onSiteCash = methods.contains(ExcursionPaymentMethod.cash);
        _onSiteCard = methods.contains(ExcursionPaymentMethod.creditCard);
        _cashPref = rest2?.cashCurrencyPreference ??
            CashCurrencyPreference.localOnly;
        _part1Paid = false;
        break;

      case ExcursionPaymentMode.fullOnSite:
        final p = partOnSite ??
            ExcursionPaymentPart(
              trigger: ExcursionPaymentTrigger.onSite,
              amount: totalPrice,
            );
        _part1Paid = p.isPaid;
        final methods = p.paymentMethods;
        _onSiteCash = methods.contains(ExcursionPaymentMethod.cash) ||
            methods.isEmpty;
        _onSiteCard = methods.contains(ExcursionPaymentMethod.creditCard);
        _cashPref = p.cashCurrencyPreference ??
            CashCurrencyPreference.localOnly;
        break;
    }
  }

  Future<void> _pickDateTime() async {
    final base = _date ?? DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _date ?? DateTime(base.year, base.month, base.day, 9, 0),
      ),
    );
    if (t == null) return;

    if (!mounted) return;
    setState(() {
      _date = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _pickRestDueDate() async {
    final base = _restDueDate ?? _date ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    if (!mounted) return;
    setState(() {
      _restDueDate = DateTime(d.year, d.month, d.day);
    });
  }

  ExcursionPaymentPlan _buildPaymentPlan(double totalPrice) {
    switch (_paymentMode) {
      case ExcursionPaymentMode.fullOnBooking:
        return ExcursionPaymentPlan(
          mode: _paymentMode,
          parts: [
            ExcursionPaymentPart(
              trigger: ExcursionPaymentTrigger.onBooking,
              amount: totalPrice,
              isPaid: _part1Paid,
            ),
          ],
        );

      case ExcursionPaymentMode.depositAndRestDate:
        final deposit =
            parseLocalizedNumber(context, _depositAmount.text) ?? 0;
        final restExplicit =
            parseLocalizedNumber(context, _restAmount.text);
        final rest =
            restExplicit ?? (totalPrice - deposit).clamp(0, double.infinity);
        return ExcursionPaymentPlan(
          mode: _paymentMode,
          parts: [
            ExcursionPaymentPart(
              trigger: ExcursionPaymentTrigger.onBooking,
              amount: deposit.toDouble(),
              isPaid: _depositPaid,
            ),
            ExcursionPaymentPart(
              trigger: ExcursionPaymentTrigger.beforeDate,
              amount: rest.toDouble(),
              isPaid: _restPaid,
              dueDate: _restDueDate,
            ),
          ],
        );

      case ExcursionPaymentMode.depositAndRestOnSite:
        final deposit =
            parseLocalizedNumber(context, _depositAmount.text) ?? 0;
        final restExplicit =
            parseLocalizedNumber(context, _restAmount.text);
        final rest =
            restExplicit ?? (totalPrice - deposit).clamp(0, double.infinity);

        final methods = <ExcursionPaymentMethod>{};
        if (_onSiteCash) methods.add(ExcursionPaymentMethod.cash);
        if (_onSiteCard) methods.add(ExcursionPaymentMethod.creditCard);

        return ExcursionPaymentPlan(
          mode: _paymentMode,
          parts: [
            ExcursionPaymentPart(
              trigger: ExcursionPaymentTrigger.onBooking,
              amount: deposit.toDouble(),
              isPaid: _depositPaid,
            ),
            ExcursionPaymentPart(
              trigger: ExcursionPaymentTrigger.onSite,
              amount: rest.toDouble(),
              isPaid: _restPaid,
              paymentMethods: methods,
              cashCurrencyPreference: methods.contains(
                      ExcursionPaymentMethod.cash)
                  ? _cashPref
                  : null,
            ),
          ],
        );

      case ExcursionPaymentMode.fullOnSite:
        final methods = <ExcursionPaymentMethod>{};
        if (_onSiteCash) methods.add(ExcursionPaymentMethod.cash);
        if (_onSiteCard) methods.add(ExcursionPaymentMethod.creditCard);

        return ExcursionPaymentPlan(
          mode: _paymentMode,
          parts: [
            ExcursionPaymentPart(
              trigger: ExcursionPaymentTrigger.onSite,
              amount: totalPrice,
              isPaid: _part1Paid,
              paymentMethods: methods,
              cashCurrencyPreference: methods.contains(
                      ExcursionPaymentMethod.cash)
                  ? _cashPref
                  : null,
            ),
          ],
        );
    }
  }

  Future<void> _save() async {
    final ex = _ex;
    final cid = _cruiseId;
    if (ex == null || cid == null) return;
    if (!_formKey.currentState!.validate()) return;

    final priceValue = _price.text.isEmpty
        ? null
        : parseLocalizedNumber(context, _price.text);
    final totalPrice = (priceValue ?? 0).toDouble();

    final plan = _buildPaymentPlan(totalPrice);

    final updated = Excursion(
      id: ex.id,
      title: _title.text.trim(),
      date: _date ?? ex.date,
      port: _port.text.trim().isEmpty ? null : _port.text.trim(),
      meetingPoint:
          _meeting.text.trim().isEmpty ? null : _meeting.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      price: priceValue,
      currency:
          _currency.text.trim().isEmpty ? null : _currency.text.trim(),
      paymentPlan: plan,
    );

    final store = CruiseStore();
    await store.load();
    await store.upsertExcursion(cruiseId: cid, excursion: updated);

    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildPaymentSection(BuildContext context) {
    final theme = Theme.of(context);
		final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.payment,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExcursionPaymentMode>(
              value: _paymentMode,
              decoration: InputDecoration(
                labelText: loc.paymentType,
              ),
              items: [
                DropdownMenuItem(
                  value: ExcursionPaymentMode.fullOnBooking,
                  child: Text(loc.payOnBooking),
                ),
                DropdownMenuItem(
                  value: ExcursionPaymentMode.depositAndRestDate,
                  child: Text('${loc.deposit} + ${loc.finalPaymentOnDate}'),
                ),
                DropdownMenuItem(
                  value: ExcursionPaymentMode.depositAndRestOnSite,
                  child: Text('${loc.deposit} + ${loc.finalPaymentOnSide}'),
                ),
                DropdownMenuItem(
                  value: ExcursionPaymentMode.fullOnSite,
                  child: Text(loc.amountPayableOnSide),
                ),
              ],
              onChanged: (m) {
                if (m == null) return;
                setState(() => _paymentMode = m);
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context) {
		final loc = AppLocalizations.of(context)!;
    switch (_paymentMode) {
      case ExcursionPaymentMode.fullOnBooking:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.amountAlreadyPayed),
              value: _part1Paid,
              onChanged: (v) =>
                  setState(() => _part1Paid = v ?? false),
            ),
          ],
        );

      case ExcursionPaymentMode.depositAndRestDate:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _depositAmount,
              decoration:
                  InputDecoration(labelText: loc.deposit),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.depositAlreadyPayed),
              value: _depositPaid,
              onChanged: (v) =>
                  setState(() => _depositPaid = v ?? false),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _restAmount,
              decoration: InputDecoration(
                labelText: loc.remainingAmountOptional,
                helperText:
                    loc.leaveEmptyForAutomaticCalculation,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.remainingAmountDueUntill),
              subtitle: Text(
                _restDueDate == null
                    ? loc.noDateSelected
                    : fmtDate(context, _restDueDate),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickRestDueDate,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.remainingAmountAlreadyPaied),
              value: _restPaid,
              onChanged: (v) =>
                  setState(() => _restPaid = v ?? false),
            ),
          ],
        );

      case ExcursionPaymentMode.depositAndRestOnSite:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _depositAmount,
              decoration:
                  InputDecoration(labelText: loc.deposit),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.depositAlreadyPayed),
              value: _depositPaid,
              onChanged: (v) =>
                  setState(() => _depositPaid = v ?? false),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _restAmount,
              decoration: InputDecoration(
                labelText: loc.remainingAmountOnSide,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.paymentTypesOnSide,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.cash),
              value: _onSiteCash,
              onChanged: (v) =>
                  setState(() => _onSiteCash = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.credit),
              value: _onSiteCard,
              onChanged: (v) =>
                  setState(() => _onSiteCard = v ?? false),
            ),
            if (_onSiteCash) ...[
              const SizedBox(height: 4),
              Text(loc.cashCurrency),
              RadioListTile<CashCurrencyPreference>(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.onlyLocalCurrency),
                value: CashCurrencyPreference.localOnly,
                groupValue: _cashPref,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _cashPref = v);
                },
              ),
              RadioListTile<CashCurrencyPreference>(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.localCurrencyOrOwnCurrency),
                value: CashCurrencyPreference.localOrHome,
                groupValue: _cashPref,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _cashPref = v);
                },
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.finalPaymentAlreadyPayed),
              value: _restPaid,
              onChanged: (v) =>
                  setState(() => _restPaid = v ?? false),
            ),
          ],
        );

      case ExcursionPaymentMode.fullOnSite:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.fullPaymentOnSide}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              loc.paymentTypesOnSide,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.cash),
              value: _onSiteCash,
              onChanged: (v) =>
                  setState(() => _onSiteCash = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.credit),
              value: _onSiteCard,
              onChanged: (v) =>
                  setState(() => _onSiteCard = v ?? false),
            ),
            if (_onSiteCash) ...[
              const SizedBox(height: 4),
              Text(loc.cashCurrency),
              RadioListTile<CashCurrencyPreference>(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.onlyLocalCurrency),
                value: CashCurrencyPreference.localOnly,
                groupValue: _cashPref,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _cashPref = v);
                },
              ),
              RadioListTile<CashCurrencyPreference>(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.localCurrencyOrOwnCurrency),
                value: CashCurrencyPreference.localOrHome,
                groupValue: _cashPref,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _cashPref = v);
                },
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.amountAlreadyPayed),
              value: _part1Paid,
              onChanged: (v) =>
                  setState(() => _part1Paid = v ?? false),
            ),
          ],
        );
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
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(labelText: loc.excursion),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? loc.requiredField
                        : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: Text(loc.dateAndTime),
                    subtitle: Text(
                      fmtDate(context, _date, includeTime: true),
                    ),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _port,
                    decoration: InputDecoration(
                      labelText: loc.harbour,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _meeting,
                    decoration: InputDecoration(
                      labelText: loc.meetingPoint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    decoration: InputDecoration(
                      labelText: loc.notesOptional,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    decoration: InputDecoration(labelText: loc.price),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currency,
                    decoration: InputDecoration(
                      labelText: loc.currencyOptional,
                    ),
                  ),
                  _buildPaymentSection(context),
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
