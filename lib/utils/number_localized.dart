import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

num? parseLocalizedNumber(BuildContext context, String raw) {
  final locale = Localizations.localeOf(context).toString();
  final f = NumberFormat.decimalPattern(locale);
  final symbols = f.symbols;

  final cleaned = raw.trim()
      .replaceAll('\u00A0', ' ')                    // NBSP -> Space
      .replaceAll(symbols.GROUP_SEP, '')            // Tausendertrenner raus
      .replaceAll(RegExp('[^0-9${RegExp.escape(symbols.DECIMAL_SEP)}-]'), '');

  if (cleaned.isEmpty) return null;
  return f.parse(cleaned);
}
