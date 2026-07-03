import 'package:cruiseplanner/l10n/app_localizations.dart';
import 'package:cruiseplanner/models/documents/document_kind.dart';
import 'package:cruiseplanner/models/documents/document_record.dart';
import 'package:cruiseplanner/services/documents/document_open_service.dart';
import 'package:cruiseplanner/services/documents/excursion_document_section_service.dart';
import 'package:cruiseplanner/widgets/documents/document_import_assistant_launcher.dart';
import 'package:cruiseplanner/widgets/documents/excursion_documents_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'read-only excursion document rows show the assistant action and keep tap-to-open',
    (tester) async {
      final document = _sampleDocument(documentId: 'doc-1');
      final service = _FakeExcursionDocumentSectionService(
        data: ExcursionDocumentSectionData(
          linkedDocuments: <DocumentRecord>[document],
          availableDocuments: const <DocumentRecord>[],
        ),
      );
      final openService = _FakeDocumentOpenService();
      final assistantLauncher = _FakeDocumentImportAssistantDocumentLauncher();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExcursionDocumentsSection(
              excursionId: 'exc-1',
              isReadOnly: true,
              service: service,
              openService: openService,
              assistantLauncher: assistantLauncher,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Use assistant'), findsOneWidget);

      await tester.tap(find.byTooltip('Use assistant'));
      await tester.pumpAndSettle();

      expect(assistantLauncher.startCallCount, 1);
      expect(assistantLauncher.lastDocument, document);
      expect(openService.openCallCount, 0);

      await tester.tap(find.text('Boarding Pass'));
      await tester.pumpAndSettle();

      expect(openService.openCallCount, 1);
      expect(openService.lastDocument, document);
      expect(assistantLauncher.startCallCount, 1);
    },
  );
}

class _FakeExcursionDocumentSectionService extends ExcursionDocumentSectionService {
  _FakeExcursionDocumentSectionService({
    required this.data,
  });

  final ExcursionDocumentSectionData data;

  @override
  Future<ExcursionDocumentSectionData> loadForExcursion(
    String excursionId,
  ) async {
    return data;
  }
}

class _FakeDocumentOpenService extends DocumentOpenService {
  int openCallCount = 0;
  DocumentRecord? lastDocument;

  @override
  Future<void> openDocument(DocumentRecord document) async {
    openCallCount += 1;
    lastDocument = document;
  }
}

class _FakeDocumentImportAssistantDocumentLauncher
    extends DocumentImportAssistantDocumentLauncher {
  int startCallCount = 0;
  DocumentRecord? lastDocument;

  @override
  Future<bool> startForDocument({
    required BuildContext context,
    required DocumentRecord document,
  }) async {
    startCallCount += 1;
    lastDocument = document;
    return true;
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
