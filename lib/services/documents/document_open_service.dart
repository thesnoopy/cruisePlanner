import 'dart:io';

import 'package:open_filex/open_filex.dart';

import '../../models/documents/document_record.dart';
import 'document_file_store.dart';

class DocumentOpenService {
  DocumentOpenService({
    DocumentFileStore? fileStore,
  }) : _fileStore = fileStore ?? DocumentFileStore();

  final DocumentFileStore _fileStore;

  Future<void> openDocument(DocumentRecord document) async {
    final relativePath = document.localRelativePath.trim();
    if (relativePath.isEmpty) {
      throw ArgumentError.value(
        document.localRelativePath,
        'document.localRelativePath',
        'Invalid path.',
      );
    }

    final file = await _fileStore.resolveAbsoluteFile(relativePath);
    if (!await file.exists()) {
      throw FileSystemException(
        'Document file does not exist.',
        file.path,
      );
    }

    final result = await OpenFilex.open(file.path);

    if (result.type == ResultType.done) {
      return;
    }

    throw FileSystemException(
      _buildOpenErrorMessage(result),
      file.path,
    );
  }

  String _buildOpenErrorMessage(OpenResult result) {
    switch (result.type) {
      case ResultType.fileNotFound:
        return 'Document file does not exist.';
      case ResultType.noAppToOpen:
        return 'No application is available to open this document.';
      case ResultType.permissionDenied:
        return 'Permission denied while opening the document.';
      case ResultType.error:
        final message = result.message.trim();
        if (message.isNotEmpty) {
          return message;
        }
        return 'Failed to open the document.';
      case ResultType.done:
        return '';
    }
  }
}
