import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:cruise_app/gen/l10n/app_localizations.dart';

String localeNameOf(BuildContext context) =>
    AppLocalizations.of(context)?.localeName ?? 'en';

String fmtDate(BuildContext ctx, DateTime? dt, {String pattern = 'yMMMd'}) {
  if (dt == null) return '—';
  try {
    return DateFormat(pattern, localeNameOf(ctx)).format(dt);
  } catch (_) {
    // Fallback: sicheres, simples Format
    return DateFormat.yMd().format(dt);
  }
}

String fmtTime(BuildContext ctx, DateTime? dt) {
  if (dt == null) return '—';
  try {
    return DateFormat.jm(localeNameOf(ctx)).format(dt);
  } catch (_) {
    return DateFormat.Hm().format(dt);
  }
}

String fmtMoney(BuildContext ctx, num? value, {String? currency}) {
  if (value == null) return '—';
  try {
    final locale = localeNameOf(ctx);
    if (currency != null && currency.isNotEmpty) {
      return NumberFormat.simpleCurrency(locale: locale, name: currency).format(value);
    }
    return NumberFormat.currency(locale: locale, symbol: '¤').format(value);
  } catch (_) {
    // Fallback neutral
    return '${currency ?? ''} ${value.toStringAsFixed(2)}'.trim();
  }
}

String fmtNumber(BuildContext ctx, num? value) {
  if (value == null) return '—';
  try {
    return NumberFormat.decimalPattern(localeNameOf(ctx)).format(value);
  } catch (_) {
    return value.toString();
  }
}
