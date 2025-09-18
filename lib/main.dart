import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'data/cruise_repository.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';



void main() {
  final repo = CruiseRepository();

  WidgetsFlutterBinding.ensureInitialized();

  // Release-Fehler sichtbar/logbar machen (crash-safe statt "silent")
  FlutterError.onError = (details) {
    Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.empty);
  };
  runZonedGuarded(() {
    runApp(CruiseApp(repo: repo));
  }, (error, stack) {
    // Im Zweifel zumindest loggen (kommt auch im iOS .ips vor)
    // ignore: avoid_print
    print('UNCAUGHT: $error\n$stack');
  });  
}


class CruiseApp extends StatelessWidget {
  
  final CruiseRepository repo;
  
  const CruiseApp({super.key, required this.repo});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Robuste Fallback-Strategie: wenn Gerätelocale unbekannt ist → en
      localeListResolutionCallback: (deviceLocales, supported) {
        if (deviceLocales != null) {
          for (final deviceLocale in deviceLocales) {
            if (supported.any((l) => l.languageCode == deviceLocale.languageCode)) {
              return deviceLocale;
            }
          }
        }
        // Fallback auf Englisch (stelle sicher, dass es app_en.arb gibt)
        return const Locale('en');
      },
      // onGenerateTitle: nutzt L10n erst NACH dem Frame sicher
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)?.appTitle ?? 'Cruise App',
      home: HomeScreen(repo: repo),
    );
  }
}
