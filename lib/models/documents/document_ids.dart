class DocumentIds {
  const DocumentIds._();

  static List<String> fromJsonValue(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    final result = <String>[];
    final seen = <String>{};

    for (final item in value) {
      final documentId = _normalizeDocumentId(item);
      if (documentId == null || !seen.add(documentId)) {
        continue;
      }
      result.add(documentId);
    }

    return List.unmodifiable(result);
  }

  static List<String> appendUnique(
    List<String> existing,
    String documentId,
  ) {
    final normalizedDocumentId = _normalizeDocumentId(documentId);
    if (normalizedDocumentId == null) {
      return List.unmodifiable(existing);
    }

    if (existing.contains(normalizedDocumentId)) {
      return List.unmodifiable(existing);
    }

    return List.unmodifiable(<String>[
      ...existing,
      normalizedDocumentId,
    ]);
  }

  static List<String> remove(
    List<String> existing,
    String documentId,
  ) {
    final normalizedDocumentId = _normalizeDocumentId(documentId);
    if (normalizedDocumentId == null || !existing.contains(normalizedDocumentId)) {
      return List.unmodifiable(existing);
    }

    return List.unmodifiable(
      existing.where((id) => id != normalizedDocumentId),
    );
  }

  static String? _normalizeDocumentId(Object? value) {
    if (value is! String) {
      return null;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
