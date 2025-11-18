import 'package:flutter/widgets.dart';
import 'package:cruiseplanner/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get t {
    final l = AppLocalizations.of(this);
    if (l != null) return l;
    // Harter Fallback – knallt nicht, gibt neutrale Defaults aus
    return _L10nFallback();
  }
}

// Minimaler Fallback – trage hier nur die paar Strings ein,
// die du an kritischen Stellen direkt beim Start brauchst.
class _L10nFallback implements AppLocalizations {
  @override
  String get appTitle => 'Cruise App';
  @override
  String get homeTitle => 'Home';
  // Weitere häufige Keys nach Bedarf ergänzen …

  // --- Boilerplate: für nicht genutzte Getter eine sichere Default-Implementierung:
  @override
  noSuchMethod(Invocation invocation) => '—';
}
