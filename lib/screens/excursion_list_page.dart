import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';

import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/data/cruise_repository.dart';
import 'package:cruiseplanner/screens/excursion_detail_read_only_page.dart';
import 'package:cruiseplanner/screens/excursion_wizard_page.dart';

class ExcursionListPage extends StatefulWidget {
  final Cruise cruise;
  final CruiseRepository repo;

  const ExcursionListPage({
    super.key,
    required this.cruise,
    required this.repo,
  });

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

  Future<void> _createNew() async {
    final created = await Navigator.push<Excursion>(
      context,
      MaterialPageRoute(
        builder: (_) => ExcursionWizardPage(
          initial: null,
          cruise: widget.cruise,
        ),
        fullscreenDialog: true,
      ),
    );
    if (created == null) return;

    setState(() {
      _excursions = [..._excursions, created]..sort((a, b) => a.date.compareTo(b.date));
    });
    // WICHTIG: hier KEIN Pop und KEIN Repo-Save – Persistenz passiert oben (CruiseDetailPage) beim Zurück.
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
    if (maybeUpdatedCruise == null) return;

    // Liste aus der zurückgegebenen Cruise übernehmen (Detail hat schon gemerged)
    setState(() {
      _excursions = List<Excursion>.from(maybeUpdatedCruise.excursions ?? const <Excursion>[])
        ..sort((a, b) => a.date.compareTo(b.date));
    });
    // KEIN Pop hier; wir bleiben in der Liste.
  }

  Future<bool> _confirmDelete(BuildContext context, Excursion e) async {
    final t = AppLocalizations.of(context)!;
    final name = e.title.isEmpty ? t.noTitle : e.title;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t.deleteCruiseTitle), // temporär wiederverwendet
            content: Text(t.deleteCruiseMessage(name)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.deleteCancel)),
              FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: Text(t.deleteConfirm)),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final df = DateFormat.yMMMMd(localeTag);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
        if (!isCurrent) return;

        final updatedCruise = widget.cruise.copyWith(excursions: _excursions);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pop<Cruise>(updatedCruise);
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(title: Text(t.excursionsTitle)),
        floatingActionButton: FloatingActionButton(
          onPressed: _createNew,
          child: const Icon(Icons.add),
        ),
        body: _excursions.isEmpty
            ? Center(child: Text(t.noExcursions))
            : ListView.builder(
                itemCount: _excursions.length,
                itemBuilder: (context, i) {
                  final e = _excursions[i];
                  final subtitle = df.format(e.date);
                  return Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) => _confirmDelete(context, e),
                    onDismissed: (_) {
                      setState(() {
                        _excursions.removeAt(i);
                      });
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(e.title.isEmpty ? t.dash : e.title),
                        subtitle: Text(subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDetail(e),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}