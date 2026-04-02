import 'document_kind.dart';

class DocumentRecord {
  final String id;
  final DocumentKind kind;
  final String title;
  final String originalFileName;
  final String mimeType;
  final String fileExtension;
  final String localRelativePath;
  final int byteSize;
  final String contentHash;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  const DocumentRecord({
    required this.id,
    required this.kind,
    required this.title,
    required this.originalFileName,
    required this.mimeType,
    required this.fileExtension,
    required this.localRelativePath,
    required this.byteSize,
    required this.contentHash,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
  });

  DocumentRecord copyWith({
    String? id,
    DocumentKind? kind,
    String? title,
    String? originalFileName,
    String? mimeType,
    String? fileExtension,
    String? localRelativePath,
    int? byteSize,
    String? contentHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return DocumentRecord(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      originalFileName: originalFileName ?? this.originalFileName,
      mimeType: mimeType ?? this.mimeType,
      fileExtension: fileExtension ?? this.fileExtension,
      localRelativePath: localRelativePath ?? this.localRelativePath,
      byteSize: byteSize ?? this.byteSize,
      contentHash: contentHash ?? this.contentHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.jsonValue,
      'title': title,
      'originalFileName': originalFileName,
      'mimeType': mimeType,
      'fileExtension': fileExtension,
      'localRelativePath': localRelativePath,
      'byteSize': byteSize,
      'contentHash': contentHash,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deleted': deleted,
    };
  }

  static DocumentRecord? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final id = _readNonEmptyString(json['id']);
    final title = _readNonEmptyString(json['title']);
    final originalFileName = _readNonEmptyString(json['originalFileName']);
    final mimeType = _readNonEmptyString(json['mimeType']);
    final fileExtension = _readNonEmptyString(json['fileExtension']);
    final localRelativePath = _readRelativePath(json['localRelativePath']);
    final contentHash = _readNonEmptyString(json['contentHash']);
    final byteSize = _readInt(json['byteSize']);
    final createdAt = _readDateTime(json['createdAt']);
    final updatedAt = _readDateTime(json['updatedAt']);

    if (id == null ||
        title == null ||
        originalFileName == null ||
        mimeType == null ||
        fileExtension == null ||
        localRelativePath == null ||
        contentHash == null ||
        byteSize == null ||
        byteSize < 0 ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }

    return DocumentRecord(
      id: id,
      kind: DocumentKind.fromJsonValue(json['kind']),
      title: title,
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileExtension: fileExtension,
      localRelativePath: localRelativePath,
      byteSize: byteSize,
      contentHash: contentHash,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deleted: _readBool(json['deleted']) ?? false,
    );
  }

  static String? _readNonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static String? _readRelativePath(Object? value) {
    final normalized = _readNonEmptyString(value)?.replaceAll('\\', '/');
    if (normalized == null ||
        normalized.startsWith('/') ||
        normalized.contains(':/') ||
        normalized.contains('../') ||
        normalized == '..') {
      return null;
    }

    return normalized;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static bool? _readBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      switch (value.toLowerCase()) {
        case 'true':
          return true;
        case 'false':
          return false;
      }
    }

    return null;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
