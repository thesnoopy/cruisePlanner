enum ShareIntakeSource {
  initialLaunch,
  resumedShare,
}

enum ShareIntakeItemKind {
  file,
  image,
  text,
  url,
}

class ShareIntakeItem {
  const ShareIntakeItem({
    required this.kind,
    required this.value,
    this.mimeType,
    this.fileName,
    this.message,
    this.thumbnailValue,
    this.durationMillis,
  });

  final ShareIntakeItemKind kind;
  final String value;
  final String? mimeType;
  final String? fileName;
  final String? message;
  final String? thumbnailValue;
  final int? durationMillis;

  bool get isFileBased =>
      kind == ShareIntakeItemKind.file || kind == ShareIntakeItemKind.image;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kind': kind.name,
      'value': value,
      'mimeType': mimeType,
      'fileName': fileName,
      'message': message,
      'thumbnailValue': thumbnailValue,
      'durationMillis': durationMillis,
    };
  }

  static ShareIntakeItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final kindValue = json['kind'];
    final value = json['value'];
    if (kindValue is! String || value is! String) {
      return null;
    }

    final kind = ShareIntakeItemKind.values.where((item) => item.name == kindValue).firstOrNull;
    final normalizedValue = value.trim();
    if (kind == null || normalizedValue.isEmpty) {
      return null;
    }

    return ShareIntakeItem(
      kind: kind,
      value: normalizedValue,
      mimeType: _readNullableString(json['mimeType']),
      fileName: _readNullableString(json['fileName']),
      message: _readNullableString(json['message']),
      thumbnailValue: _readNullableString(json['thumbnailValue']),
      durationMillis: _readNullableInt(json['durationMillis']),
    );
  }
}

class ShareIntakeBatch {
  const ShareIntakeBatch({
    required this.id,
    required this.source,
    required this.receivedAt,
    required this.items,
  });

  final String id;
  final ShareIntakeSource source;
  final DateTime receivedAt;
  final List<ShareIntakeItem> items;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'source': source.name,
      'receivedAt': receivedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }

  static ShareIntakeBatch? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final id = _readNullableString(json['id']);
    final sourceValue = _readNullableString(json['source']);
    final receivedAtValue = _readNullableString(json['receivedAt']);
    final itemsValue = json['items'];
    if (id == null ||
        sourceValue == null ||
        receivedAtValue == null ||
        itemsValue is! List) {
      return null;
    }

    final source = ShareIntakeSource.values
        .where((item) => item.name == sourceValue)
        .firstOrNull;
    final receivedAt = DateTime.tryParse(receivedAtValue);
    if (source == null || receivedAt == null) {
      return null;
    }

    final items = itemsValue
        .whereType<Map>()
        .map(
          (item) => ShareIntakeItem.fromJson(
            Map<String, dynamic>.from(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          ),
        )
        .whereType<ShareIntakeItem>()
        .toList(growable: false);

    if (items.isEmpty) {
      return null;
    }

    return ShareIntakeBatch(
      id: id,
      source: source,
      receivedAt: receivedAt.toUtc(),
      items: items,
    );
  }
}

String? _readNullableString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _readNullableInt(Object? value) {
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

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final value in this) {
      return value;
    }
    return null;
  }
}
