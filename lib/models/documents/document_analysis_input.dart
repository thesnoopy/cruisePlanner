import 'package:equatable/equatable.dart';

import 'document_import_source_reference.dart';

class DocumentAnalysisInput extends Equatable {
  static const Object _unset = Object();

  final DocumentImportSourceReference sourceReference;
  final String? documentId;
  final String? originalFileName;
  final String? title;
  final String? mimeType;
  final String? localRelativePath;
  final String? extractedText;

  const DocumentAnalysisInput({
    required this.sourceReference,
    this.documentId,
    this.originalFileName,
    this.title,
    this.mimeType,
    this.localRelativePath,
    this.extractedText,
  });

  String? get resolvedDocumentId {
    final normalizedDocumentId = documentId?.trim();
    if (normalizedDocumentId != null && normalizedDocumentId.isNotEmpty) {
      return normalizedDocumentId;
    }

    final sourceDocumentId = sourceReference.documentId?.trim();
    if (sourceDocumentId != null && sourceDocumentId.isNotEmpty) {
      return sourceDocumentId;
    }

    return null;
  }

  bool get hasSuppliedText => extractedText != null;

  DocumentAnalysisInput copyWith({
    DocumentImportSourceReference? sourceReference,
    Object? documentId = _unset,
    Object? originalFileName = _unset,
    Object? title = _unset,
    Object? mimeType = _unset,
    Object? localRelativePath = _unset,
    Object? extractedText = _unset,
  }) {
    return DocumentAnalysisInput(
      sourceReference: sourceReference ?? this.sourceReference,
      documentId: identical(documentId, _unset)
          ? this.documentId
          : documentId as String?,
      originalFileName: identical(originalFileName, _unset)
          ? this.originalFileName
          : originalFileName as String?,
      title: identical(title, _unset) ? this.title : title as String?,
      mimeType: identical(mimeType, _unset)
          ? this.mimeType
          : mimeType as String?,
      localRelativePath: identical(localRelativePath, _unset)
          ? this.localRelativePath
          : localRelativePath as String?,
      extractedText: identical(extractedText, _unset)
          ? this.extractedText
          : extractedText as String?,
    );
  }

  @override
  List<Object?> get props => [
        sourceReference,
        documentId,
        originalFileName,
        title,
        mimeType,
        localRelativePath,
        extractedText,
      ];
}
