import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:webdav_client/webdav_client.dart' as webdav;

import '../../models/documents/document_record.dart';
import '../../settings/webdav_settings.dart';
import '../../sync/webdav_client_factory.dart';

class DocumentRemoteStore {
  static const String _documentsFolderName = 'documents';
  static const String _metadataFolderName = 'metadata';
  static const String _filesFolderName = 'files';
  static const String _metadataFileName = 'documents.json';
  static const String _originalFileBaseName = 'original';

  const DocumentRemoteStore(this._settings);

  final WebDavSettings _settings;

  Future<void> ensureRemoteDirectoriesExist() async {
    final client = _createClient();

    await _ensureDirectory(client, remoteDocumentsRootPath);
    await _ensureDirectory(client, remoteMetadataDirectoryPath);
    await _ensureDirectory(client, remoteFilesDirectoryPath);
  }

  Future<List<DocumentRecord>> readDocuments() async {
    final client = _createClient();

    try {
      final bytes = await client.read(remoteMetadataFilePath);
      if (bytes.isEmpty) {
        return const <DocumentRecord>[];
      }

      final jsonString = utf8.decode(Uint8List.fromList(bytes));
      final decoded = jsonDecode(jsonString);
      final recordsJson = _extractRecordsJson(decoded);
      if (recordsJson == null) {
        return const <DocumentRecord>[];
      }

      final records = <DocumentRecord>[];
      for (final item in recordsJson) {
        if (item is! Map) {
          continue;
        }

        final normalized = Map<String, dynamic>.from(
          item.map((key, value) => MapEntry(key.toString(), value)),
        );
        final record = DocumentRecord.fromJson(normalized);
        if (record == null) {
          continue;
        }

        records.add(record);
      }

      records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return List<DocumentRecord>.unmodifiable(records);
    } catch (error) {
      if (_isMissingRemoteResourceError(error)) {
        return const <DocumentRecord>[];
      }
      rethrow;
    }
  }

  Future<void> writeDocuments(List<DocumentRecord> documents) async {
    await ensureRemoteDirectoriesExist();

    final client = _createClient();
    final payload = <String, dynamic>{
      'records': documents.map((document) => document.toJson()).toList(),
    };
    final data = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    await client.write(remoteMetadataFilePath, data);
  }

