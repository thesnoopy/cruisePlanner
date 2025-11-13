// Regenerated screens v2 – ID-only navigation, aligned with current models.

import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/cruise.dart';
import '../../models/excursion.dart';
import '../../models/identifiable.dart';
import 'excursion_edit_screen.dart';
import '../../utils/format.dart';


class ExcursionListScreen extends StatefulWidget {
  final String cruiseId;
  const ExcursionListScreen({super.key, required this.cruiseId});

  @override
  State<ExcursionListScreen> createState() => _ExcursionListScreenState();
}

class _ExcursionListScreenState extends State<ExcursionListScreen> {
  Cruise? _cruise;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = CruiseStore();
    await s.load();
    setState(() {
      _cruise = s.getCruise(widget.cruiseId);
    });
  }

  Future<void> _create() async {
    final id = Identifiable.newId();
    final s = CruiseStore();
    await s.load();
    final c = s.getCruise(widget.cruiseId);
    if (c == null) return;
    final ex = Excursion(id: id, title: 'Neue Excursion', date: c.period.start, port: null, meetingPoint: null, notes: null, price: null, currency: null);
    await s.upsertExcursion(cruiseId: widget.cruiseId, excursion: ex);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExcursionEditScreen(excursionId: id)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _cruise;
    return Scaffold(
      appBar: AppBar(title: const Text('Excursions')),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: c.excursions.length,
      itemBuilder: (_, i) {
        final e = c.excursions[i];

        final dateStr = fmtDate(context, e.date, pattern: 'yMMMd');
        final timeStr = fmtDate(context, e.date, pattern: 'HH:mm');

        final location = e.port ?? 'Kein Hafen';
        final meetingPoint = e.meetingPoint;
        final locationLine = (meetingPoint != null && meetingPoint.isNotEmpty)
            ? '$location – $meetingPoint'
            : location;

        return ListTile(
          leading: const Icon(Icons.tour),
          title: Text(e.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zeile 1: Hafen / Treffpunkt
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      locationLine,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Zeile 2: Datum
              Row(
                children: [
                  const Icon(Icons.event, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      dateStr,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Zeile 3: Uhrzeit
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14),
                  const SizedBox(width: 4),
                  Text(timeStr),
                ],
              ),
            ],
          ),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExcursionEditScreen(excursionId: e.id),
              ),
            );
            await _load();
          },
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final s = CruiseStore();
              await s.load();
              await s.deleteExcursion(e.id);
              await _load();
            },
          ),
        );
      },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
    );
  }
}
