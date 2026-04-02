import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/documents/document_record.dart';

class DocumentStore {
  static const String _storageKey = 'document_store_v1';

  Future<List<DocumentRecord>> loadDocuments({
    bool includeDeleted = false,
  }) async {
    final records = await _loadRecordMap();
    final values = records.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (includeDeleted) {
      return values;
    }

    return values.where((record) => !record.deleted).toList();
  }

  Future<DocumentRecord?> getDocumentById(String id) async {
    if (id.trim().isEmpty) {
      return null;
    }

    final records = await _loadRecordMap();
    return records[id];
  }

  Future<void> saveDocument(DocumentRecord record) async {
    final records = await _loadRecordMap();
    records[record.id] = record;
    await _persistRecordMap(records);
  }

  Future<void> saveDocuments(List<DocumentRecord> documents) async {
    final records = await _loadRecordMap();
    for (final document in documents) {
      records[document.id] = document;
    }
    await _persistRecordMap(records);
  }

  Future<bool> deleteDocumentSoft(String id) async {
    final records = await _loadRecordMap();
    final existing = records[id];
    if (existing == null) {
      return false;
    }

    records[id] = existing.copyWith(
      deleted: true,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persistRecordMap(records);
    return true;
  }

  Future<bool> restoreDocument(String id) async {
    final records = await _loadRecordMap();
    final existing = records[id];
    if (existing == null) {
      return false;
    }

    records[id] = existing.copyWith(
      deleted: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persistRecordMap(records);
    return true;
  }

  Future<bool> removeDocumentMetadata(String id) async {
    final records = await _loadRecordMap();
    final removed = records.remove(id);
    if (removed == null) {
      return false;
    }

    await _persistRecordMap(records);
    return true;
  }

  Future<Map<String, DocumentRecord>> _loadRecordMap() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_storageKey);

    if (rawValue == null || rawValue.trim().isEmpty) {
      return <String, DocumentRecord>{};
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        return <String, DocumentRecord>{};
      }

      final recordsJson = decoded['records'];
      if (recordsJson is! List) {
        return <String, DocumentRecord>{};
      }

      final result = <String, DocumentRecord>{};
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

        result[record.id] = record;
      }

      return result;
    } catch (_) {
      return <String, DocumentRecord>{};
    }
  }

  Future<void> _persistRecordMap(Map<String, DocumentRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'records': records.values.map((record) => record.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(payload));
  }
}