  Future<bool> remoteFileExists(DocumentRecord document) async {
    final remotePath = buildRemoteFilePath(document);
    final client = _createClient();

    try {
      await client.readProps(remotePath);
      return true;
    } catch (error) {
      if (_isMissingRemoteResourceError(error)) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> uploadDocumentFile({
    required DocumentRecord document,
    required File localFile,
  }) async {
    final localPath = localFile.path.trim();
    if (localPath.isEmpty) {
      throw ArgumentError.value(localFile.path, 'localFile', 'Invalid path.');
    }

    if (!await localFile.exists()) {
      throw FileSystemException('Document file does not exist.', localFile.path);
    }

    await ensureRemoteDirectoriesExist();

    final client = _createClient();
    await _ensureDirectory(client, buildRemoteDocumentDirectoryPath(document.id));

    final data = await localFile.readAsBytes();
    await client.write(
      buildRemoteFilePath(document),
      Uint8List.fromList(data),
    );
  }

  Future<void> downloadDocumentFile({
    required DocumentRecord document,
    required File destinationFile,
  }) async {
    final remotePath = buildRemoteFilePath(document);
    final client = _createClient();
    final bytes = await client.read(remotePath);

    await destinationFile.parent.create(recursive: true);
    await destinationFile.writeAsBytes(bytes, flush: true);
  }

  Future<void> deleteDocumentFile(DocumentRecord document) async {
    final client = _createClient();

    try {
      await client.remove(buildRemoteFilePath(document));
    } catch (error) {
      if (_isMissingRemoteResourceError(error)) {
        return;
      }
      rethrow;
    }

    await _deleteDocumentDirectoryIfEmpty(client, document.id);
  }

  String buildRemoteFilePath(DocumentRecord document) {
    _validateDocumentId(document.id);
    final extension = _normalizeFileExtension(document.fileExtension);
    if (extension.isEmpty) {
      throw ArgumentError.value(
        document.fileExtension,
        'document.fileExtension',
        'Must not be empty.',
      );
    }

    return _joinPath(
      buildRemoteDocumentDirectoryPath(document.id),
      '$_originalFileBaseName.$extension',
    );
  }

  String buildRemoteDocumentDirectoryPath(String documentId) {
    final normalizedDocumentId = _validateDocumentId(documentId);
    return _joinPath(remoteFilesDirectoryPath, normalizedDocumentId);
  }

  String get remoteDocumentsRootPath =>
      _joinPath(_remoteBaseDirectoryPath, _documentsFolderName);

  String get remoteMetadataDirectoryPath =>
      _joinPath(remoteDocumentsRootPath, _metadataFolderName);

  String get remoteMetadataFilePath =>
      _joinPath(remoteMetadataDirectoryPath, _metadataFileName);

  String get remoteFilesDirectoryPath =>
      _joinPath(remoteDocumentsRootPath, _filesFolderName);

  webdav.Client _createClient() {
    if (!_settings.isValid) {
      throw StateError('WebDAV settings are incomplete.');
    }

    return createConfiguredWebDavClient(
      _settings,
      headers: const <String, String>{
        'accept-charset': 'utf-8',
      },
    );
  }

  Future<void> _ensureDirectory(webdav.Client client, String path) async {
    try {
      await client.mkdir(path);
    } catch (error) {
      if (!await _directoryExists(client, path)) {
        rethrow;
      }
    }
  }

  Future<bool> _directoryExists(webdav.Client client, String path) async {
    try {
      await client.readDir(path);
      return true;
    } catch (_) {
      try {
        await client.readProps(path);
        return true;
      } catch (error) {
        if (_isMissingRemoteResourceError(error)) {
          return false;
        }
        rethrow;
      }
    }
  }

  Future<void> _deleteDocumentDirectoryIfEmpty(
    webdav.Client client,
    String documentId,
  ) async {
    final remoteDirectoryPath = buildRemoteDocumentDirectoryPath(documentId);

    try {
      final entries = await client.readDir(remoteDirectoryPath);
      if (entries.isNotEmpty) {
        return;
      }
    } catch (error) {
      if (_isMissingRemoteResourceError(error)) {
        return;
      }
      rethrow;
    }

    try {
      await client.remove(remoteDirectoryPath);
    } catch (error) {
      if (_isMissingRemoteResourceError(error) ||
          _isSafeToIgnoreNonEmptyDirectoryError(error)) {
        return;
      }
      rethrow;
    }
  }

  bool _isMissingRemoteResourceError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('404') ||
        message.contains('not found') ||
        message.contains('does not exist');
  }

  bool _isSafeToIgnoreNonEmptyDirectoryError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('directory not empty') ||
        message.contains('not empty') ||
        message.contains('409');
  }

  String get _remoteBaseDirectoryPath => _normalizePath(_settings.remotePath);

  List? _extractRecordsJson(Object? decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map) {
      final normalized = Map<String, dynamic>.from(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      final records = normalized['records'];
      if (records is List) {
        return records;
      }
    }

    return null;
  }

  String _validateDocumentId(String documentId) {
    final normalized = documentId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(documentId, 'documentId', 'Must not be empty.');
    }
    if (normalized.contains('/') || normalized.contains('\\')) {
      throw ArgumentError.value(
        documentId,
        'documentId',
        'Must not contain path separators.',
      );
    }
    if (normalized == '.' || normalized == '..') {
      throw ArgumentError.value(documentId, 'documentId', 'Invalid value.');
    }
    return normalized;
  }

  String _normalizeFileExtension(String extension) {
    final normalized = extension.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }

    final withoutDot = normalized.startsWith('.')
        ? normalized.substring(1)
        : normalized;
    if (withoutDot.isEmpty ||
        withoutDot == '.' ||
        withoutDot == '..' ||
        withoutDot.contains('/') ||
        withoutDot.contains('\\')) {
      return '';
    }

    return withoutDot;
  }

  String _normalizePath(String path) {
    var normalized = path.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return '/';
    }
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    while (normalized.contains('//')) {
      normalized = normalized.replaceAll('//', '/');
    }
    return normalized;
  }

  String _joinPath(String left, String right) {
    final normalizedLeft = _normalizePath(left);
    final normalizedRight = right.trim().replaceAll('\\', '/');

    if (normalizedRight.isEmpty) {
      return normalizedLeft;
    }

    if (normalizedLeft == '/') {
      return '/$normalizedRight'.replaceAll('//', '/');
    }

    return '$normalizedLeft/$normalizedRight'.replaceAll('//', '/');
  }
}
