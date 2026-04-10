import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/cruise.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';
import '../../widgets/documents/cruise_documents_section.dart';
import 'cruise_edit_screen.dart';

class CruiseDetailsScreen extends StatefulWidget {
  const CruiseDetailsScreen({
    super.key,
    required this.cruiseId,
  });

  final String cruiseId;

  @override
  State<CruiseDetailsScreen> createState() => _CruiseDetailsScreenState();
}

class _CruiseDetailsScreenState extends State<CruiseDetailsScreen> {
  Cruise? _cruise;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = CruiseStore();
    await store.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _cruise = store.getCruise(widget.cruiseId);
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    final cruise = _cruise;
    if (cruise == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CruiseEditScreen(cruiseId: cruise.id),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.cruiseDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cruise = _cruise;
    if (cruise == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.cruiseDetails)),
        body: Center(child: Text(loc.cruise)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle(context, cruise)),
        actions: [
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit),
            tooltip: loc.editCruise,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CruiseInfoSection(cruise: cruise),
          const SizedBox(height: 16),
          CruiseDocumentsSection(
            key: ValueKey(
              'cruise-documents-${cruise.id}-${cruise.documentIds.join('|')}',
            ),
            cruiseId: cruise.id,
            isReadOnly: true,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit),
            label: Text(loc.editCruise),
          ),
        ],
      ),
    );
  }

  String _screenTitle(BuildContext context, Cruise cruise) {
    final loc = AppLocalizations.of(context)!;
    return cruise.title.trim().isEmpty ? loc.cruiseDetails : cruise.title.trim();
  }
}

class _CruiseInfoSection extends StatelessWidget {
  const _CruiseInfoSection({required this.cruise});

  final Cruise cruise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sectionTitle(context, cruise),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._buildRows(context),
          ],
        ),
      ),
    );
  }

  String _sectionTitle(BuildContext context, Cruise cruise) {
    final loc = AppLocalizations.of(context)!;
    final title = cruise.title.trim();
    if (title.isNotEmpty) {
      return title;
    }

    final shipName = cruise.ship.name.trim();
    if (shipName.isNotEmpty) {
      return shipName;
    }

    return loc.cruiseDetails;
  }

  List<Widget> _buildRows(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final rows = <Widget>[
      if (cruise.title.trim().isNotEmpty)
        _InfoTile(
          icon: Icons.title,
          label: loc.title,
          value: cruise.title.trim(),
        ),
      if (cruise.ship.name.trim().isNotEmpty)
        _InfoTile(
          icon: Icons.directions_boat_outlined,
          label: loc.ship,
          value: cruise.ship.name.trim(),
        ),
      if ((cruise.ship.operatorName ?? '').trim().isNotEmpty)
        _InfoTile(
          icon: Icons.business_outlined,
          label: loc.travelCompany,
          value: cruise.ship.operatorName!.trim(),
        ),
      _InfoTile(
        icon: Icons.event_outlined,
        label: loc.start,
        value: fmtDate(context, cruise.period.start),
      ),
      _InfoTile(
        icon: Icons.event_available_outlined,
        label: loc.end,
        value: fmtDate(context, cruise.period.end),
      ),
      if ((cruise.cabinNumber ?? '').trim().isNotEmpty)
        _InfoTile(
          icon: Icons.door_front_door_outlined,
          label: loc.cabinNumber,
          value: cruise.cabinNumber!.trim(),
        ),
      if ((cruise.deckNumber ?? '').trim().isNotEmpty)
        _InfoTile(
          icon: Icons.layers_outlined,
          label: loc.deckNumber,
          value: cruise.deckNumber!.trim(),
        ),
      if ((cruise.deckname ?? '').trim().isNotEmpty)
        _InfoTile(
          icon: Icons.label_outline,
          label: loc.deckname,
          value: cruise.deckname!.trim(),
        ),
    ];

    return rows;
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
