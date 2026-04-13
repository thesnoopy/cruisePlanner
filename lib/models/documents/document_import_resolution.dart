import 'document_record.dart';

enum DocumentImportResolutionKind {
  imported,
  existing,
}

class DocumentImportResolution {
  const DocumentImportResolution({
    required this.document,
    required this.kind,
  });

  final DocumentRecord document;
  final DocumentImportResolutionKind kind;
}
