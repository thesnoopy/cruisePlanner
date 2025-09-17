import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/screens/excursion_detail_read_only_page.dart';
import 'package:cruiseplanner/data/cruise_repository.dart';
import 'package:cruiseplanner/screens/excursion_wizard_page.dart'; // ← dein existierender Wizard

class ExcursionListPage extends StatefulWidget {
  final Cruise cruise;
  final CruiseRepository repo;

  const ExcursionListPage({super.key, required this.cruise, required this.repo});

  @override
  State<ExcursionListPage> createState() => _ExcursionListPageState();
}

class _ExcursionListPageState extends State<ExcursionListPage> {
  late List<Excursion> _excursions;

  @override
  void initState() {
    super.initState();
    _excursions = List<Excursion>.from(widget.cruise.excursions ?? const <Excursion>[])
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Cruise _withExcursions(List<Excursion> list) {
    return widget.cruise.copyWith(excursions: list);
  }

  void _applyAndReturn(List<Excursion> list) {
    final updatedCruise = _withExcursions(list);
    Navigator.pop(context, updatedCruise); // pop zur CruiseDetailPage
  }

  Future<void> _createNew() async {
    // Falls dein Wizard eine andere Signatur hat, hier anpassen.
    final created = await Navigator.push<Excursion>(
      context,
      MaterialPageRoute(
        builder: (_) => ExcursionWizardPage(
          initial: null,
          cruise: widget.cruise,
          onSave: (exc) async {
            Navigator.pop(context, exc); // Wizard gibt Excursion zurück
          },
        ),
        fullscreenDialog: true,
      ),
    );

    if (created != null) {
      final list = [..._excursions, created]..sort((a, b) => a.date.compareTo(b.date));
      _applyAndReturn(list);
    }
  }

  Future<void> _openDetail(Excursion e) async {
    final maybeUpdatedCruise = await Navigator.push<Cruise>(
      context,
      MaterialPageRoute(
        builder: (_) => ExcursionDetailReadOnlyPage(
          cruise: widget.cruise,
          excursion: e,
          repo: widget.repo,
        ),
      ),
    );

    if (maybeUpdatedCruise != null) {
      // direkt nach oben weiterreichen (Liste wird in Detail schon gepflegt)
      if (!mounted) return;
      Navigator.pop(context, maybeUpdatedCruise);
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final df = DateFormat.yMMMMd(localeTag);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(widget.cruise);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(translations.excursionsTitle),
        actions: [
          IconButton(
            tooltip: translations.addNew,
            icon: const Icon(Icons.add),
            onPressed: _createNew,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNew,
        icon: const Icon(Icons.add),
        label: Text(translations.addNew),
      ),
      body: _excursions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(translations.noExcursionsYet),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _createNew,
                    child: Text(translations.addNew),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _excursions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = _excursions[i];
                final subtitle = "${df.format(e.date)} • ${e.port ?? translations.dash}";
                return Card(
                  child: ListTile(
                    title: Text(e.title.isEmpty ? translations.dash : e.title),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openDetail(e),
                  ),
                );
              },
            ),
    )
    );
  }
}
