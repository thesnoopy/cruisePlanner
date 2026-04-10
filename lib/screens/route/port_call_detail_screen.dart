import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/route_item.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';
import '../../widgets/documents/port_call_documents_section.dart';
import 'route_edit_screen.dart';

class PortCallDetailScreen extends StatefulWidget {
  const PortCallDetailScreen({
    super.key,
    required this.routeItemId,
  });

  final String routeItemId;

  @override
  State<PortCallDetailScreen> createState() => _PortCallDetailScreenState();
}

class _PortCallDetailScreenState extends State<PortCallDetailScreen> {
  PortCallItem? _item;
  String? _cruiseId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = CruiseStore();
    await store.load();

    final routeItem = store.getById<RouteItem>(widget.routeItemId);
    final item = routeItem is PortCallItem ? routeItem : null;
    String? cruiseId;

    for (final cruise in store.cruises) {
      if (cruise.route.any((routeItem) => routeItem.id == widget.routeItemId)) {
        cruiseId = cruise.id;
        break;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _item = item;
      _cruiseId = cruiseId;
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    final item = _item;
    final cruiseId = _cruiseId;
    if (item == null || cruiseId == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteEditScreen(
          routeItemId: item.id,
          cruiseId: cruiseId,
        ),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.harbour)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final item = _item;
    if (item == null || _cruiseId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.harbour)),
        body: Center(child: Text(loc.unknownHarbour)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle(context, item)),
        actions: [
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit),
            tooltip: loc.editPort,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PortCallInfoSection(item: item),
          const SizedBox(height: 16),
          PortCallDocumentsSection(
            key: ValueKey('port-call-documents-${item.id}-${item.documentIds.join('|')}'),
            portCallId: item.id,
            isReadOnly: true,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit),
            label: Text(loc.editPort),
          ),
        ],
      ),
    );
  }

  String _screenTitle(BuildContext context, PortCallItem item) {
    final loc = AppLocalizations.of(context)!;
    return item.portName.trim().isEmpty ? loc.harbour : item.portName.trim();
  }
}

class _PortCallInfoSection extends StatelessWidget {
  const _PortCallInfoSection({required this.item});

  final PortCallItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.portName.trim().isEmpty ? loc.unknownHarbour : item.portName.trim(),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.place_outlined,
              label: loc.harbour,
              value: item.portName.trim().isEmpty ? loc.unknownHarbour : item.portName.trim(),
            ),
            _InfoTile(
              icon: Icons.event_outlined,
              label: loc.date,
              value: fmtDate(context, item.date),
            ),
            if (item.arrival != null)
              _InfoTile(
                icon: Icons.login,
                label: loc.arrival,
                value: fmtDate(context, item.arrival, includeTime: true),
              ),
            if (item.departure != null)
              _InfoTile(
                icon: Icons.logout,
                label: loc.departure,
                value: fmtDate(context, item.departure, includeTime: true),
              ),
            if (item.allAboard != null)
              _InfoTile(
                icon: Icons.warning_amber_outlined,
                label: loc.allOnBoard,
                value: fmtDate(context, item.allAboard, includeTime: true),
              ),
            if ((item.notes ?? '').trim().isNotEmpty)
              _InfoTile(
                icon: Icons.notes_outlined,
                label: loc.notesOptional,
                value: item.notes!.trim(),
              ),
          ],
        ),
      ),
    );
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
