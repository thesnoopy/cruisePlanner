import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/screens/excursion_wizard_page.dart';
import 'package:cruiseplanner/data/cruise_repository.dart';

class ExcursionDetailReadOnlyPage extends StatelessWidget {
  final Cruise cruise;
  final Excursion excursion;
  final CruiseRepository repo;

  const ExcursionDetailReadOnlyPage({
    super.key,
    required this.cruise,
    required this.excursion,
    required this.repo,
  });

  List<Excursion> _replaceById(List<Excursion> list, Excursion updated) {
    final idx = list.indexWhere((x) => x.id == updated.id);
    if (idx < 0) return list; // nichts zu ersetzen
    final copy = [...list];
    copy[idx] = updated;
    copy.sort((a, b) => a.date.compareTo(b.date));
    return copy;
  }

  Cruise _withExcursions(List<Excursion> list) {
    return cruise.copyWith(excursions: list);
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final df = DateFormat.yMMMMd(localeTag);

    String? formatMoney(num? value, String? code) {
      if (value == null || code == null || code.isEmpty) return null;
      return NumberFormat.currency(locale: localeTag, name: code).format(value);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.excursionDetailsTitle),
        actions: [
          IconButton(
            tooltip: translations.edit,
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<Excursion>(
                context,
                MaterialPageRoute(
                  builder: (_) => ExcursionWizardPage(
                    initial: excursion,
                    cruise: cruise,
                    onSave: (exc) async {
                      Navigator.pop(context, exc); // Wizard gibt Excursion zurück
                    },
                  ),
                  fullscreenDialog: true,
                ),
              );
              if (updated != null) {
                final list = _replaceById(cruise.excursions ?? const <Excursion>[], updated);
                final updatedCruise = _withExcursions(list);
                if (context.mounted) Navigator.pop(context, updatedCruise);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text(excursion.title.isEmpty ? translations.dash : excursion.title),
              subtitle: Text("${df.format(excursion.date)} • ${excursion.port ?? translations.dash}"),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.meeting_room),
              title: Text(translations.meetingPointLabel),
              subtitle: Text(excursion.meetingPoint?.isNotEmpty == true ? excursion.meetingPoint! : translations.dash),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text(translations.priceLabel),
              subtitle: Text(formatMoney(excursion.price, excursion.currency) ?? translations.dash),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notes),
              title: Text(translations.notesLabel),
              subtitle: Text(excursion.notes?.isNotEmpty == true ? excursion.notes! : translations.dash),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_boat),
              title: Text(cruise.title),
              subtitle: Text(
                "${DateFormat.yMMMMd(localeTag).format(cruise.period.start)} → "
                "${DateFormat.yMMMMd(localeTag).format(cruise.period.end)}",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
