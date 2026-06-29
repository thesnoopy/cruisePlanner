import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/cruise.dart';
import '../../models/excursion.dart';
import '../../models/excursions/cash_currency_preference.dart';
import '../../models/excursions/excursion_payment_method.dart';
import '../../models/excursions/excursion_payment_mode.dart';
import '../../models/excursions/excursion_payment_part.dart';
import '../../models/excursions/excursion_payment_plan.dart';
import '../../models/excursions/excursion_payment_status_extension.dart';
import '../../models/excursions/excursion_payment_trigger.dart';
import '../../models/excursions/excursion_stop.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';
import '../../widgets/documents/excursion_documents_section.dart';
import 'excursion_edit_screen.dart';

class ExcursionDetailScreen extends StatefulWidget {
  final String cruiseId;
  final String excursionId;

  const ExcursionDetailScreen({
    super.key,
    required this.cruiseId,
    required this.excursionId,
  });

  @override
  State<ExcursionDetailScreen> createState() => _ExcursionDetailScreenState();
}

class _ExcursionDetailScreenState extends State<ExcursionDetailScreen> {
  Cruise? _cruise;
  Excursion? _excursion;
  bool _loading = true;
  final Set<String> _updatingStopIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = CruiseStore();
    await store.load();

    final cruise = store.getCruise(widget.cruiseId);
    Excursion? excursion;

