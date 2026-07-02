import '../../models/documents/document_analysis_input.dart';
import '../../models/documents/document_analysis_result.dart';
import '../../models/documents/document_text_extraction_result.dart';

abstract class DocumentSemanticAnalyzer {
  const DocumentSemanticAnalyzer();

  Future<DocumentAnalysisResult> analyze({
    required DocumentAnalysisInput input,
    required DocumentTextExtractionResult textExtractionResult,
  });
}

class NoOpDocumentSemanticAnalyzer extends DocumentSemanticAnalyzer {
  const NoOpDocumentSemanticAnalyzer();

  @override
  Future<DocumentAnalysisResult> analyze({
    required DocumentAnalysisInput input,
    required DocumentTextExtractionResult textExtractionResult,
  }) async {
    return DocumentAnalysisResult(
      sourceReference: input.sourceReference,
    );
  }
}
