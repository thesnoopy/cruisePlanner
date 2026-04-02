import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/format.dart';
import '../excursion.dart';
import 'excursion_payment_mode.dart';
import 'excursion_payment_trigger.dart';

extension ExcursionPaymentStatusExtension on Excursion {
  String paymentStatusText(BuildContext context) {
    final plan = paymentPlan;
    final price = this.price;
    final currency = this.currency ?? '';
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
        final restStr = rest != null ? fmtNumber(context, rest.amount) : '-';
        final restDateStr = rest?.dueDate != null
            ? fmtDate(context, rest!.dueDate)
            : loc.withoutDate;

        final depositStatus = deposit?.isPaid == true ? loc.payed : loc.open;
        final restStatus = rest?.isPaid == true ? loc.payed : loc.open;

        return '${loc.deposit} $depositStr $currency ($depositStatus), '
            '${loc.finalPayment} $restStr $currency - $restDateStr ($restStatus)';

      case ExcursionPaymentMode.depositAndRestOnSite:
        final deposit = onBooking.isNotEmpty ? onBooking.first : null;
        final rest = onSite.isNotEmpty ? onSite.first : null;

        final depositStr =
            deposit != null ? fmtNumber(context, deposit.amount) : '-';
        final restStr = rest != null ? fmtNumber(context, rest.amount) : '-';
        final depositStatus = deposit?.isPaid == true ? loc.payed : loc.open;
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
}
