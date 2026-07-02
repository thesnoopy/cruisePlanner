import 'dart:convert';

import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/screens/details/cruise_edit_screen.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'CruiseEditScreen edit mode fills only missing visible fields from draft',
    (tester) async {
      await _seedCruises(<Cruise>[
        Cruise(
          id: 'cruise-1',
          title: 'Existing Title',
          ship: const Ship(name: '', operatorName: 'Existing Operator'),
          period: Period(
            start: DateTime(2026, 7, 1),
            end: DateTime(2026, 7, 8),
          ),
          cabinNumber: null,
          deckNumber: '9',
          deckname: null,
        ),
      ]);

      await tester.pumpWidget(
        _TestApp(
          child: CruiseEditScreen(
            cruiseId: 'cruise-1',
            initialDraft: CruiseImportDraft(
              title: 'Draft Title',
              shipName: 'AIDAblu',
              operatorName: 'Draft Operator',
              cabinNumber: '1234',
              deckNumber: '11',
              deckName: 'Sun',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_textFieldValue(tester, 0), 'Existing Title');
      expect(_textFieldValue(tester, 1), 'AIDAblu');
      expect(_textFieldValue(tester, 2), 'Existing Operator');
      expect(_textFieldValue(tester, 3), '1234');
      expect(_textFieldValue(tester, 4), '9');
      expect(_textFieldValue(tester, 5), 'Sun');
    },
  );

  testWidgets(
    'CruiseEditScreen create mode stays unsaved and prefills from draft',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final fallbackPeriod = Period(
        start: DateTime(2026, 7, 12),
        end: DateTime(2026, 7, 19),
      );

      await tester.pumpWidget(
        _TestApp(
          child: CruiseEditScreen.create(
            fallbackPeriod: fallbackPeriod,
            initialDraft: CruiseImportDraft(
              title: 'Mediterranean Escape',
              shipName: 'AIDAnova',
              operatorName: 'AIDA',
              startDate: DateTime(2026, 7, 10),
              cabinNumber: '8080',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final store = CruiseStore();
      await store.load();

      expect(store.activeCruises, isEmpty);
      expect(_textFieldValue(tester, 0), 'Mediterranean Escape');
      expect(_textFieldValue(tester, 1), 'AIDAnova');
      expect(_textFieldValue(tester, 2), 'AIDA');
      expect(_textFieldValue(tester, 3), '8080');
      expect(
        find.text(DateFormat.yMMMd('en').format(DateTime(2026, 7, 10))),
        findsOneWidget,
      );
      expect(
        find.text(DateFormat.yMMMd('en').format(DateTime(2026, 7, 19))),
        findsOneWidget,
      );
      expect(find.text('Documents'), findsNothing);
    },
  );

  testWidgets(
    'CruiseEditScreen edit mode without draft keeps existing values unchanged',
    (tester) async {
      await _seedCruises(<Cruise>[
        Cruise(
          id: 'cruise-2',
          title: 'Baltic Cruise',
          ship: const Ship(name: 'AIDAmar', operatorName: 'AIDA'),
          period: Period(
            start: DateTime(2026, 8, 1),
            end: DateTime(2026, 8, 8),
          ),
          cabinNumber: '7001',
          deckNumber: '7',
          deckname: 'Ocean',
        ),
      ]);

      await tester.pumpWidget(
        const _TestApp(
          child: CruiseEditScreen(cruiseId: 'cruise-2'),
        ),
      );
      await tester.pumpAndSettle();

      expect(_textFieldValue(tester, 0), 'Baltic Cruise');
      expect(_textFieldValue(tester, 1), 'AIDAmar');
      expect(_textFieldValue(tester, 2), 'AIDA');
      expect(_textFieldValue(tester, 3), '7001');
      expect(_textFieldValue(tester, 4), '7');
      expect(_textFieldValue(tester, 5), 'Ocean');
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

String _textFieldValue(WidgetTester tester, int index) {
  final field = tester.widget<TextFormField>(find.byType(TextFormField).at(index));
  return field.controller?.text ?? '';
}

Future<void> _seedCruises(List<Cruise> cruises) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'cruises_json_v3': jsonEncode(<String, Object>{
      'schemaVersion': 3,
      'cruises': cruises.map((cruise) => cruise.toMap()).toList(growable: false),
    }),
  });
}
