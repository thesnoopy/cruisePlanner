import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DocumentFileStore {
  static const String _documentsFolderName = 'documents';
  static const String _originalFileBaseName = 'original';

  Future<Directory> getRootDirectory() async {
    final applicationDirectory = await getApplicationDocumentsDirectory();
    return Directory(
      p.join(applicationDirectory.path, _documentsFolderName),
    );
  }

  Future<Directory> createDocumentDirectory(String documentId) async {
    final normalizedDocumentId = documentId.trim();
    if (normalizedDocumentId.isEmpty) {
      throw ArgumentError.value(documentId, 'documentId', 'Must not be empty.');
    }

    final rootDirectory = await getRootDirectory();
    final directory = Directory(
      p.join(rootDirectory.path, normalizedDocumentId),
    );

    await directory.create(recursive: true);
    return directory;
  }

  String buildRelativePath(String documentId, String fileExtension) {
    final normalizedDocumentId = documentId.trim();
    final normalizedExtension = _normalizeExtension(fileExtension);

    if (normalizedDocumentId.isEmpty) {
      throw ArgumentError.value(documentId, 'documentId', 'Must not be empty.');
    }

    if (normalizedExtension.isEmpty) {
      throw ArgumentError.value(
        fileExtension,
        'fileExtension',
        'Must not be empty.',
      );
    }

    return p
        .join(
          _documentsFolderName,
          normalizedDocumentId,
          '$_originalFileBaseName.$normalizedExtension',
        )
        .replaceAll('\\', '/');
  }

  Future<File> resolveAbsoluteFile(String relativePath) async {
    final normalizedRelativePath = relativePath.trim();
    if (normalizedRelativePath.isEmpty) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Must not be empty.',
      );
    }

    final applicationDirectory = await getApplicationDocumentsDirectory();
    return File(
      p.join(
        applicationDirectory.path,
        normalizedRelativePath.replaceAll('/', p.separator),
      ),
    );
  }

  Future<File> copyFileIntoStorage({
    required File sourceFile,
    required String documentId,
    required String fileExtension,
  }) async {
    await createDocumentDirectory(documentId);

    final relativePath = buildRelativePath(documentId, fileExtension);
    final destinationFile = await resolveAbsoluteFile(relativePath);

    await destinationFile.parent.create(recursive: true);
    return sourceFile.copy(destinationFile.path);
  }

  Future<File> writeBytesIntoStorage({
    required Uint8List bytes,
    required String documentId,
    required String fileExtension,
  }) async {
    await createDocumentDirectory(documentId);

    final relativePath = buildRelativePath(documentId, fileExtension);
    final destinationFile = await resolveAbsoluteFile(relativePath);

    await destinationFile.parent.create(recursive: true);
    await destinationFile.writeAsBytes(bytes, flush: true);
    return destinationFile;
  }

  Future<String> calculateContentHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<bool> fileExists(String relativePath) async {
    final file = await resolveAbsoluteFile(relativePath);
    return file.exists();
  }

  Future<bool> deleteFile(String relativePath) async {
    final file = await resolveAbsoluteFile(relativePath);
    if (!await file.exists()) {
      return false;
    }

    await file.delete();
    await _deleteDocumentDirectoryIfEmpty(relativePath);
    return true;
  }

  Future<void> _deleteDocumentDirectoryIfEmpty(String relativePath) async {
    final normalizedRelativePath = relativePath.trim();
    if (normalizedRelativePath.isEmpty) {
      return;
    }

    final normalizedPath = p.normalize(
      normalizedRelativePath.replaceAll('\\', '/'),
    );
    final segments = p.split(normalizedPath);
    if (segments.length != 3 ||
        segments.first != _documentsFolderName ||
        segments[2].isEmpty) {
      return;
    }

    final documentDirectory = await resolveAbsoluteDocumentDirectory(segments[1]);
    if (!await documentDirectory.exists()) {
      return;
    }

    final remainingEntries = await documentDirectory.list(followLinks: false).take(1).toList();
    if (remainingEntries.isNotEmpty) {
      return;
    }

    await documentDirectory.delete();
  }

  Future<Directory> resolveAbsoluteDocumentDirectory(String documentId) async {
    final normalizedDocumentId = documentId.trim();
    if (normalizedDocumentId.isEmpty) {
      throw ArgumentError.value(documentId, 'documentId', 'Must not be empty.');
    }

    final rootDirectory = await getRootDirectory();
    return Directory(
      p.join(rootDirectory.path, normalizedDocumentId),
    );
  }

  String _normalizeExtension(String fileExtension) {
    final normalized = fileExtension.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }

    return normalized.startsWith('.') ? normalized.substring(1) : normalized;
  }
}
