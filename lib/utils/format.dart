import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:cruiseplanner/l10n/app_localizations.dart';

String localeNameOf(BuildContext context) =>
    AppLocalizations.of(context)?.localeName ?? 'en';

String fmtDate(
  BuildContext context,
  DateTime? dt, {
  bool includeTime = false,
  bool timeOnly = false,
  String? pattern,
}) {
  if (dt == null) return '';

  final locale = localeNameOf(context);

  try {
    // 1) Explizites Pattern hat höchste Priorität
    if (pattern != null && pattern.isNotEmpty) {
      return DateFormat(pattern, locale).format(dt);
    }

    // 2) Nur Zeit
    if (timeOnly) {
      return DateFormat.jm(locale).format(dt);
    }

    // 3) Datum + Zeit
    if (includeTime) {
      final datePart = DateFormat.yMMMd(locale).format(dt);
      final timePart = DateFormat.jm(locale).format(dt);
      return '$datePart $timePart';
    }

    // 4) Default: nur Datum
    return DateFormat.yMMMd(locale).format(dt);
  } catch (e, stack) {
    // Hier siehst du im Log, warum es schiefgeht
    debugPrint('fmtDate error for locale "$locale": $e');
    // Fallback: neutrale Datumsausgabe im Default-Locale
    try {
      return DateFormat.yMMMd().format(dt);
    } catch (_) {
      // Allerletzter Fallback
      return dt.toIso8601String();
    }
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
    return NumberFormat.currency(locale: locale, symbol: '').format(value);
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

// in format.dart

num? parseLocalizedNumber(BuildContext context, String? input) {
  if (input == null) return null;
  var text = input.trim();
  if (text.isEmpty) return null;

  final locale = localeNameOf(context);

  // 1. Versuch: richtig über intl nach Locale parsen
  try {
    final format = NumberFormat.decimalPattern(locale);
    return format.parse(text);
  } catch (_) {
    // Ignorieren, wir versuchen einen robusteren Fallback
  }

  // 2. Fallback: einfache Heuristik für Komma/Punkt
  // Entferne Leerzeichen
  text = text.replaceAll(' ', '');

  // Fall a: nur Komma → Komma ist Dezimaltrenner (deutscher Stil)
  if (text.contains(',') && !text.contains('.')) {
    text = text.replaceAll('.', '');   // evtl. Tausenderpunkte
    text = text.replaceAll(',', '.');  // Dezimaltrenner auf Punkt
  }
  // Fall b: nur Punkt → Punkt ist Dezimaltrenner (englischer Stil)
  else if (text.contains('.') && !text.contains(',')) {
    // nichts weiter tun
  }
  // Fall c: Punkt und Komma → letztes Symbol ist Dezimaltrenner
  else if (text.contains('.') && text.contains(',')) {
    final lastComma = text.lastIndexOf(',');
    final lastDot = text.lastIndexOf('.');
    final decimalIndex = lastComma > lastDot ? lastComma : lastDot;
    final decimalSep = text[decimalIndex];
    final thousandsSep = decimalSep == '.' ? ',' : '.';

    final before = text.substring(0, decimalIndex).replaceAll(thousandsSep, '');
    final after = text.substring(decimalIndex + 1).replaceAll(thousandsSep, '');
    text = '$before.$after';
  }

  return num.tryParse(text);
}
