import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../models/documents/document_kind.dart';
import '../../models/documents/document_record.dart';
import '../../store/document_store.dart';
import 'document_file_store.dart';

class DocumentImportService {
  DocumentImportService({
    DocumentStore? documentStore,
    DocumentFileStore? fileStore,
    Uuid? uuid,
  })  : _documentStore = documentStore ?? DocumentStore(),
        _fileStore = fileStore ?? DocumentFileStore(),
        _uuid = uuid ?? const Uuid();

  final DocumentStore _documentStore;
  final DocumentFileStore _fileStore;
  final Uuid _uuid;

  Future<DocumentRecord> importFile({
    required File sourceFile,
    String? title,
  }) {
    return _importDocument(
      sourceFile: sourceFile,
      title: title,
    );
  }

  Future<DocumentRecord> importDocument({
    required File sourceFile,
    String? title,
  }) {
    return _importDocument(
      sourceFile: sourceFile,
      title: title,
    );
  }

  Future<DocumentRecord> _importDocument({
    required File sourceFile,
    String? title,
  }) async {
    final sourcePath = sourceFile.path.trim();
    if (sourcePath.isEmpty) {
      throw ArgumentError.value(sourceFile.path, 'sourceFile', 'Invalid path.');
    }

    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist.', sourceFile.path);
    }

    final documentId = _uuid.v4();

    final originalFileName = _extractOriginalFileName(sourceFile.path);
    final fileExtension = _extractFileExtension(originalFileName);
    final storedFile = await _fileStore.copyFileIntoStorage(
      sourceFile: sourceFile,
      documentId: documentId,
      fileExtension: fileExtension,
    );

    final relativePath = _fileStore.buildRelativePath(documentId, fileExtension);
    final contentHash = await _fileStore.calculateContentHash(storedFile);
    final byteSize = await storedFile.length();
    final mimeType = _inferMimeType(fileExtension);
    final kind = _inferDocumentKind(mimeType, fileExtension);
    final resolvedTitle = _resolveTitle(
      explicitTitle: title,
      originalFileName: originalFileName,
    );
    final now = DateTime.now().toUtc();

    final record = DocumentRecord(
      id: documentId,
      kind: kind,
      title: resolvedTitle,
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileExtension: fileExtension,
      localRelativePath: relativePath,
      byteSize: byteSize,
      contentHash: contentHash,
      createdAt: now,
      updatedAt: now,
      deleted: false,
    );

    await _documentStore.saveDocument(record);
    return record;
  }

  String _extractOriginalFileName(String filePath) {
    final fileName = p.basename(filePath).trim();
    return fileName.isEmpty ? 'document.bin' : fileName;
  }

  String _extractFileExtension(String fileName) {
    final extension = p.extension(fileName).trim().toLowerCase();
    if (extension.isEmpty) {
      return 'bin';
    }

    final normalized = extension.startsWith('.')
        ? extension.substring(1)
        : extension;

    return normalized.isEmpty ? 'bin' : normalized;
  }

  String _resolveTitle({
    required String? explicitTitle,
    required String originalFileName,
  }) {
    final normalizedTitle = explicitTitle?.trim();
    if (normalizedTitle != null && normalizedTitle.isNotEmpty) {
      return normalizedTitle;
    }

    final baseName = p.basenameWithoutExtension(originalFileName).trim();
    if (baseName.isNotEmpty) {
      return baseName;
    }

    return originalFileName;
  }

  String _inferMimeType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  DocumentKind _inferDocumentKind(String mimeType, String fileExtension) {
    if (mimeType == 'application/pdf' || fileExtension == 'pdf') {
      final pdfKind = _findKind('pdf');
      if (pdfKind != null) {
        return pdfKind;
      }
    }

    if (mimeType.startsWith('image/')) {
      final imageKind = _findKind('image');
      if (imageKind != null) {
        return imageKind;
      }
    }

    if (mimeType.startsWith('text/')) {
      final textKind = _findKind('text');
      if (textKind != null) {
        return textKind;
      }
    }

    return _findKind('document') ??
        _findKind('file') ??
        _findKind('other') ??
        _findKind('unknown') ??
        DocumentKind.values.first;
  }

  DocumentKind? _findKind(String value) {
    final normalized = value.trim().toLowerCase();

    for (final kind in DocumentKind.values) {
      if (kind.name.toLowerCase() == normalized) {
        return kind;
      }

      if (kind.jsonValue.toLowerCase() == normalized) {
        return kind;
      }
    }

    return null;
  }
}
