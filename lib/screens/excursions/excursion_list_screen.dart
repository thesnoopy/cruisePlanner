
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/cruise.dart';
import '../../models/excursion.dart';
import '../../models/excursions/excursion_payment_status_extension.dart';
import '../../models/excursions/excursion_payment_trigger.dart';
import '../../models/excursions/excursion_payment_method.dart';
import '../../models/excursions/cash_currency_preference.dart';
import '../../screens/excursions/excursion_detail_screen.dart';
import '../../screens/excursions/excursion_edit_screen.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';
import '../../models/identifiable.dart';

class ExcursionListScreen extends StatefulWidget {
  final String cruiseId;

  const ExcursionListScreen({
    super.key,
    required this.cruiseId,
  });

  @override
  State<ExcursionListScreen> createState() => _ExcursionListScreenState();
}

class _ExcursionListScreenState extends State<ExcursionListScreen> {
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

    final cruise = store.getCruise(widget.cruiseId);

    if (!mounted) {
      return;
    }

    setState(() {
      _cruise = cruise;
      _loading = false;
    });
  }

  Future<void> _openDetail(Excursion ex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExcursionDetailScreen(
          cruiseId: widget.cruiseId,
          excursionId: ex.id,
        ),
      ),
    );
    await _load();
  }

  // ADDED — neuer Ausflug
  Future<void> _createExcursion() async {
    final store = CruiseStore();
    await store.load();
    final cruise = store.getCruise(widget.cruiseId);
    if (cruise == null) {
      return;
    }

    final newExc = Excursion(
      id: Identifiable.newId(),
      title: '',
      date: cruise.period.start,
      port: null,
      meetingPoint: null,
      notes: null,
      price: null,
      currency: null,
      paymentPlan: null,
    );

    await store.upsertExcursion(
      cruiseId: cruise.id,
      excursion: newExc,
    );
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExcursionEditScreen(excursionId: newExc.id),
      ),
    );

    await _load();
  }

  // ADDED — Ausflug löschen
  Future<void> _deleteExcursion(String id) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showConfirmationDialog(
      context: context,
      title: loc.deleteExcursionTitle,              // optional
      message: loc.deleteExcursionQuestionmark, // optional
      okText: loc.delete,                     // optional
      cancelText: loc.confirmCancel,               // optional
      icon: Icons.warning_amber_rounded,     // optional
      destructive: true,                     // optional (OK Button rot)
    );

    if (!confirmed) {
      return;
    }

    final store = CruiseStore();
    await store.load();
    await store.deleteExcursion(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.excursions)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cruise = _cruise;

    if (cruise == null || cruise.excursions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.excursions)),
        body: Center(
          child: Text(loc.noFutureExcursions),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createExcursion,
          tooltip: loc.newExcursion,
          child: const Icon(Icons.add),
        ),
      );
    }

    final excursions = [...cruise.excursions]..sort(
        (a, b) => a.date.compareTo(b.date),
      );

    return Scaffold(
      appBar: AppBar(title: Text(loc.excursions)),
      body: ListView.builder(
        itemCount: excursions.length,
        itemBuilder: (context, index) {
          final ex = excursions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              onTap: () => _openDetail(ex),
              leading:      
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.teal.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.directions_walk,
                    color: Colors.teal,
                  ),
                ),
              title: Text(ex.title),
              subtitle: _buildSubtitle(context, ex),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteExcursion(ex.id),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createExcursion,
        tooltip: loc.newExcursion,
        child: const Icon(Icons.add),
      )
    );
  }

  Widget _buildSubtitle(BuildContext context, Excursion ex) {
    final dateLine = fmtDate(context, ex.date, includeTime: true);
    final portLine = ex.port?.isNotEmpty == true ? ex.port! : null;
    final paymentText = ex.paymentStatusText(context);
    final paymentIcons = _buildPaymentIcons(ex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            children: [
              const Icon(Icons.calendar_month, size: 14),
              const SizedBox(width: 4),
              Text(dateLine),
            ],
          ),
        if (portLine != null) 
          Row(
            children: [
              const Icon(Icons.location_on, size: 14),
              const SizedBox(width: 4),
              Text(portLine),
            ],
          ),
        const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.payments, size: 14),
              const SizedBox(width: 4),
              Expanded( 
                child: Text(
                  paymentText,
                ),
              ),
            ],
          ),
        if (paymentIcons.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: paymentIcons,
          ),
        ],
      ],
    );
  }

  Widget _chipIcon(IconData icon, BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiaryContainer;
    final foreground = Theme.of(context).colorScheme.onTertiaryContainer;

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: foreground),
    );
  }

  List<Widget> _buildPaymentIcons(Excursion ex) {
    final plan = ex.paymentPlan;
    if (plan == null || plan.parts.isEmpty) {
      return [];
    }

    final onSiteParts = plan.parts
        .where((p) => p.trigger == ExcursionPaymentTrigger.onSite)
        .toList();

    if (onSiteParts.isEmpty) {
      return [];
    }

    final p = onSiteParts.first;
    final methods = p.paymentMethods;

    final icons = <Widget>[];

    if (methods.contains(ExcursionPaymentMethod.cash)) {
      icons.add(_chipIcon(Icons.attach_money, context));
    }
    if (methods.contains(ExcursionPaymentMethod.creditCard)) {
      icons.add(_chipIcon(Icons.credit_card, context));
    }

    if (methods.contains(ExcursionPaymentMethod.cash) &&
        p.cashCurrencyPreference != null) {
      switch (p.cashCurrencyPreference) {
        case CashCurrencyPreference.localOnly:
          icons.add(_chipIcon(Icons.public, context));
          break;
        case CashCurrencyPreference.localOrHome:
          icons.add(_chipIcon(Icons.currency_exchange, context));
          break;
        default:
          break;
      }
    }

    return icons;
  }
}
