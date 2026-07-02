import 'package:equatable/equatable.dart';

class DocumentImportSourceReference extends Equatable {
  static const Object _unset = Object();

  final String? documentId;
  final String? pendingShareBatchId;
  final int? pendingShareItemIndex;

  const DocumentImportSourceReference({
    this.documentId,
    this.pendingShareBatchId,
    this.pendingShareItemIndex,
  });

  bool get hasDocumentId => documentId != null && documentId!.isNotEmpty;

  bool get hasPendingShareReference =>
      pendingShareBatchId != null &&
      pendingShareBatchId!.isNotEmpty &&
      pendingShareItemIndex != null;

  DocumentImportSourceReference copyWith({
    Object? documentId = _unset,
    Object? pendingShareBatchId = _unset,
    Object? pendingShareItemIndex = _unset,
  }) {
    return DocumentImportSourceReference(
      documentId: identical(documentId, _unset)
          ? this.documentId
          : documentId as String?,
      pendingShareBatchId: identical(pendingShareBatchId, _unset)
          ? this.pendingShareBatchId
          : pendingShareBatchId as String?,
      pendingShareItemIndex: identical(pendingShareItemIndex, _unset)
          ? this.pendingShareItemIndex
          : pendingShareItemIndex as int?,
    );
  }

  @override
  List<Object?> get props => [
        documentId,
        pendingShareBatchId,
        pendingShareItemIndex,
      ];
}
