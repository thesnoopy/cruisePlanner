
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/cruise.dart';
import '../../models/excursion.dart';
import '../../models/excursions/excursion_payment_mode.dart';
import '../../models/excursions/excursion_payment_trigger.dart';
import '../../models/excursions/excursion_payment_method.dart';
import '../../models/excursions/cash_currency_preference.dart';
import '../../screens/excursions/excursion_edit_screen.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';

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

    Cruise? cruise;
    for (final c in store.cruises) {
      if (c.id == widget.cruiseId) {
        cruise = c;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      _cruise = cruise;
      _loading = false;
    });
  }

  Future<void> _openEdit(Excursion ex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExcursionEditScreen(excursionId: ex.id),
      ),
    );
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
              onTap: () => _openEdit(ex),
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
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, Excursion ex) {
    final dateLine = fmtDate(context, ex.date, includeTime: true);
    final portLine = ex.port?.isNotEmpty == true ? ex.port! : null;
    final paymentText = _buildPaymentSummary(context, ex);
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

  String _buildPaymentSummary(BuildContext context, Excursion ex) {
    final plan = ex.paymentPlan;
    final price = ex.price;
    final currency = ex.currency ?? '';
    final loc = AppLocalizations.of(context)!;

    String priceStr;
    if (price != null) {
      priceStr = fmtMoney(context, price, currency: currency);
    } else {
      priceStr = '';
    }

    if (plan == null || plan.parts.isEmpty) {
      if (priceStr.isEmpty) {
        return loc.noPaymentInformation;
      }
      return '${loc.price} $priceStr';
    }

    final onBooking = plan.parts
        .where((p) => p.trigger == ExcursionPaymentTrigger.onBooking)
        .toList();
    final beforeDate = plan.parts
        .where((p) => p.trigger == ExcursionPaymentTrigger.beforeDate)
        .toList();
    final onSite = plan.parts
        .where((p) => p.trigger == ExcursionPaymentTrigger.onSite)
        .toList();

    final totalOpen = plan.openAmount;

    switch (plan.mode) {
      case ExcursionPaymentMode.fullOnBooking:
        if (plan.isFullyPaid) {
          return priceStr.isEmpty
              ? loc.fullyPayed
              : '${loc.fullyPayed} ($priceStr)';
        } else {
          return priceStr.isEmpty
              ? '${loc.payOnBooking}, ${loc.stillOpen}'
              : '${loc.payOnBooking}: $priceStr (${loc.stillOpen})';
        }

      case ExcursionPaymentMode.depositAndRestDate:
        final deposit = onBooking.isNotEmpty ? onBooking.first : null;
        final rest = beforeDate.isNotEmpty ? beforeDate.first : null;
        

        final depositStr =
            deposit != null ? fmtNumber(context, deposit.amount) : '-';
        final restStr =
            rest != null ? fmtNumber(context, rest.amount) : '-';
        final restDateStr = rest?.dueDate != null
            ? fmtDate(context, rest!.dueDate)
            : loc.withoutDate;

        final depositStatus =
            deposit?.isPaid == true ? loc.payed : loc.open;
        final restStatus = rest?.isPaid == true ? loc.payed : loc.open;

        return '${loc.deposit} $depositStr $currency ($depositStatus), '
            '${loc.finalPayment} $restStr $currency - $restDateStr ($restStatus)';

      case ExcursionPaymentMode.depositAndRestOnSite:
        final deposit = onBooking.isNotEmpty ? onBooking.first : null;
        final rest = onSite.isNotEmpty ? onSite.first : null;

        final depositStr =
            deposit != null ? fmtNumber(context, deposit.amount) : '-';
        final restStr =
            rest != null ? fmtNumber(context, rest.amount) : '-';
        final depositStatus =
            deposit?.isPaid == true ? loc.payed : loc.open;
        final restStatus = rest?.isPaid == true ? loc.payed : loc.open;

        return '${loc.deposit} $depositStr $currency ($depositStatus), '
            '${loc.finalPayment} $restStr $currency ${loc.onSide} ($restStatus)';

      case ExcursionPaymentMode.fullOnSite:
        if (plan.isFullyPaid) {
          return priceStr.isEmpty
              ? '${loc.payed} ${loc.onSide}'
              : '${loc.payed} ${loc.onSide} ($priceStr)';
        } else {
          if (priceStr.isEmpty) {
            return loc.amountPayableOnSide;
          }
          return '${loc.amountOnSide}: $priceStr '
              '(${loc.open}: ${fmtNumber(context, totalOpen)})';
        }
    }
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
