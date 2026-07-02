// RouteEditScreen – supports Date+Time and 'Alle Mann an Bord'; fixes getRef, mounted.
import 'package:flutter/material.dart';
import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_draft.dart';
import '../../models/documents/document_import_source_reference.dart';
import '../../store/cruise_store.dart';
import '../../models/route/route_item.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../services/documents/route_item_import_draft_prefill_service.dart';
import '../../services/documents/route_item_saved_document_attachment_service.dart';
import '../../utils/format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/documents/port_call_documents_section.dart';
import '../../widgets/documents/sea_day_documents_section.dart';

class RouteEditScreen extends StatefulWidget {
  final String routeItemId;
  final String cruiseId; // pass from list to avoid store lookup
  final bool createMode;
  final DocumentDraftTargetType? draftTargetType;
  final RouteItemImportDraft? initialDraft;
  final DocumentImportSourceReference? sourceReference;

  const RouteEditScreen({
    super.key,
    required this.routeItemId,
    required this.cruiseId,
    this.draftTargetType,
    this.initialDraft,
    this.sourceReference,
  }) : createMode = false;

  const RouteEditScreen.create({
    super.key,
    required this.routeItemId,
    required this.cruiseId,
    required this.draftTargetType,
    this.initialDraft,
    this.sourceReference,
  }) : createMode = true;

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> {
  final _draftPrefillService = const RouteItemImportDraftPrefillService();
  final _savedDocumentAttachmentService =
      RouteItemSavedDocumentAttachmentService();

  RouteItem? _item;
  final _portName = TextEditingController();
  final _notes = TextEditingController();
  bool _loading = true;

  DateTime? _date; // anchor day
  DateTime? _arrival;
  DateTime? _departure;
  DateTime? _allAboard;

  bool get isPort => _item is PortCallItem;
  bool get _isPortTarget =>
      _item is PortCallItem ||
      widget.draftTargetType == DocumentDraftTargetType.portCall;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = CruiseStore();
    await s.load();
    RouteItem? it;
    if (widget.createMode) {
      final cruise = s.getCruise(widget.cruiseId);
      final targetType = widget.draftTargetType;
      if (cruise != null &&
          targetType != null &&
          targetType.isRouteItemTarget) {
        it = _draftPrefillService.buildNewRouteItem(
          routeItemId: widget.routeItemId,
          fallbackDate: cruise.period.start,
          targetType: targetType,
          draft: widget.initialDraft,
        );
      }
    } else {
      final storedItem = s.getById<RouteItem>(widget.routeItemId);
      final targetType = widget.draftTargetType;
      if (storedItem != null) {
        it = targetType == null
            ? storedItem
            : _draftPrefillService.mergeIntoExisting(
                    base: storedItem,
                    targetType: targetType,
                    draft: widget.initialDraft,
                  ) ??
                storedItem;
      }
    }

    if (!mounted) {
      return;
    }

    if (it != null) {
      _applyItemToForm(it);
    }

    setState(() {
      _item = it;
      _loading = false;
    });
  }

  void _applyItemToForm(RouteItem item) {
    _date = item.date;
    _arrival = null;
    _departure = null;
    _allAboard = null;
    _portName.text = '';
    _notes.text = '';

    if (item is PortCallItem) {
      _portName.text = item.portName;
      _arrival = item.arrival;
      _departure = item.departure;
      _allAboard = item.allAboard;
      _notes.text = item.notes ?? '';
    } else if (item is SeaDayItem) {
      _notes.text = item.notes ?? '';
    }
  }

  Future<void> _save() async {
    final it = _item;
    if (it == null) {
      return;
    }
    final s = CruiseStore();
    await s.load();
    final latestItem = widget.createMode
        ? it
        : s.getById<RouteItem>(widget.routeItemId) ?? it;
    late RouteItem next;
    if (latestItem is PortCallItem) {
      next = latestItem.copyWith(
        date: _date ?? latestItem.date,
        portName: _portName.text.trim(),
        arrival: _arrival,
        departure: _departure,
        allAboard: _allAboard,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    } else if (latestItem is SeaDayItem) {
      next = latestItem.copyWith(
        date: _date ?? latestItem.date,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    } else {
      return;
    }
    await s.upsertRouteItem(cruiseId: widget.cruiseId, item: next);
    await _savedDocumentAttachmentService.attachImportedDocumentIfPresent(
      cruiseId: widget.cruiseId,
      routeItemId: next.id,
      sourceReference: widget.sourceReference,
    );
    if (!mounted) {
      return;
    }
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
    if (d == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? DateTime(baseDay.year, baseDay.month, baseDay.day, 18, 0)),
    );
    if (t == null) {
      return;
    }

    if (!mounted) {
      return;
    }
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (it == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_isPortTarget ? loc.editPort : loc.editSeaDay)),
        body: Center(child: Text(_isPortTarget ? loc.harbour : loc.seaDay)),
      );
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
          if (!widget.createMode && it is PortCallItem) ...[
            const SizedBox(height: 24),
            PortCallDocumentsSection(portCallId: it.id),
          ] else if (!widget.createMode && it is SeaDayItem) ...[
            const SizedBox(height: 24),
            SeaDayDocumentsSection(
              key: ValueKey('sea-day-docs-${it.id}-${it.documentIds.join('|')}'),
              seaDayId: it.id,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(loc.save)),
        ],
      ),
    );
  }
}
