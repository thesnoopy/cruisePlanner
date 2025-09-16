import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';

import 'package:cruiseplanner/models/cruise.dart';
import '../data/cruise_repository.dart';
import 'cruise_wizard_page.dart';

class CruiseDetailsReadOnlyPage extends StatelessWidget {
  final Cruise cruise;
  final CruiseRepository repo;
  const CruiseDetailsReadOnlyPage({super.key, required this.cruise, required this.repo});

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final df = DateFormat.yMMMMd(localeTag);

    String rangeText(DateTime s, DateTime e) => "${df.format(s)} → ${df.format(e)}";

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.cruiseDetailsTitle),
        actions: [
          IconButton(
              tooltip: translations.edit,
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await Navigator.push<Cruise>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CruiseWizardPage(initial: cruise), // Edit-Modus via initial
                    fullscreenDialog: true,
                  ),
                );

                if (updated != null) {
                  // Optional: direkt speichern, wenn du hier schon persistieren willst:
                  // await repo.saveCruise(updated); // falls du so eine Methode hast
                  // Zurück zur vorigen Seite und aktualisiertes Objekt mitgeben:
                  if (context.mounted) Navigator.pop(context, updated);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cruise.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(rangeText(cruise.period.start, cruise.period.end)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_boat),
              title: Text(cruise.ship.name.isEmpty ? translations.dash : cruise.ship.name),
              subtitle: Text(cruise.ship.shippingLine.isEmpty ? translations.dash : cruise.ship.shippingLine),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: Text(translations.excursionsCountLabel),
              subtitle: Text("${cruise.excursions?.length ?? 0}"),
            ),
          ),
        ],
      ),
    );
  }
}
