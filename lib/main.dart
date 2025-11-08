import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cruiseplanner/gen/l10n/app_localizations.dart';
import 'store/cruise_store.dart';
import 'screens/home_screen.dart';

void main() {
  final store = CruiseStore();
  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final CruiseStore store;
  const MyApp({super.key, required this.store});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: HomeScreen(store: store),
    );
  }
}
