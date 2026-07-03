import '../../models/documents/document_analysis_input.dart';
import '../../models/documents/document_analysis_result.dart';
import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_draft.dart';
import '../../models/documents/document_text_extraction_result.dart';
import 'document_semantic_analyzer.dart';
import 'document_text_extraction_service.dart';

class DocumentAnalysisService {
  DocumentAnalysisService({
    DocumentTextExtractionService? textExtractionService,
    DocumentSemanticAnalyzer? semanticAnalyzer,
  })  : _textExtractionService =
            textExtractionService ?? const NoOpDocumentTextExtractionService(),
        _semanticAnalyzer =
            semanticAnalyzer ?? const LocalRuleBasedDocumentSemanticAnalyzer();

  final DocumentTextExtractionService _textExtractionService;
  final DocumentSemanticAnalyzer _semanticAnalyzer;

  Future<DocumentAnalysisResult> analyze(
    DocumentAnalysisInput input,
  ) async {
    final textExtractionResult = input.hasSuppliedText
        ? DocumentTextExtractionResult(
            extractedText: input.extractedText ?? '',
          )
        : await _textExtractionService.extractText(input);

    final analyzerResult = await _semanticAnalyzer.analyze(
      input: input,
      textExtractionResult: textExtractionResult,
    );

    final normalizedDrafts = analyzerResult.drafts
        .map(
          (draft) => draft.sourceReference == input.sourceReference
              ? draft
              : draft.copyWith(sourceReference: input.sourceReference),
        )
        .toList(growable: false);

    if (normalizedDrafts.isEmpty) {
      return analyzerResult.copyWith(
        sourceReference: input.sourceReference,
        drafts: <DocumentImportDraft>[
          DocumentImportDraft(
            targetType: DocumentDraftTargetType.documentOnly,
            sourceReference: input.sourceReference,
          ),
        ],
      );
    }

    return analyzerResult.copyWith(
      sourceReference: input.sourceReference,
      drafts: normalizedDrafts,
    );
  }
}
