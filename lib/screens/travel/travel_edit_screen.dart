// Regenerated screens v2 - ID-only navigation, aligned with current models.

import 'package:cruiseplanner/models/travel/cruise_check_in_item.dart';
import 'package:cruiseplanner/models/travel/cruise_check_out_item.dart';
import 'package:cruiseplanner/models/travel/hotel_item.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_draft.dart';
import '../../models/identifiable.dart';
import '../../models/travel/base_travel.dart';
import '../../models/travel/flight_item.dart';
import '../../models/travel/rental_car_item.dart';
import '../../models/travel/train_item.dart';
import '../../models/travel/transfer_item.dart';
import '../../services/documents/travel_import_draft_prefill_service.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';
import '../../widgets/documents/travel_documents_section.dart';

class TravelEditScreen extends StatefulWidget {
  final String? travelItemId;
  final String? cruiseId;
  final DocumentDraftTargetType? draftTargetType;
  final TravelImportDraft? initialDraft;

  const TravelEditScreen({
    super.key,
    required this.travelItemId,
    this.draftTargetType,
    this.initialDraft,
  }) : cruiseId = null;

  const TravelEditScreen.create({
    super.key,
    required this.cruiseId,
    required this.draftTargetType,
    this.initialDraft,
  }) : travelItemId = null;

  @override
  State<TravelEditScreen> createState() => _TravelEditScreenState();
}

class _TravelEditScreenState extends State<TravelEditScreen> {
  final _draftPrefillService = const TravelImportDraftPrefillService();

  TravelItem? _item;
  String? _cruiseId;
  bool _loading = true;

  final _formKey = GlobalKey<FormState>();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _notes = TextEditingController();
  final _price = TextEditingController();
  final _currency = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  // kind-specific
  final _carrier = TextEditingController();
  final _flightNo = TextEditingController();
  final _recordLocator = TextEditingController();
  TransferMode? _transferMode;
  final _company = TextEditingController(); // rental car
  final _name = TextEditingController();
  final _location = TextEditingController();

  bool get _isCreateMode => widget.travelItemId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = CruiseStore();
    await store.load();

    TravelItem? item;
    String? cruiseId;

    final travelItemId = widget.travelItemId;
    if (travelItemId != null) {
      final storedItem = store.getById<TravelItem>(travelItemId);
      final draftTargetType = widget.draftTargetType;
      if (storedItem != null) {
        item = draftTargetType == null
            ? storedItem
            : _draftPrefillService.mergeIntoExisting(
                    base: storedItem,
                    targetType: draftTargetType,
                    draft: widget.initialDraft,
                  ) ??
                storedItem;
      }

      for (final cruise in store.activeCruises) {
        if (cruise.travel.any((travelItem) => travelItem.id == travelItemId)) {
          cruiseId = cruise.id;
          break;
        }
      }
    } else {
      final targetCruiseId = widget.cruiseId;
      final draftTargetType = widget.draftTargetType;
      final cruise =
          targetCruiseId == null ? null : store.getCruise(targetCruiseId);
      if (cruise != null &&
          draftTargetType != null &&
          draftTargetType.isTravelTarget) {
        cruiseId = cruise.id;
        item = _draftPrefillService.buildNewTravelItem(
          travelItemId: Identifiable.newId(),
          fallbackStart: cruise.period.start,
          targetType: draftTargetType,
          draft: widget.initialDraft,
        );
      }
    }

    if (!mounted) {
      return;
    }

    if (item != null) {
      _applyItemToForm(item);
    }

