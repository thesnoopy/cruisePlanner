import 'dart:async';

import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/documents/document_analysis_input.dart';
import 'package:cruiseplanner/models/documents/document_analysis_result.dart';
import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_assistant_action.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/services/documents/document_analysis_service.dart';
import 'package:cruiseplanner/services/documents/document_import_assistant_action_navigator.dart';
import 'package:cruiseplanner/services/documents/document_import_assistant_flow_service.dart';
import 'package:cruiseplanner/widgets/documents/document_import_assistant_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'supported analysis result builds an action and shows the review dialog',
    (tester) async {
      final flowService = _FakeDocumentImportAssistantFlowService(
        buildActionResult: const DocumentImportAssistantAction.createNewCruise(
          initialCruiseDraft: CruiseImportDraft(title: 'Mediterranean Escape'),
          sourceReference: DocumentImportSourceReference(documentId: 'doc-1'),
        ),
      );
      final navigator = _FakeDocumentImportAssistantActionNavigator();
      const analysisResult = DocumentAnalysisResult(
        sourceReference: DocumentImportSourceReference(documentId: 'doc-1'),
      );
      bool? result;

      await _pumpLauncher(
        tester,
        analysisResult: analysisResult,
        flowService: flowService,
        navigator: navigator,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(flowService.buildActionCallCount, 1);
      expect(flowService.lastAnalysisResult, analysisResult);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Assistant suggestion'), findsOneWidget);
      expect(find.text('Mediterranean Escape'), findsOneWidget);
      expect(find.text('Open edit screen'), findsOneWidget);
      expect(result, isNull);
    },
  );

  testWidgets('tapping open uses the injected navigator path', (tester) async {
    final flowService = _FakeDocumentImportAssistantFlowService(
      buildActionResult: const DocumentImportAssistantAction.editExistingTravel(
        travelItemId: 'travel-1',
        draftTargetType: DocumentDraftTargetType.hotel,
        initialTravelDraft: TravelImportDraft(
          name: 'Harbor View Hotel',
          location: 'Barcelona',
        ),
        sourceReference: DocumentImportSourceReference(documentId: 'doc-2'),
      ),
    );
    final navigator = _FakeDocumentImportAssistantActionNavigator();
    bool? result;

    await _pumpLauncher(
      tester,
      analysisResult: const DocumentAnalysisResult(
        sourceReference: DocumentImportSourceReference(documentId: 'doc-2'),
      ),
      flowService: flowService,
      navigator: navigator,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open edit screen'));
    await tester.pumpAndSettle();

    expect(navigator.openCallCount, 1);
    expect(
      navigator.lastAction,
      const DocumentImportAssistantAction.editExistingTravel(
        travelItemId: 'travel-1',
        draftTargetType: DocumentDraftTargetType.hotel,
        initialTravelDraft: TravelImportDraft(
          name: 'Harbor View Hotel',
          location: 'Barcelona',
        ),
        sourceReference: DocumentImportSourceReference(documentId: 'doc-2'),
      ),
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(result, isTrue);
  });

  testWidgets(
    'manualReview action from the flow shows a safe review state and no open button',
    (tester) async {
      final flowService = _FakeDocumentImportAssistantFlowService(
        buildActionResult: const DocumentImportAssistantAction.manualReview(
          sourceReference: DocumentImportSourceReference(documentId: 'doc-3'),
        ),
      );
      final navigator = _FakeDocumentImportAssistantActionNavigator(
        canOpenResult: false,
      );
      bool? result;

      await _pumpLauncher(
        tester,
        analysisResult: const DocumentAnalysisResult(
          sourceReference: DocumentImportSourceReference(documentId: 'doc-3'),
        ),
        flowService: flowService,
        navigator: navigator,
        onResult: (value) => result = value,
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

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(navigator.openCallCount, 0);
      expect(result, isFalse);
    },
  );

  testWidgets(
    'unsupported action from the flow shows a safe review state and no open button',
    (tester) async {
      final flowService = _FakeDocumentImportAssistantFlowService(
        buildActionResult: const DocumentImportAssistantAction.unsupported(
          sourceReference: DocumentImportSourceReference(documentId: 'doc-4'),
        ),
      );
      final navigator = _FakeDocumentImportAssistantActionNavigator(
        canOpenResult: false,
      );

      await _pumpLauncher(
        tester,
        analysisResult: const DocumentAnalysisResult(
          sourceReference: DocumentImportSourceReference(documentId: 'doc-4'),
        ),
        flowService: flowService,
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
    },
  );

  testWidgets('no dialog is shown when the launcher context is unmounted', (
    tester,
  ) async {
    final completer = Completer<DocumentImportAssistantAction>();
    final flowService = _FakeDocumentImportAssistantFlowService(
      buildActionFuture: completer.future,
    );
    final navigator = _FakeDocumentImportAssistantActionNavigator();
    final harnessKey = GlobalKey<_UnmountableLauncherHarnessState>();
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _UnmountableLauncherHarness(
          key: harnessKey,
          analysisResult: const DocumentAnalysisResult(
            sourceReference: DocumentImportSourceReference(documentId: 'doc-5'),
          ),
          flowService: flowService,
          navigator: navigator,
          onResult: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    harnessKey.currentState!.hideLauncher();
    await tester.pump();

    completer.complete(
      const DocumentImportAssistantAction.createNewCruise(
        initialCruiseDraft: CruiseImportDraft(title: 'Late Result'),
        sourceReference: DocumentImportSourceReference(documentId: 'doc-5'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(navigator.openCallCount, 0);
    expect(result, isFalse);
  });

  testWidgets(
    'existing document launcher analyzes the selected document and shows the review dialog',
    (tester) async {
      final analysisService = _FakeDocumentAnalysisService(
        analyzeResult: const DocumentAnalysisResult(
          sourceReference: DocumentImportSourceReference(documentId: 'doc-9'),
        ),
      );
      final flowService = _FakeDocumentImportAssistantFlowService(
        buildActionResult: const DocumentImportAssistantAction.createNewCruise(
          initialCruiseDraft: CruiseImportDraft(title: 'Baltic Voyage'),
          sourceReference: DocumentImportSourceReference(documentId: 'doc-9'),
        ),
      );
      final launcher = DocumentImportAssistantDocumentLauncher(
        analysisService: analysisService,
        flowService: flowService,
      );
      bool? result;

      await _pumpDocumentLauncher(
        tester,
        document: _sampleDocument(documentId: 'doc-9'),
        launcher: launcher,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(analysisService.analyzeCallCount, 1);
      expect(
        analysisService.lastInput,
        const DocumentAnalysisInput(
          sourceReference: DocumentImportSourceReference(documentId: 'doc-9'),
          documentId: 'doc-9',
          originalFileName: 'doc-9.pdf',
          title: 'Boarding Pass',
          mimeType: 'application/pdf',
          localRelativePath: 'documents/doc-9/original.pdf',
        ),
      );
      expect(flowService.buildActionCallCount, 1);
      expect(
        flowService.lastAnalysisResult,
        const DocumentAnalysisResult(
          sourceReference: DocumentImportSourceReference(documentId: 'doc-9'),
        ),
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(result, isNull);
    },
  );

  testWidgets('existing document launcher shows a snackbar when analysis fails', (
    tester,
  ) async {
    final analysisService = _FakeDocumentAnalysisService(
      analyzeError: StateError('analysis failed'),
    );
    final launcher = DocumentImportAssistantDocumentLauncher(
      analysisService: analysisService,
    );
    bool? result;

    await _pumpDocumentLauncher(
      tester,
      document: _sampleDocument(documentId: 'doc-10'),
      launcher: launcher,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(analysisService.analyzeCallCount, 1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Assistant could not be started.'), findsOneWidget);
    expect(result, isFalse);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required DocumentAnalysisResult analysisResult,
  required DocumentImportAssistantFlowService flowService,
  required DocumentImportAssistantActionNavigator navigator,
  ValueChanged<bool>? onResult,
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
                onPressed: () async {
                  final result =
                      await showDocumentImportAssistantForAnalysisResult(
                    context: context,
                    analysisResult: analysisResult,
                    flowService: flowService,
                    navigator: navigator,
                  );
                  onResult?.call(result);
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

Future<void> _pumpDocumentLauncher(
  WidgetTester tester, {
  required DocumentRecord document,
  required DocumentImportAssistantDocumentLauncher launcher,
  ValueChanged<bool>? onResult,
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
                onPressed: () async {
                  final result = await launcher.startForDocument(
                    context: context,
                    document: document,
                  );
                  onResult?.call(result);
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

class _FakeDocumentImportAssistantFlowService
    extends DocumentImportAssistantFlowService {
  _FakeDocumentImportAssistantFlowService({
    DocumentImportAssistantAction? buildActionResult,
    Future<DocumentImportAssistantAction>? buildActionFuture,
  }) : _buildActionFuture =
           buildActionFuture ?? Future.value(buildActionResult!);

  final Future<DocumentImportAssistantAction> _buildActionFuture;

  int buildActionCallCount = 0;
  DocumentAnalysisResult? lastAnalysisResult;

  @override
  Future<DocumentImportAssistantAction> buildAction(
    DocumentAnalysisResult analysisResult,
  ) {
    buildActionCallCount += 1;
    lastAnalysisResult = analysisResult;
    return _buildActionFuture;
  }
}

class _FakeDocumentAnalysisService extends DocumentAnalysisService {
  _FakeDocumentAnalysisService({
    this.analyzeResult,
    this.analyzeError,
  });

  final DocumentAnalysisResult? analyzeResult;
  final Object? analyzeError;

  int analyzeCallCount = 0;
  DocumentAnalysisInput? lastInput;

  @override
  Future<DocumentAnalysisResult> analyze(
    DocumentAnalysisInput input,
  ) async {
    analyzeCallCount += 1;
    lastInput = input;
    if (analyzeError != null) {
      throw analyzeError!;
    }
    return analyzeResult!;
  }
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

class _UnmountableLauncherHarness extends StatefulWidget {
  const _UnmountableLauncherHarness({
    super.key,
    required this.analysisResult,
    required this.flowService,
    required this.navigator,
    this.onResult,
  });

  final DocumentAnalysisResult analysisResult;
  final DocumentImportAssistantFlowService flowService;
  final DocumentImportAssistantActionNavigator navigator;
  final ValueChanged<bool>? onResult;

  @override
  State<_UnmountableLauncherHarness> createState() =>
      _UnmountableLauncherHarnessState();
}

class _UnmountableLauncherHarnessState
    extends State<_UnmountableLauncherHarness> {
  bool _showLauncher = true;

  void hideLauncher() {
    setState(() {
      _showLauncher = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showLauncher
          ? Builder(
              builder: (launcherContext) {
                return Center(
                  child: TextButton(
                    onPressed: () async {
                      final result =
                          await showDocumentImportAssistantForAnalysisResult(
                        context: launcherContext,
                        analysisResult: widget.analysisResult,
                        flowService: widget.flowService,
                        navigator: widget.navigator,
                      );
                      widget.onResult?.call(result);
                    },
                    child: const Text('Show'),
                  ),
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }
}

DocumentRecord _sampleDocument({
  required String documentId,
}) {
  final timestamp = DateTime.utc(2026, 7, 1, 12);
  return DocumentRecord(
    id: documentId,
    kind: DocumentKind.pdf,
    title: 'Boarding Pass',
    originalFileName: '$documentId.pdf',
    mimeType: 'application/pdf',
    fileExtension: 'pdf',
    localRelativePath: 'documents/$documentId/original.pdf',
    byteSize: 3,
    contentHash: 'hash-$documentId',
    createdAt: timestamp,
    updatedAt: timestamp,
    deleted: false,
  );
}
