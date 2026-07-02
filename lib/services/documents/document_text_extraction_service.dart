import '../../models/documents/document_analysis_input.dart';
import '../../models/documents/document_text_extraction_result.dart';

abstract class DocumentTextExtractionService {
  const DocumentTextExtractionService();

  Future<DocumentTextExtractionResult> extractText(
    DocumentAnalysisInput input,
  );
}

class NoOpDocumentTextExtractionService
    extends DocumentTextExtractionService {
  const NoOpDocumentTextExtractionService();

  @override
  Future<DocumentTextExtractionResult> extractText(
    DocumentAnalysisInput input,
  ) async {
    return const DocumentTextExtractionResult(
      extractedText: '',
      diagnosticReason: 'Text extraction is not implemented.',
    );
  }
}
