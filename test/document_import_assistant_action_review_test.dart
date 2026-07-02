import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_assistant_action.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/services/documents/document_import_assistant_action_navigator.dart';
import 'package:cruiseplanner/widgets/documents/document_import_assistant_action_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('supported action shows open button', (tester) async {
    final navigator = _FakeDocumentImportAssistantActionNavigator();

    await _pumpLauncher(
      tester,
      action: const DocumentImportAssistantAction.createNewCruise(
        initialCruiseDraft: CruiseImportDraft(title: 'Mediterranean Escape'),
        sourceReference: DocumentImportSourceReference(documentId: 'doc-1'),
      ),
      navigator: navigator,
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Assistant suggestion'), findsOneWidget);
    expect(find.text('Mediterranean Escape'), findsOneWidget);
    expect(find.text('Open edit screen'), findsOneWidget);
  });

  testWidgets('tapping open button calls navigator open path', (tester) async {
    final navigator = _FakeDocumentImportAssistantActionNavigator();
    const action = DocumentImportAssistantAction.editExistingTravel(
      travelItemId: 'travel-1',
      draftTargetType: DocumentDraftTargetType.hotel,
      initialTravelDraft: TravelImportDraft(
        name: 'Harbor View Hotel',
        location: 'Barcelona',
      ),
      sourceReference: DocumentImportSourceReference(documentId: 'doc-2'),
    );

    await _pumpLauncher(
      tester,
      action: action,
      navigator: navigator,
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open edit screen'));
    await tester.pumpAndSettle();

    expect(navigator.openCallCount, 1);
    expect(navigator.lastAction, action);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('manualReview does not show an automatic open path', (
    tester,
  ) async {
    final navigator = _FakeDocumentImportAssistantActionNavigator(
      canOpenResult: false,
    );

    await _pumpLauncher(
      tester,
      action: const DocumentImportAssistantAction.manualReview(
        sourceReference: DocumentImportSourceReference(documentId: 'doc-3'),
      ),
      navigator: navigator,
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This document could not be assigned with enough confidence yet.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open edit screen'), findsNothing);
  });

  testWidgets('unsupported does not show an automatic open path', (
    tester,
  ) async {
    final navigator = _FakeDocumentImportAssistantActionNavigator(
      canOpenResult: false,
    );

    await _pumpLauncher(
      tester,
      action: const DocumentImportAssistantAction.unsupported(
        sourceReference: DocumentImportSourceReference(documentId: 'doc-4'),
      ),
      navigator: navigator,
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No supported assistant action is available for this document yet.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open edit screen'), findsNothing);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required DocumentImportAssistantAction action,
  required DocumentImportAssistantActionNavigator navigator,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: TextButton(
                onPressed: () {
                  showDocumentImportAssistantActionReviewDialog(
                    context: context,
                    action: action,
                    navigator: navigator,
                  );
                },
                child: const Text('Show'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _FakeDocumentImportAssistantActionNavigator
    extends DocumentImportAssistantActionNavigator {
  _FakeDocumentImportAssistantActionNavigator({
    this.canOpenResult = true,
  });

  final bool canOpenResult;

  int openCallCount = 0;
  DocumentImportAssistantAction? lastAction;

  @override
  bool canOpen(DocumentImportAssistantAction action) => canOpenResult;

  @override
  Future<bool> open(
    BuildContext context,
    DocumentImportAssistantAction action,
  ) async {
    openCallCount += 1;
    lastAction = action;
    return true;
  }
}
