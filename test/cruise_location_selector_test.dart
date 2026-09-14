import 'dart:convert';

import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/cruise_location.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:cruiseplanner/widgets/cruise_location_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cruise_location_migration_test.dart' show legacyLocationPayload;

void main() {
  testWidgets('selector lists route first, selects existing location, creates '
      'and persists a stop point without resetting the surrounding form', (tester) async {
    SharedPreferences.setMockInitialValues({
      'cruises_json_v3': jsonEncode(legacyLocationPayload()),
    });
    final title = TextEditingController(text: 'Unsaved excursion title');
    addTearDown(title.dispose);
    String? selectedId;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StatefulBuilder(builder: (context, update) => Column(
        children: [
          TextField(controller: title),
          CruiseLocationSelector(
            cruiseId: 'cruise-1', locationId: selectedId,
            onChanged: (id) => update(() => selectedId = id),
          ),
        ],
      ))),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select a location'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Porto')).dy,
        lessThan(tester.getTopLeft(find.text('Santiago de Compostela')).dy));
    await tester.tap(find.text('Porto'));
    await tester.pumpAndSettle();
    expect(selectedId, isNotNull);
    final originalId = selectedId;
    await tester.tap(find.text('Porto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(AlertDialog),
        matching: find.byType(TextFormField)), 'San Francisco');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(selectedId, isNot(originalId));
    expect(find.text('San Francisco'), findsOneWidget);
    expect(title.text, 'Unsaved excursion title');
    final store = CruiseStore();
    addTearDown(store.dispose);
    await store.load();
    final location = store.getCruise('cruise-1')!.locationById(selectedId)!;
    expect(location.name, 'San Francisco');
    expect(location.type, CruiseLocationType.stopPoint);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cancelling location creation preserves the existing selection', (tester) async {
    SharedPreferences.setMockInitialValues({
      'cruises_json_v3': jsonEncode(legacyLocationPayload()),
    });
    final store = CruiseStore();
    addTearDown(store.dispose);
    await store.load();
    final id = store.locationChoices('cruise-1').first.id;
    var changes = 0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CruiseLocationSelector(
        cruiseId: 'cruise-1', locationId: id,
        onChanged: (_) => changes++,
      )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Porto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(find.text('Porto'), findsOneWidget);
    await store.load();
    expect(store.getCruise('cruise-1')!.locations, hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
