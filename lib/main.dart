
import 'package:flutter/material.dart';
//import 'package:intl/date_symbol_data_local.dart' as intl;

import 'services/share/share_intake_service.dart';
import 'screens/home_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DateFormat-Locale-Daten initialisieren
  //await intl.initializeDateFormatting('en');
  //await intl.initializeDateFormatting('de');

  await ShareIntakeService().initialize();
  runApp(const CruiseApp());
}

class CruiseApp extends StatelessWidget {
  const CruiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cruise Planer',
      debugShowCheckedModeBanner: false,

      // <<< WICHTIG: Localization einbinden >>>
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Keine explizite locale -> System-/Gerätesprache wird genutzt
      // locale: const Locale('de'), // nur falls du fest auf Deutsch erzwingen willst

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
