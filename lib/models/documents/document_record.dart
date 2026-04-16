import 'document_kind.dart';

enum DocumentOrigin {
  localFile,
  urlImport,
  ;

  String get jsonValue {
    switch (this) {
      case DocumentOrigin.localFile:
        return 'localFile';
      case DocumentOrigin.urlImport:
        return 'urlImport';
    }
  }

  static DocumentOrigin fromJsonValue(Object? value) {
    switch (value) {
      case 'urlImport':
        return DocumentOrigin.urlImport;
      case 'localFile':
      default:
        return DocumentOrigin.localFile;
    }
  }
}

enum DocumentSnapshotStatus {
  available,
  linkOnly,
  failed,
  ;

  String get jsonValue {
    switch (this) {
      case DocumentSnapshotStatus.available:
        return 'available';
      case DocumentSnapshotStatus.linkOnly:
        return 'linkOnly';
      case DocumentSnapshotStatus.failed:
        return 'failed';
    }
  }

  static DocumentSnapshotStatus? fromJsonValue(Object? value) {
    switch (value) {
      case 'available':
        return DocumentSnapshotStatus.available;
      case 'linkOnly':
        return DocumentSnapshotStatus.linkOnly;
      case 'failed':
        return DocumentSnapshotStatus.failed;
      default:
        return null;
    }
  }
}

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
  final DocumentOrigin origin;
  final String? sourceUrl;
  final DocumentSnapshotStatus? snapshotStatus;
  final DateTime? capturedAtUtc;
  final String? sourceDescription;
  final String? sourceHost;

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
    this.origin = DocumentOrigin.localFile,
    this.sourceUrl,
    this.snapshotStatus,
    this.capturedAtUtc,
    this.sourceDescription,
    this.sourceHost,
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
    DocumentOrigin? origin,
    String? sourceUrl,
    bool clearSourceUrl = false,
    DocumentSnapshotStatus? snapshotStatus,
    bool clearSnapshotStatus = false,
    DateTime? capturedAtUtc,
    bool clearCapturedAtUtc = false,
    String? sourceDescription,
    bool clearSourceDescription = false,
    String? sourceHost,
    bool clearSourceHost = false,
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
      origin: origin ?? this.origin,
      sourceUrl: clearSourceUrl ? null : sourceUrl ?? this.sourceUrl,
      snapshotStatus: clearSnapshotStatus
          ? null
          : snapshotStatus ?? this.snapshotStatus,
      capturedAtUtc: clearCapturedAtUtc
          ? null
          : capturedAtUtc ?? this.capturedAtUtc,
      sourceDescription: clearSourceDescription
          ? null
          : sourceDescription ?? this.sourceDescription,
      sourceHost: clearSourceHost ? null : sourceHost ?? this.sourceHost,
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
      'origin': origin.jsonValue,
      'sourceUrl': sourceUrl,
      'snapshotStatus': snapshotStatus?.jsonValue,
      'capturedAtUtc': capturedAtUtc?.toIso8601String(),
      'sourceDescription': sourceDescription,
      'sourceHost': sourceHost,
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
      origin: DocumentOrigin.fromJsonValue(json['origin']),
      sourceUrl: _readNullableString(json['sourceUrl']),
      snapshotStatus: DocumentSnapshotStatus.fromJsonValue(
        json['snapshotStatus'],
      ),
      capturedAtUtc: _readNullableDateTime(json['capturedAtUtc']),
      sourceDescription: _readNullableString(json['sourceDescription']),
      sourceHost: _readNullableString(json['sourceHost']),
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

  static String? _readNullableString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

  static DateTime? _readNullableDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    return _readDateTime(value);
  }
}
