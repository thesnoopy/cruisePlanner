import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'data/cruise_repository.dart';
import 'package:cruise_app/gen/l10n/app_localizations.dart';



void main() {
  final repo = CruiseRepository();
  runApp(CruiseApp(repo: repo));
}

class CruiseApp extends StatelessWidget {
  
  final CruiseRepository repo;
  
  const CruiseApp({super.key, required this.repo});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: HomeScreen(repo: repo),
    );
  }
}
