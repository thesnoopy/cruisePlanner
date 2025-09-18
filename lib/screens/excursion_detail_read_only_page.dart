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

  Future<void> _edit(BuildContext context) async {
    final updated = await Navigator.of(context).push<Excursion>(
      MaterialPageRoute(
        builder: (_) => ExcursionWizardPage(
          cruise: cruise,
          initial: excursion,
        ),
      ),
    );

    if (updated == null) return;

    // Genau EIN Pop mit der aktualisierten Excursion zurück zur Liste:
    if (context.mounted) {
      Navigator.of(context).pop<Excursion>(updated);
    }
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
            onPressed: () => _edit(context),
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
