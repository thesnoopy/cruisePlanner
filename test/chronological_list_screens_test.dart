import 'dart:convert';

import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/route/port_call_item.dart';
import 'package:cruiseplanner/models/route/route_item.dart';
import 'package:cruiseplanner/models/route/sea_day_item.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/models/travel/base_travel.dart';
import 'package:cruiseplanner/models/travel/flight_item.dart';
import 'package:cruiseplanner/screens/excursions/excursion_list_screen.dart';
import 'package:cruiseplanner/screens/route/route_list_screen.dart';
import 'package:cruiseplanner/screens/travel/travel_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('RouteListScreen shows past treatment and scrolls to the current item once', (
    tester,
  ) async {
    await _setSurfaceSize(tester, const Size(420, 480));

    final cruise = _sampleCruise(
      route: <RouteItem>[
        PortCallItem(
          id: 'port-0',
          date: DateTime(2026, 7, 1),
          portName: 'Past Port',
          arrival: DateTime(2026, 7, 1, 8, 0),
          departure: DateTime(2026, 7, 1, 17, 0),
        ),
        for (var i = 1; i <= 8; i++)
          PortCallItem(
            id: 'port-$i',
            date: DateTime(2026, 7, i + 1),
            portName: i == 5 ? 'Current Port' : 'Port $i',
            arrival: DateTime(2026, 7, i + 1, 8, 0),
            departure: DateTime(2026, 7, i + 1, 17, 0),
          ),
      ],
    );
    await _seedCruise(cruise);

    final rebuildKey = GlobalKey<_RebuildHarnessState>();
    await tester.pumpWidget(
      _TestApp(
        child: _RebuildHarness(
          key: rebuildKey,
          builder: () => RouteListScreen(
            cruiseId: cruise.id,
            nowProvider: () => DateTime(2026, 7, 6, 10, 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final currentDy = tester.getTopLeft(find.text('Current Port')).dy;
    expect(currentDy, lessThan(220));
    final initialPosition =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

    await tester.drag(find.byType(Scrollable), const Offset(0, -600));
    await tester.pumpAndSettle();
    final manualPosition =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(manualPosition, greaterThan(initialPosition));

    rebuildKey.currentState!.triggerRebuild();
    await tester.pumpAndSettle();
    final rebuiltPosition =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(rebuiltPosition, manualPosition);
  });

  testWidgets('RouteListScreen scrolls to the first upcoming item when none is current', (
    tester,
  ) async {
    await _setSurfaceSize(tester, const Size(420, 480));

    final cruise = _sampleCruise(
      route: <RouteItem>[
        SeaDayItem(id: 'sea-0', date: DateTime(2026, 7, 1)),
        SeaDayItem(id: 'sea-1', date: DateTime(2026, 7, 2)),
        SeaDayItem(id: 'sea-2', date: DateTime(2026, 7, 3)),
        SeaDayItem(id: 'sea-3', date: DateTime(2026, 7, 4)),
        SeaDayItem(id: 'sea-4', date: DateTime(2026, 7, 5)),
        SeaDayItem(
          id: 'sea-5',
          date: DateTime(2026, 7, 7),
          notes: 'Upcoming Sea Day',
        ),
        SeaDayItem(
          id: 'sea-6',
          date: DateTime(2026, 7, 8),
          notes: 'Sea Day 6',
        ),
        SeaDayItem(
          id: 'sea-7',
          date: DateTime(2026, 7, 9),
          notes: 'Sea Day 7',
        ),
        SeaDayItem(
          id: 'sea-8',
          date: DateTime(2026, 7, 10),
          notes: 'Sea Day 8',
        ),
      ],
    );
    await _seedCruise(cruise);

    await tester.pumpWidget(
      _TestApp(
        child: RouteListScreen(
          cruiseId: cruise.id,
          nowProvider: () => DateTime(2026, 7, 6, 23, 59),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final upcomingDy = tester.getTopLeft(find.text('Upcoming Sea Day')).dy;
    expect(upcomingDy, lessThan(220));
  });

  testWidgets('RouteListScreen does not auto-scroll when all items are past', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _setSurfaceSize(tester, const Size(420, 480));

      final cruise = _sampleCruise(
        route: <RouteItem>[
          for (var i = 0; i < 8; i++)
            PortCallItem(
              id: 'past-$i',
              date: DateTime(2026, 7, i + 1),
              portName: 'Past $i',
              arrival: DateTime(2026, 7, i + 1, 8, 0),
              departure: DateTime(2026, 7, i + 1, 17, 0),
            ),
        ],
      );
      await _seedCruise(cruise);

      await tester.pumpWidget(
        _TestApp(
          child: RouteListScreen(
            cruiseId: cruise.id,
            nowProvider: () => DateTime(2026, 7, 20, 12, 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Past item')), findsWidgets);
      final pastTitle = tester.widget<Text>(find.text('Past 0'));
      expect(pastTitle.style?.color, isNotNull);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final scrollPosition = scrollable.position.pixels;
      expect(
        scrollPosition,
        moreOrLessEquals(scrollable.position.minScrollExtent, epsilon: 0.01),
      );
      expect(tester.getTopLeft(find.text('Past 0')).dy, lessThan(220));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('RouteListScreen empty list keeps empty state', (tester) async {
    final cruise = _sampleCruise();
    await _seedCruise(cruise);

    await tester.pumpWidget(
      _TestApp(
        child: RouteListScreen(
          cruiseId: cruise.id,
          nowProvider: () => DateTime(2026, 7, 20, 12, 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Harbour today or in Future'), findsOneWidget);
  });

  testWidgets('ExcursionListScreen shows past visual treatment', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final cruise = _sampleCruise(
        excursions: <Excursion>[
          Excursion(
            id: 'exc-1',
            title: 'Past Excursion',
            date: DateTime(2026, 7, 4),
            port: 'Palma',
          ),
        ],
      );
      await _seedCruise(cruise);

      await tester.pumpWidget(
        _TestApp(
          child: ExcursionListScreen(
            cruiseId: cruise.id,
            nowProvider: () => DateTime(2026, 7, 5, 0, 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Past item')), findsOneWidget);
      final title = tester.widget<Text>(find.text('Past Excursion'));
      expect(title.style?.color, isNotNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('TravelListScreen shows past visual treatment', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final cruise = _sampleCruise(
        travel: <TravelItem>[
          FlightItem(
            id: 'flight-1',
            start: DateTime(2026, 7, 4, 8, 0),
            end: DateTime(2026, 7, 4, 10, 0),
            from: 'HAM',
            to: 'BCN',
          ),
        ],
      );
      await _seedCruise(cruise);

      await tester.pumpWidget(
        _TestApp(
          child: TravelListScreen(
            cruiseId: cruise.id,
            nowProvider: () => DateTime(2026, 7, 4, 12, 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Past item')), findsOneWidget);
      final routeText = tester.widget<Text>(find.textContaining('HAM'));
      expect(routeText.style?.color, isNotNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'RouteListScreen brings an initially off-screen current item into view only once',
    (tester) async {
      await _setSurfaceSize(tester, const Size(420, 320));

      final routeItems = <RouteItem>[
        for (var i = 0; i < 24; i++)
          PortCallItem(
            id: 'past-long-$i',
            date: DateTime(2026, 6, i + 1),
            portName: 'Past Long $i',
            arrival: DateTime(2026, 6, i + 1, 8, 0),
            departure: DateTime(2026, 6, i + 1, 17, 0),
          ),
        PortCallItem(
          id: 'current-offscreen',
          date: DateTime(2026, 7, 6),
          portName: 'Current Offscreen Port',
          arrival: DateTime(2026, 7, 6, 8, 0),
          departure: DateTime(2026, 7, 6, 17, 0),
        ),
        for (var i = 0; i < 10; i++)
          PortCallItem(
            id: 'future-$i',
            date: DateTime(2026, 7, 7 + i),
            portName: 'Future $i',
            arrival: DateTime(2026, 7, 7 + i, 8, 0),
            departure: DateTime(2026, 7, 7 + i, 17, 0),
          ),
      ];

      final cruise = _sampleCruise(route: routeItems);
      await _seedCruise(cruise);

      final rebuildKey = GlobalKey<_RebuildHarnessState>();
      await tester.pumpWidget(
        _TestApp(
          child: _RebuildHarness(
            key: rebuildKey,
            builder: () => RouteListScreen(
              cruiseId: cruise.id,
              nowProvider: () => DateTime(2026, 7, 6, 10, 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentFinder = find.text('Current Offscreen Port');
      expect(currentFinder, findsOneWidget);
      final initialPosition =
          tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      expect(initialPosition, greaterThan(0));
      expect(tester.getTopLeft(currentFinder).dy, lessThan(120));

      await tester.drag(find.byType(Scrollable), const Offset(0, -1200));
      await tester.pumpAndSettle();
      final manualPosition =
          tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      expect(manualPosition, greaterThan(initialPosition));

      rebuildKey.currentState!.triggerRebuild();
      await tester.pumpAndSettle();
      final rebuiltPosition =
          tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      expect(rebuiltPosition, manualPosition);
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

class _RebuildHarness extends StatefulWidget {
  const _RebuildHarness({
    super.key,
    required this.builder,
  });

  final Widget Function() builder;

  @override
  State<_RebuildHarness> createState() => _RebuildHarnessState();
}

class _RebuildHarnessState extends State<_RebuildHarness> {
  int _counter = 0;

  void triggerRebuild() {
    setState(() {
      _counter += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _ = _counter;
    return widget.builder();
  }
}

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _seedCruise(Cruise cruise) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'cruises_json_v3': jsonEncode(<String, Object>{
      'schemaVersion': 3,
      'cruises': <Map<String, dynamic>>[cruise.toMap()],
    }),
  });
}

Cruise _sampleCruise({
  List<Excursion> excursions = const <Excursion>[],
  List<RouteItem> route = const <RouteItem>[],
  List<TravelItem> travel = const <TravelItem>[],
}) {
  return Cruise(
    id: 'cruise-1',
    title: 'Test Cruise',
    ship: Ship(name: 'Test Ship'),
    period: Period(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 7, 14),
    ),
    excursions: excursions,
    route: route,
    travel: travel,
  );
}