    setState(() {
      _item = item;
      _cruiseId = cruiseId;
      _loading = false;
    });
  }

  void _applyItemToForm(TravelItem item) {
    _from.text = item.from ?? '';
    _to.text = item.to ?? '';
    _notes.text = item.notes ?? '';
    _price.text = fmtNumber(context, item.price);
    _currency.text = item.currency ?? '';
    _start = item.start;
    _end = item.end;
    _recordLocator.text = item.recordLocator ?? '';
    _carrier.text = '';
    _flightNo.text = '';
    _transferMode = null;
    _company.text = '';
    _name.text = '';
    _location.text = '';

    switch (item.kind) {
      case TravelKind.flight:
        final flight = item as FlightItem;
        _carrier.text = flight.carrier ?? '';
        _flightNo.text = flight.flightNo ?? '';
        break;
      case TravelKind.train:
        break;
      case TravelKind.transfer:
        final transfer = item as TransferItem;
        _transferMode = transfer.mode;
        break;
      case TravelKind.rentalCar:
        final rentalCar = item as RentalCarItem;
        _company.text = rentalCar.company ?? '';
        break;
      case TravelKind.hotel:
        final hotel = item as HotelItem;
        _company.text = hotel.company ?? '';
        _name.text = hotel.name;
        _location.text = hotel.location ?? '';
        break;
      case TravelKind.cruiseCheckIn:
        break;
      case TravelKind.cruiseCheckOut:
        break;
    }
  }

  Future<void> _pickDateTime(bool start) async {
    final initial =
        start ? (_start ?? DateTime.now()) : (_end ?? _start ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (date == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return;
    }

    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (start) {
        _start = value;
        if (_end != null && _end!.isBefore(_start!)) {
          _end = _start;
        }
      } else {
        _end = value;
      }
    });
  }

  Future<void> _save() async {
    final item = _item;
    final cid = _cruiseId;
    if (item == null || cid == null) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parsedPrice =
        _price.text.isEmpty ? null : parseLocalizedNumber(context, _price.text);
    final store = CruiseStore();
    await store.load();
    final latest =
        _isCreateMode
            ? item
            : store.getById<TravelItem>(widget.travelItemId!) ?? item;

    TravelItem next;
    switch (latest.kind) {
      case TravelKind.flight:
        next = (latest as FlightItem).copyWith(
          start: _start ?? latest.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: parsedPrice,
          currency: _currency.text.isEmpty ? null : _currency.text,
          carrier: _carrier.text.isEmpty ? null : _carrier.text,
          flightNo: _flightNo.text.isEmpty ? null : _flightNo.text,
          recordLocator:
              _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.train:
        next = (latest as TrainItem).copyWith(
          start: _start ?? latest.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: parsedPrice,
          currency: _currency.text.isEmpty ? null : _currency.text,
          recordLocator:
              _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.transfer:
        next = (latest as TransferItem).copyWith(
          start: _start ?? latest.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: parsedPrice,
          currency: _currency.text.isEmpty ? null : _currency.text,
          mode: _transferMode,
          recordLocator:
              _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.rentalCar:
        next = (latest as RentalCarItem).copyWith(
          start: _start ?? latest.start,
          end: _end,
          from: _from.text,
          to: _to.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: parsedPrice,
          currency: _currency.text.isEmpty ? null : _currency.text,
          company: _company.text.isEmpty ? null : _company.text,
          recordLocator:
              _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.hotel:
        next = (latest as HotelItem).copyWith(
          start: _start ?? latest.start,
          end: _end,
          notes: _notes.text.isEmpty ? null : _notes.text,
          price: parsedPrice,
          currency: _currency.text.isEmpty ? null : _currency.text,
          company: _company.text.isEmpty ? null : _company.text,
          name: _name.text.isEmpty ? null : _name.text,
          location: _location.text.isEmpty ? null : _location.text,
          recordLocator:
              _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.cruiseCheckIn:
        next = (latest as CruiseCheckIn).copyWith(
          start: _start ?? latest.start,
          end: _end,
          notes: _notes.text.isEmpty ? null : _notes.text,
          recordLocator:
              _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
      case TravelKind.cruiseCheckOut:
        next = (latest as CruiseCheckOut).copyWith(
          start: _start ?? latest.start,
          end: _end,
          notes: _notes.text.isEmpty ? null : _notes.text,
          recordLocator:
              _recordLocator.text.isEmpty ? null : _recordLocator.text,
        );
        break;
    }

    await store.upsertTravelItem(cruiseId: cid, item: next);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final loc = AppLocalizations.of(context)!;

    final title = switch (item?.kind) {
      TravelKind.flight => loc.editFlight,
      TravelKind.train => loc.editTrain,
      TravelKind.transfer => loc.editTransfer,
      TravelKind.rentalCar => loc.editRentalCar,
      TravelKind.hotel => loc.hotel,
      TravelKind.cruiseCheckIn => loc.cruiseCheckIn,
      TravelKind.cruiseCheckOut => loc.cruiseCheckOut,
      _ => loc.editTravel,
    };

    List<Widget> writeScreen({
      String from = '',
      String to = '',
      String start = '',
      String end = '',
      String notes = '',
      String price = '',
      String carrier = '',
      String flightNo = '',
      String recordLocator = '',
      String transferMode = '',
      String company = '',
      String name = '',
      String location = '',
    }) {
      final List<Widget> collection = [];
      if (from != '') {
        collection.add(
          _row(
            from,
            TextFormField(
              controller: _from,
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? loc.requiredField
                          : null,
            ),
          ),
        );
        collection.add(const SizedBox(height: 12));
      }
      if (to != '') {
        collection.add(
          _row(
            to,
            TextFormField(
              controller: _to,
              validator:
                  (value) =>
                      (value == null || value.isEmpty) ? to : null,
            ),
          ),
        );
        collection.add(const SizedBox(height: 12));
      }
      if (start != '') {
        collection.add(
          ListTile(
            title: Text(start),
            subtitle: Text(
              fmtDate(context, _start ?? DateTime.now(), includeTime: true),
            ),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () => _pickDateTime(true),
          ),
        );
      }
      if (end != '') {
        collection.add(
          ListTile(
            title: Text(end),
            subtitle: Text(
              fmtDate(
                context,
                _end ?? _start ?? DateTime.now(),
                includeTime: true,
              ),
            ),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () => _pickDateTime(false),
          ),
        );
      }
      collection.add(const SizedBox(height: 12));
      if (notes != '') {
        collection.add(
          TextFormField(
            controller: _notes,
            decoration: InputDecoration(labelText: notes),
            maxLines: 3,
          ),
        );
        collection.add(const SizedBox(height: 12));
      }
      if (price != '') {
        collection.add(
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  decoration: InputDecoration(labelText: loc.price),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _currency,
                  decoration: InputDecoration(labelText: loc.currencyOptional),
                ),
              ),
            ],
          ),
        );
        collection.add(const Divider(height: 32));
      }
      if (carrier != '') {
        collection.add(
          TextFormField(
            controller: _carrier,
            decoration: InputDecoration(labelText: carrier),
          ),
        );
        collection.add(const SizedBox(height: 12));
      }
      if (flightNo != '') {
        collection.add(
          TextFormField(
            controller: _flightNo,
            decoration: InputDecoration(labelText: flightNo),
          ),
        );
      }
      if (recordLocator != '') {
        collection.add(
          TextFormField(
            controller: _recordLocator,
            decoration: InputDecoration(labelText: recordLocator),
          ),
        );
      }
      if (transferMode != '') {
        collection.add(
          DropdownButtonFormField<TransferMode>(
            initialValue: _transferMode,
            items: [
              for (final mode in TransferMode.values)
                DropdownMenuItem(value: mode, child: Text(mode.name)),
            ],
            onChanged: (value) => setState(() => _transferMode = value),
            decoration: InputDecoration(labelText: transferMode),
          ),
        );
      }
      if (company != '') {
        collection.add(
          TextFormField(
            controller: _company,
            decoration: InputDecoration(labelText: company),
          ),
        );
      }
      if (name != '') {
        collection.add(
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: loc.hotel),
          ),
        );
      }
      if (location != '') {
        collection.add(
          TextFormField(
            controller: _location,
            decoration: InputDecoration(labelText: loc.location),
          ),
        );
      }
      return collection;
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : item == null
              ? Center(child: Text(loc.noTravelItem))
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (item.kind == TravelKind.flight)
                      ...writeScreen(
                        from: loc.from,
                        to: loc.to,
                        start: loc.start,
                        end: loc.end,
                        notes: loc.notesOptional,
                        price: loc.price,
                        carrier: loc.airlineOptional,
                        flightNo: loc.flightnumber,
                        recordLocator: loc.bookingNumberOptional,
                      ),
                    if (item.kind == TravelKind.train)
                      ...writeScreen(
                        from: loc.from,
                        to: loc.to,
                        start: loc.start,
                        end: loc.end,
                        notes: loc.notesOptional,
                        price: loc.price,
                      ),
                    if (item.kind == TravelKind.transfer)
                      ...writeScreen(
                        from: loc.from,
                        to: loc.to,
                        start: loc.start,
                        end: loc.end,
                        notes: loc.notesOptional,
                        price: loc.price,
                        transferMode: loc.modeOptional,
                      ),
                    if (item.kind == TravelKind.rentalCar)
                      ...writeScreen(
                        from: loc.from,
                        to: loc.to,
                        start: loc.start,
                        end: loc.end,
                        notes: loc.notesOptional,
                        price: loc.price,
                        recordLocator: loc.bookingNumberOptional,
                        company: loc.rentalCarCompany,
                      ),
                    if (item.kind == TravelKind.hotel)
                      ...writeScreen(
                        start: loc.start,
                        end: loc.end,
                        notes: loc.notesOptional,
                        price: loc.price,
                        name: loc.hotel,
                        recordLocator: loc.bookingNumberOptional,
                        location: loc.location,
                      ),
                    if (item.kind == TravelKind.cruiseCheckIn)
                      ...writeScreen(
                        start: loc.start,
                        end: loc.end,
                        notes: loc.notesOptional,
                      ),
                    if (item.kind == TravelKind.cruiseCheckOut)
                      ...writeScreen(
                        start: loc.start,
                        end: loc.end,
                        notes: loc.notesOptional,
                      ),
                    if (!_isCreateMode) ...[
                      const SizedBox(height: 16),
                      TravelDocumentsSection(
                        key: ValueKey(
                          'travel-docs-${item.id}-${item.documentIds.join('|')}',
                        ),
                        travelItemId: item.id,
                      ),
                    ],
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

  Widget _row(String label, Widget field) => Row(
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: field),
    ],
  );
}
