import 'package:flutter/material.dart';
import '../models/cruise.dart';
import '../models/ship.dart';
import '../models/period.dart';
import '../utils/date_fmt.dart';
import 'package:cruise_app/gen/l10n/app_localizations.dart';

class CruiseWizardPage extends StatefulWidget {
  final Cruise initial;

  const CruiseWizardPage({super.key, required this.initial});

  @override
  State<CruiseWizardPage> createState() => _CruiseWizardPageState();
}

class _CruiseWizardPageState extends State<CruiseWizardPage> {
  int _currentStep = 0;

  // Form Keys für step-spezifische Validierung
  final _formTitleKey = GlobalKey<FormState>();
  final _formShipKey = GlobalKey<FormState>();

  // Controller
  late final TextEditingController _titleCtrl;
  late final TextEditingController _shipNameCtrl;
  late final TextEditingController _shippingLineCtrl;

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _titleCtrl = TextEditingController(text: c.title);
    _shipNameCtrl = TextEditingController(text: c.ship.name);
    _shippingLineCtrl = TextEditingController(text: c.ship.shippingLine);
    _startDate = c.period.start;
    _endDate = c.period.end;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _shipNameCtrl.dispose();
    _shippingLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate, // Ende darf nicht vor Start liegen
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _onStepContinue() {
    switch (_currentStep) {
      case 0:
        if (_formTitleKey.currentState?.validate() ?? false) {
          setState(() => _currentStep = 1);
        }
        break;
      case 1:
        if (_formShipKey.currentState?.validate() ?? false) {
          setState(() => _currentStep = 2);
        }
        break;
      case 2:
        _finish();
        break;
    }
  }

  void _onStepCancel() {
    if (_currentStep == 0) {
      Navigator.pop(context); // Wizard ohne Ergebnis schließen
    } else {
      setState(() => _currentStep -= 1);
    }
  }

  void _finish() {
    // finale Validierung (Titel nicht leer; Dates konsistent)
    final translations = AppLocalizations.of(context)!;
    if ((_formTitleKey.currentState?.validate() ?? false) &&
        !_endDate.isBefore(_startDate)) {
      final result = widget.initial.copyWith(
        title: _titleCtrl.text.trim(),
        ship: Ship(
          name: _shipNameCtrl.text.trim(),
          shippingLine: _shippingLineCtrl.text.trim(),
        ),
        period: Period(start: _startDate, end: _endDate),
      );
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translations.pleaseCheckEntries)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final controls = (BuildContext context, ControlsDetails details) {
      final isLast = _currentStep == 2;
      return Row(
        children: [
          ElevatedButton(
            onPressed: details.onStepContinue,
            child: Text(isLast ? translations.finished : translations.next),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: details.onStepCancel,
            child: Text(_currentStep == 0 ? translations.cancel : translations.back),
          ),
        ],
      );
    };

    return Scaffold(
      appBar: AppBar(title: Text(
        widget.initial.title.trim().isEmpty
          ? translations.wizardTitleNewCruise
          : widget.initial.title,
        )
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: controls,
        steps: [
          Step(
            title: Text(translations.cruiseTitleLabel),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formTitleKey,
              child: TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: translations.cruiseTitleLabel,
                  hintText: translations.cruiseTitleHintText,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? translations.titleMustNotBeEmpty : null,
              ),
            ),
          ),
          Step(
            title: Text(translations.shipLabel),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formShipKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _shipNameCtrl,
                    decoration: InputDecoration(
                      labelText: translations.shipName,
                      hintText: translations.shipNameHintText,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? translations.pleaseEnterShipName : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shippingLineCtrl,
                    decoration: InputDecoration(
                      labelText: translations.cruiseCompany,
                      hintText: translations.cruiseCompanyHintText,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? translations.pleaseEnterCruiseCompany : null,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: Text(translations.periodLabel),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(translations.startDate),
                  subtitle: Text(ymd(_startDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickStartDate,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(translations.endDate),
                  subtitle: Text(ymd(_endDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickEndDate,
                  ),
                ),
                if (_endDate.isBefore(_startDate))
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      translations.endMustAfterStart,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