    if (cruise != null) {
      for (final item in cruise.excursions) {
        if (item.id == widget.excursionId) {
          excursion = item;
          break;
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _cruise = cruise;
      _excursion = excursion;
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    final excursion = _excursion;
    if (excursion == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExcursionEditScreen(excursionId: excursion.id),
      ),
    );

    await _load();
  }

  Future<void> _updateStopVisited(ExcursionStop stop, bool visited) async {
    final excursion = _excursion;
    if (excursion == null) {
      return;
    }

    setState(() {
      _updatingStopIds.add(stop.id);
    });

    try {
      final store = CruiseStore();
      await store.updateExcursionStopVisited(
        widget.cruiseId,
        excursion.id,
        stop.id,
        visited,
      );

      await _load();
    } finally {
      if (mounted) {
        setState(() {
          _updatingStopIds.remove(stop.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.excursion)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cruise = _cruise;
    final excursion = _excursion;

    if (cruise == null || excursion == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.excursion)),
        body: Center(
          child: Text(loc.excursionNotFound),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          excursion.title.isEmpty ? loc.excursion : excursion.title,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoSection(excursion: excursion),
          const SizedBox(height: 16),
          ExcursionDocumentsSection(
            key: ValueKey(
              'excursion-documents-${excursion.id}-${excursion.documentIds.join('|')}',
            ),
            excursionId: excursion.id,
            isReadOnly: true,
          ),
          const SizedBox(height: 16),
          _PaymentSection(excursion: excursion),
          const SizedBox(height: 16),
          _StopsSection(
            stops: excursion.stops,
            updatingStopIds: _updatingStopIds,
            onVisitedChanged: _updateStopVisited,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit),
            label: Text(loc.editExcursion),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Excursion excursion;

  const _InfoSection({required this.excursion});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              excursion.title.isEmpty ? loc.excursion : excursion.title,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(loc.dateAndTime),
              subtitle: Text(fmtDate(context, excursion.date, includeTime: true)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on),
              title: Text(loc.harbour),
              subtitle: Text(excursion.port?.isNotEmpty == true ? excursion.port! : '-'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(loc.meetingPoint),
              subtitle: Text(
                excursion.meetingPoint?.isNotEmpty == true ? excursion.meetingPoint! : '-',
              ),
            ),
            if (excursion.notes?.isNotEmpty == true)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notes),
                title: Text(loc.notesOptional),
                subtitle: Text(excursion.notes!),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  final Excursion excursion;

  const _PaymentSection({required this.excursion});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currency = excursion.currency ?? '';
    final plan = excursion.paymentPlan;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.payment,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              excursion.paymentStatusText(context),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _PaymentInfoRow(
              label: loc.price,
              value: excursion.price != null
                  ? fmtMoney(context, excursion.price, currency: currency)
                  : '-',
            ),
            _PaymentInfoRow(
              label: loc.paymentType,
              value: _modeLabel(loc, plan?.mode),
            ),
            if (plan != null) ..._buildPlanRows(context, loc, plan, currency),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlanRows(
    BuildContext context,
    AppLocalizations loc,
    ExcursionPaymentPlan plan,
    String currency,
  ) {
    final onBooking = _firstPart(plan, ExcursionPaymentTrigger.onBooking);
    final beforeDate = _firstPart(plan, ExcursionPaymentTrigger.beforeDate);
    final onSite = _firstPart(plan, ExcursionPaymentTrigger.onSite);
    final widgets = <Widget>[];

    if (onBooking != null && plan.mode != ExcursionPaymentMode.fullOnBooking) {
      widgets.add(
        _PaymentInfoRow(
          label: loc.deposit,
          value: _formatAmount(context, onBooking.amount, currency),
        ),
      );
    }

    if (beforeDate != null) {
      widgets.add(
        _PaymentInfoRow(
          label: loc.finalPayment,
          value: _formatAmount(context, beforeDate.amount, currency),
        ),
      );
      widgets.add(
        _PaymentInfoRow(
          label: loc.remainingAmountDueUntill,
          value: beforeDate.dueDate != null
              ? fmtDate(context, beforeDate.dueDate)
              : loc.withoutDate,
        ),
      );
    }

    if (onSite != null) {
      widgets.add(
        _PaymentInfoRow(
          label: plan.mode == ExcursionPaymentMode.fullOnSite
              ? loc.amountOnSide
              : loc.remainingAmountOnSide,
          value: _formatAmount(context, onSite.amount, currency),
        ),
      );

      final onSiteDetails = _buildOnSiteDetails(loc, onSite);
      if (onSiteDetails.isNotEmpty) {
        widgets.add(
          _PaymentInfoRow(
            label: loc.paymentTypesOnSide,
            value: onSiteDetails,
          ),
        );
      }
    }

    if (plan.mode == ExcursionPaymentMode.fullOnBooking && onBooking != null) {
      widgets.add(
        _PaymentInfoRow(
          label: loc.finalPayment,
          value: _formatAmount(context, onBooking.amount, currency),
        ),
      );
    }

    return widgets;
  }

  ExcursionPaymentPart? _firstPart(
    ExcursionPaymentPlan plan,
    ExcursionPaymentTrigger trigger,
  ) {
    for (final part in plan.parts) {
      if (part.trigger == trigger) {
        return part;
      }
    }
    return null;
  }

  String _modeLabel(AppLocalizations loc, ExcursionPaymentMode? mode) {
    switch (mode) {
      case ExcursionPaymentMode.depositAndRestDate:
        return '${loc.deposit} + ${loc.finalPaymentOnDate}';
      case ExcursionPaymentMode.depositAndRestOnSite:
        return '${loc.deposit} + ${loc.finalPaymentOnSide}';
      case ExcursionPaymentMode.fullOnSite:
        return loc.fullPaymentOnSide;
      case ExcursionPaymentMode.fullOnBooking:
        return loc.payOnBooking;
      case null:
        return loc.noPaymentInformation;
    }
  }

  String _formatAmount(BuildContext context, num amount, String currency) {
    if (currency.isEmpty) {
      return fmtNumber(context, amount);
    }
    return fmtMoney(context, amount, currency: currency);
  }

  String _buildOnSiteDetails(
    AppLocalizations loc,
    ExcursionPaymentPart part,
  ) {
    final details = <String>[];

    if (part.paymentMethods.contains(ExcursionPaymentMethod.cash)) {
      details.add(loc.cash);
    }
    if (part.paymentMethods.contains(ExcursionPaymentMethod.creditCard)) {
      details.add(loc.credit);
    }
    if (part.paymentMethods.contains(ExcursionPaymentMethod.cash) &&
        part.cashCurrencyPreference != null) {
      details.add(_cashPreferenceLabel(loc, part.cashCurrencyPreference!));
    }

    return details.join(' • ');
  }

  String _cashPreferenceLabel(
    AppLocalizations loc,
    CashCurrencyPreference preference,
  ) {
    switch (preference) {
      case CashCurrencyPreference.localOnly:
        return loc.onlyLocalCurrency;
      case CashCurrencyPreference.localOrHome:
        return loc.localCurrencyOrOwnCurrency;
    }
  }
}

class _PaymentInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopsSection extends StatelessWidget {
  final List<ExcursionStop> stops;
  final Set<String> updatingStopIds;
  final Future<void> Function(ExcursionStop stop, bool visited) onVisitedChanged;

  const _StopsSection({
    required this.stops,
    required this.updatingStopIds,
    required this.onVisitedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.stops,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (stops.isEmpty)
              Text('-', style: theme.textTheme.bodyMedium),
            for (final stop in stops) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(stop.name),
                subtitle: stop.address?.isNotEmpty == true ? Text(stop.address!) : null,
                trailing: updatingStopIds.contains(stop.id)
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Checkbox(
                        value: stop.visited,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          onVisitedChanged(stop, value);
                        },
                      ),
              ),
              if (stop != stops.last) const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}
