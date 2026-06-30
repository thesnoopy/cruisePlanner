import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/route/route_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';
import '../../widgets/documents/sea_day_documents_section.dart';
import 'route_edit_screen.dart';

class SeaDayDetailScreen extends StatefulWidget {
  const SeaDayDetailScreen({
    super.key,
    required this.routeItemId,
  });

  final String routeItemId;

  @override
  State<SeaDayDetailScreen> createState() => _SeaDayDetailScreenState();
}

class _SeaDayDetailScreenState extends State<SeaDayDetailScreen> {
  SeaDayItem? _item;
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
    final item = routeItem is SeaDayItem ? routeItem : null;
    String? cruiseId;

    for (final cruise in store.activeCruises) {
      if (cruise.route.any((current) => current.id == widget.routeItemId)) {
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
        appBar: AppBar(title: Text(loc.seaDay)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final item = _item;
    if (item == null || _cruiseId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.seaDay)),
        body: Center(child: Text(loc.seaDay)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.seaDay),
        actions: [
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit),
            tooltip: loc.editSeaDay,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SeaDayInfoSection(item: item),
          const SizedBox(height: 16),
          SeaDayDocumentsSection(
            key: ValueKey('sea-day-documents-${item.id}-${item.documentIds.join('|')}'),
            seaDayId: item.id,
            isReadOnly: true,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit),
            label: Text(loc.editSeaDay),
          ),
        ],
      ),
    );
  }
}

class _SeaDayInfoSection extends StatelessWidget {
  const _SeaDayInfoSection({required this.item});

  final SeaDayItem item;

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
              loc.seaDay,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.event_outlined,
              label: loc.date,
              value: fmtDate(context, item.date),
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
