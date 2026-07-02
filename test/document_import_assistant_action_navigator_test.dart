import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_assistant_action.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/screens/details/cruise_edit_screen.dart';
import 'package:cruiseplanner/screens/route/route_edit_screen.dart';
import 'package:cruiseplanner/services/documents/document_import_assistant_action_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'open pushes CruiseEditScreen in create mode for createNewCruise',
    (tester) async {
      const navigator = DocumentImportAssistantActionNavigator();
      final draft = CruiseImportDraft(
        title: 'Mediterranean Escape',
        shipName: 'AIDAnova',
      );
      const sourceReference = DocumentImportSourceReference(
        documentId: 'doc-cruise-1',
      );
      final context = await _pumpHarness(tester);

      final didOpen = await navigator.open(
        context,
        DocumentImportAssistantAction.createNewCruise(
          initialCruiseDraft: draft,
          sourceReference: sourceReference,
        ),
      );
      await tester.pumpAndSettle();

      expect(didOpen, isTrue);
      expect(find.byType(CruiseEditScreen), findsOneWidget);
      final screen = tester.widget<CruiseEditScreen>(
        find.byType(CruiseEditScreen),
      );
      expect(screen.cruiseId, isNull);
      expect(screen.initialDraft, draft);
      expect(screen.sourceReference, sourceReference);
    },
  );

  testWidgets(
    'open pushes RouteEditScreen with ids, draft and sourceReference',
    (tester) async {
      const navigator = DocumentImportAssistantActionNavigator();
      final draft = RouteItemImportDraft(
        date: DateTime(2026, 7, 9),
        portName: 'Palma',
        notes: 'Ticket notes',
      );
      const sourceReference = DocumentImportSourceReference(
        documentId: 'doc-route-1',
        pendingShareBatchId: 'batch-1',
        pendingShareItemIndex: 0,
      );
      final context = await _pumpHarness(tester);

      final didOpen = await navigator.open(
        context,
        DocumentImportAssistantAction.editExistingRouteItem(
          cruiseId: 'cruise-1',
          routeItemId: 'route-1',
          draftTargetType: DocumentDraftTargetType.portCall,
          initialRouteItemDraft: draft,
          sourceReference: sourceReference,
        ),
      );
      await tester.pumpAndSettle();

      expect(didOpen, isTrue);
      expect(find.byType(RouteEditScreen), findsOneWidget);
      final screen = tester.widget<RouteEditScreen>(
        find.byType(RouteEditScreen),
      );
      expect(screen.createMode, isFalse);
      expect(screen.cruiseId, 'cruise-1');
      expect(screen.routeItemId, 'route-1');
      expect(screen.draftTargetType, DocumentDraftTargetType.portCall);
      expect(screen.initialDraft, draft);
      expect(screen.sourceReference, sourceReference);
    },
  );

  testWidgets('open returns false for unsupported and manualReview', (
    tester,
  ) async {
    const navigator = DocumentImportAssistantActionNavigator();
    final context = await _pumpHarness(tester);

    final unsupportedDidOpen = await navigator.open(
      context,
      const DocumentImportAssistantAction.unsupported(),
    );
    final manualReviewDidOpen = await navigator.open(
      context,
      const DocumentImportAssistantAction.manualReview(),
    );
    await tester.pumpAndSettle();

    expect(unsupportedDidOpen, isFalse);
    expect(manualReviewDidOpen, isFalse);
    expect(find.byType(CruiseEditScreen), findsNothing);
    expect(find.byType(RouteEditScreen), findsNothing);
  });

  testWidgets('open returns false for invalid missing ids', (tester) async {
    const navigator = DocumentImportAssistantActionNavigator();
    final context = await _pumpHarness(tester);

    final invalidEditDidOpen = await navigator.open(
      context,
      DocumentImportAssistantAction.editExistingRouteItem(
        cruiseId: 'cruise-1',
        routeItemId: '',
        draftTargetType: DocumentDraftTargetType.portCall,
        sourceReference: const DocumentImportSourceReference(),
      ),
    );
    final invalidCreateDidOpen = await navigator.open(
      context,
      DocumentImportAssistantAction.createNewExcursion(
        cruiseId: '',
        sourceReference: const DocumentImportSourceReference(),
      ),
    );
    await tester.pumpAndSettle();

    expect(invalidEditDidOpen, isFalse);
    expect(invalidCreateDidOpen, isFalse);
    expect(find.byType(CruiseEditScreen), findsNothing);
    expect(find.byType(RouteEditScreen), findsNothing);
  });
}

Future<BuildContext> _pumpHarness(WidgetTester tester) async {
  late BuildContext context;

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (buildContext) {
          context = buildContext;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return context;
}
