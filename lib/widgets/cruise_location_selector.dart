import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/cruise_location.dart';
import '../store/cruise_store.dart';

/// Shared picker; persistence and location ordering belong to CruiseStore.
class CruiseLocationSelector extends StatefulWidget {
  const CruiseLocationSelector({
    super.key,
    required this.cruiseId,
    required this.locationId,
    required this.onChanged,
  });

  final String cruiseId;
  final String? locationId;
  final ValueChanged<String> onChanged;

  @override
  State<CruiseLocationSelector> createState() => _CruiseLocationSelectorState();
}

class _CruiseLocationSelectorState extends State<CruiseLocationSelector> {
  final _store = CruiseStore();
  List<CruiseLocation> _locations = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _store.load();
    if (!mounted) return;
    setState(() => _locations = _store.locationChoices(widget.cruiseId));
  }

  Future<void> _pick(FormFieldState<String> field) async {
    await _refresh();
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final routeIds = _store.routeLocationIds(widget.cruiseId);
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final inRoute in [true, false]) ...[
              ListTile(title: Text(inRoute
                  ? loc.cruiseRouteLocations : loc.cruiseOtherLocations)),
              for (final location in _locations.where(
                  (item) => routeIds.contains(item.id) == inRoute))
                ListTile(
                  leading: Icon(location.type == CruiseLocationType.port
                      ? Icons.directions_boat : Icons.place_outlined),
                  title: Text(location.name),
                  selected: location.id == widget.locationId,
                  onTap: () => Navigator.pop(sheetContext, location.id),
                ),
            ],
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(loc.cruiseCreateLocation),
              onTap: () => Navigator.pop(sheetContext, ''),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    final id = selected.isEmpty ? await _create() : selected;
    if (!mounted || id == null) return;
    field.didChange(id);
    widget.onChanged(id);
  }

  Future<String?> _create() async {
    final draft = await showDialog<_LocationDraft>(
      context: context,
      builder: (_) => const _CreateLocationDialog(),
    );
    if (!mounted || draft == null) return null;
    try {
      await _store.load();
      final location = await _store.createLocation(
        cruiseId: widget.cruiseId, name: draft.name, type: draft.type,
      );
      await _refresh();
      return location.id;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.cruiseLocationSaveFailed),
        ));
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final selected = _locations.where((item) => item.id == widget.locationId)
        .firstOrNull;
    return FormField<String>(
      initialValue: widget.locationId,
      validator: (id) => id == null ? loc.cruiseSelectLocation : null,
      builder: (field) => InkWell(
        onTap: () => _pick(field),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: loc.cruiseLocation,
            errorText: field.errorText,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(selected?.name ?? loc.cruiseSelectLocation),
        ),
      ),
    );
  }
}

class _LocationDraft {
  const _LocationDraft(this.name, this.type);
  final String name;
  final CruiseLocationType type;
}

class _CreateLocationDialog extends StatefulWidget {
  const _CreateLocationDialog();

  @override
  State<_CreateLocationDialog> createState() => _CreateLocationDialogState();
}

class _CreateLocationDialogState extends State<_CreateLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  CruiseLocationType _type = CruiseLocationType.stopPoint;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.cruiseCreateLocation),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: loc.cruiseLocationName),
              validator: (value) => value == null || value.trim().isEmpty
                  ? loc.cruiseLocationNameRequired : null,
            ),
            DropdownButtonFormField<CruiseLocationType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: loc.cruiseLocationType),
              items: [
                DropdownMenuItem(value: CruiseLocationType.port,
                    child: Text(loc.harbour)),
                DropdownMenuItem(value: CruiseLocationType.stopPoint,
                    child: Text(loc.cruiseLocationStopPoint)),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text(loc.confirmCancel)),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _LocationDraft(_name.text, _type));
            }
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}
