import 'package:equatable/equatable.dart';

import 'document_draft_confidence.dart';
import 'document_import_draft.dart';
import 'document_import_source_reference.dart';

class DocumentAnalysisResult extends Equatable {
  static const Object _unset = Object();

  final DocumentImportSourceReference sourceReference;
  final List<DocumentImportDraft> drafts;
  final DocumentDraftConfidence? confidence;
  final String? summary;

  const DocumentAnalysisResult({
    this.sourceReference = const DocumentImportSourceReference(),
    this.drafts = const <DocumentImportDraft>[],
    this.confidence,
    this.summary,
  });

  bool get hasDrafts => drafts.isNotEmpty;

  DocumentImportDraft? get primaryDraft =>
      drafts.isEmpty ? null : drafts.first;

  DocumentAnalysisResult copyWith({
    DocumentImportSourceReference? sourceReference,
    List<DocumentImportDraft>? drafts,
    Object? confidence = _unset,
    Object? summary = _unset,
  }) {
    return DocumentAnalysisResult(
      sourceReference: sourceReference ?? this.sourceReference,
      drafts: drafts ?? this.drafts,
      confidence: identical(confidence, _unset)
          ? this.confidence
          : confidence as DocumentDraftConfidence?,
      summary: identical(summary, _unset) ? this.summary : summary as String?,
    );
  }

  @override
  List<Object?> get props => [
        sourceReference,
        drafts,
        confidence,
        summary,
      ];
}
