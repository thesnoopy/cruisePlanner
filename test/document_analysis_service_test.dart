import 'package:cruiseplanner/models/documents/document_analysis_input.dart';
import 'package:cruiseplanner/models/documents/document_analysis_result.dart';
import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/models/documents/document_text_extraction_result.dart';
import 'package:cruiseplanner/services/documents/document_analysis_service.dart';
import 'package:cruiseplanner/services/documents/document_semantic_analyzer.dart';
import 'package:cruiseplanner/services/documents/document_text_extraction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentAnalysisService', () {
    test('bypasses extraction when text is already supplied', () async {
      final extractor = _FakeDocumentTextExtractionService(
        result: const DocumentTextExtractionResult(extractedText: 'ignored'),
      );
      final analyzer = _CapturingDocumentSemanticAnalyzer(
        result: const DocumentAnalysisResult(),
      );
      final service = DocumentAnalysisService(
        textExtractionService: extractor,
        semanticAnalyzer: analyzer,
      );
      const input = DocumentAnalysisInput(
        sourceReference: DocumentImportSourceReference(documentId: 'doc-1'),
        extractedText: 'already extracted',
      );

      final result = await service.analyze(input);

      expect(extractor.callCount, 0);
      expect(analyzer.lastTextExtractionResult, isNotNull);
      expect(
        analyzer.lastTextExtractionResult!.extractedText,
        'already extracted',
      );
      expect(result.primaryDraft!.isDocumentOnly, isTrue);
    });

    test(
      'converts an empty analyzer result into a document-only fallback',
      () async {
        final service = DocumentAnalysisService(
          textExtractionService: _FakeDocumentTextExtractionService(
            result: const DocumentTextExtractionResult(extractedText: ''),
          ),
          semanticAnalyzer: _CapturingDocumentSemanticAnalyzer(
            result: const DocumentAnalysisResult(),
          ),
        );
        const input = DocumentAnalysisInput(
          sourceReference: DocumentImportSourceReference(
            pendingShareBatchId: 'batch-1',
            pendingShareItemIndex: 1,
          ),
        );

        final result = await service.analyze(input);

        expect(result.sourceReference, input.sourceReference);
        expect(result.drafts, hasLength(1));
        expect(
          result.primaryDraft!.targetType,
          DocumentDraftTargetType.documentOnly,
        );
        expect(result.primaryDraft!.sourceReference, input.sourceReference);
      },
    );

    test(
      'preserves the input source reference on returned analysis results',
      () async {
        const input = DocumentAnalysisInput(
          sourceReference: DocumentImportSourceReference(documentId: 'doc-42'),
        );
        const analyzerDraft = DocumentImportDraft(
          targetType: DocumentDraftTargetType.cruise,
          sourceReference: DocumentImportSourceReference(),
        );
        final service = DocumentAnalysisService(
          textExtractionService: _FakeDocumentTextExtractionService(
            result: const DocumentTextExtractionResult(extractedText: 'ticket'),
          ),
          semanticAnalyzer: _CapturingDocumentSemanticAnalyzer(
            result: const DocumentAnalysisResult(
              drafts: <DocumentImportDraft>[analyzerDraft],
            ),
          ),
        );

        final result = await service.analyze(input);

        expect(result.sourceReference, input.sourceReference);
        expect(result.primaryDraft!.sourceReference, input.sourceReference);
      },
    );

    test(
      'returns analyzer drafts unchanged when they are already useful',
      () async {
        const draft = DocumentImportDraft(
          targetType: DocumentDraftTargetType.excursion,
          sourceReference: DocumentImportSourceReference(
            pendingShareBatchId: 'batch-5',
            pendingShareItemIndex: 2,
          ),
          existingCruiseId: 'cruise-1',
          existingItemId: 'exc-9',
          excursion: ExcursionImportDraft(
            title: 'Harbor tour',
          ),
        );
        const input = DocumentAnalysisInput(
          sourceReference: DocumentImportSourceReference(
            pendingShareBatchId: 'batch-5',
            pendingShareItemIndex: 2,
          ),
        );
        final expectedResult = const DocumentAnalysisResult(
          sourceReference: DocumentImportSourceReference(
            pendingShareBatchId: 'batch-5',
            pendingShareItemIndex: 2,
          ),
          drafts: <DocumentImportDraft>[draft],
        );
        final service = DocumentAnalysisService(
          textExtractionService: _FakeDocumentTextExtractionService(
            result: const DocumentTextExtractionResult(
              extractedText: 'Excursion voucher',
            ),
          ),
          semanticAnalyzer: _CapturingDocumentSemanticAnalyzer(
            result: expectedResult,
          ),
        );

        final result = await service.analyze(input);

        expect(result, expectedResult);
      },
    );
  });
}

class _FakeDocumentTextExtractionService extends DocumentTextExtractionService {
  _FakeDocumentTextExtractionService({
    required this.result,
  });

  final DocumentTextExtractionResult result;
  int callCount = 0;

  @override
  Future<DocumentTextExtractionResult> extractText(
    DocumentAnalysisInput input,
  ) async {
    callCount++;
    return result;
  }
}

class _CapturingDocumentSemanticAnalyzer extends DocumentSemanticAnalyzer {
  _CapturingDocumentSemanticAnalyzer({
    required this.result,
  });

  final DocumentAnalysisResult result;
  DocumentTextExtractionResult? lastTextExtractionResult;

  @override
  Future<DocumentAnalysisResult> analyze({
    required DocumentAnalysisInput input,
    required DocumentTextExtractionResult textExtractionResult,
  }) async {
    lastTextExtractionResult = textExtractionResult;
    return result;
  }
}
