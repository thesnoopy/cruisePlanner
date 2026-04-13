import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/share/share_intake_payload.dart';

typedef SharedPreferencesAsyncLoader = Future<SharedPreferences> Function();

class ShareIntakeService extends ChangeNotifier {
  factory ShareIntakeService({
    SharedPreferencesAsyncLoader? preferencesLoader,
    Uuid? uuid,
  }) {
    _instance ??= ShareIntakeService._internal(
      preferencesLoader: preferencesLoader,
      uuid: uuid,
    );
    return _instance!;
  }

  ShareIntakeService._internal({
    SharedPreferencesAsyncLoader? preferencesLoader,
    Uuid? uuid,
  })  : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _uuid = uuid ?? const Uuid();

  static ShareIntakeService? _instance;
  static const String _storageKey = 'share_intake_queue_v1';

  final SharedPreferencesAsyncLoader _preferencesLoader;
  final Uuid _uuid;

  Future<void>? _initialization;
  StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;
  List<ShareIntakeBatch> _pendingBatches = const <ShareIntakeBatch>[];

  List<ShareIntakeBatch> get pendingBatches =>
      List<ShareIntakeBatch>.unmodifiable(_pendingBatches);

  ShareIntakeBatch? get latestPendingBatch =>
      _pendingBatches.isEmpty ? null : _pendingBatches.last;

  ShareIntakeBatch? getPendingBatch(String batchId) {
    final normalizedId = batchId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }

    for (final batch in _pendingBatches) {
      if (batch.id == normalizedId) {
        return batch;
      }
    }

    return null;
  }

  ShareIntakeItem? getPendingItem({
    required String batchId,
    required int itemIndex,
  }) {
    final batch = getPendingBatch(batchId);
    if (batch == null || itemIndex < 0 || itemIndex >= batch.items.length) {
      return null;
    }

    return batch.items[itemIndex];
  }

  bool get hasPendingBatches => _pendingBatches.isNotEmpty;

  int get pendingItemCount => _pendingBatches.fold<int>(
    0,
    (count, batch) => count + batch.items.length,
  );

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> clearPendingBatch(String batchId) async {
    final normalizedId = batchId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    _pendingBatches = List<ShareIntakeBatch>.unmodifiable(
      _pendingBatches.where((batch) => batch.id != normalizedId),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> clearAllPending() async {
    if (_pendingBatches.isEmpty) {
      return;
    }

    _pendingBatches = const <ShareIntakeBatch>[];
    await _persist();
    notifyListeners();
  }

  Future<void> removePendingItem({
    required String batchId,
    required int itemIndex,
  }) async {
    final normalizedId = batchId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    final batchIndex = _pendingBatches.indexWhere(
      (batch) => batch.id == normalizedId,
    );
    if (batchIndex < 0) {
      return;
    }

    final batch = _pendingBatches[batchIndex];
    if (itemIndex < 0 || itemIndex >= batch.items.length) {
      return;
    }

    final nextItems = <ShareIntakeItem>[
      ...batch.items.take(itemIndex),
      ...batch.items.skip(itemIndex + 1),
    ];
    final nextBatches = <ShareIntakeBatch>[
      ..._pendingBatches.take(batchIndex),
      if (nextItems.isNotEmpty)
        ShareIntakeBatch(
          id: batch.id,
          source: batch.source,
          receivedAt: batch.receivedAt,
          items: List<ShareIntakeItem>.unmodifiable(nextItems),
        ),
      ..._pendingBatches.skip(batchIndex + 1),
    ];

    _pendingBatches = List<ShareIntakeBatch>.unmodifiable(nextBatches);
    await _persist();
    notifyListeners();
  }

  Future<void> _initialize() async {
    await _loadPersisted();
    if (_mediaSubscription != null) {
      return;
    }

    _mediaSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (sharedMedia) {
        unawaited(
          _captureSharedMedia(
            sharedMedia,
            source: ShareIntakeSource.resumedShare,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Share intake stream error: $error');
      },
    );

    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    await _captureSharedMedia(
      initialMedia,
      source: ShareIntakeSource.initialLaunch,
    );
  }

  Future<void> _captureSharedMedia(
    List<SharedMediaFile> sharedMedia, {
    required ShareIntakeSource source,
  }) async {
    final items = sharedMedia
        .map(_normalizeSharedMediaFile)
        .whereType<ShareIntakeItem>()
        .toList(growable: false);

    if (items.isEmpty) {
      ReceiveSharingIntent.instance.reset();
      return;
    }

    final batch = ShareIntakeBatch(
      id: _uuid.v4(),
      source: source,
      receivedAt: DateTime.now().toUtc(),
      items: items,
    );

    _pendingBatches = List<ShareIntakeBatch>.unmodifiable(
      <ShareIntakeBatch>[
        ..._pendingBatches,
        batch,
      ],
    );
    await _persist();
    ReceiveSharingIntent.instance.reset();
    notifyListeners();
  }

  ShareIntakeItem? _normalizeSharedMediaFile(SharedMediaFile file) {
    final normalizedValue = _normalizeSharedValue(file);
    if (normalizedValue == null) {
      return null;
    }

    final kind = _mapKind(file, normalizedValue);
    final normalizedThumbnail = _normalizeFileLikeValue(file.thumbnail);
    final fileName = switch (kind) {
      ShareIntakeItemKind.file || ShareIntakeItemKind.image =>
        _extractFileName(normalizedValue),
      ShareIntakeItemKind.text || ShareIntakeItemKind.url => null,
    };

    return ShareIntakeItem(
      kind: kind,
      value: normalizedValue,
      mimeType: _trimToNull(file.mimeType),
      fileName: fileName,
      message: _trimToNull(file.message),
      thumbnailValue: normalizedThumbnail,
      durationMillis: file.duration,
    );
  }

  ShareIntakeItemKind _mapKind(SharedMediaFile file, String normalizedValue) {
    switch (file.type) {
      case SharedMediaType.image:
        return ShareIntakeItemKind.image;
      case SharedMediaType.text:
        return _looksLikeUrl(normalizedValue)
            ? ShareIntakeItemKind.url
            : ShareIntakeItemKind.text;
      case SharedMediaType.url:
        return ShareIntakeItemKind.url;
      case SharedMediaType.file:
      case SharedMediaType.video:
        return ShareIntakeItemKind.file;
    }
  }

  String? _normalizeSharedValue(SharedMediaFile file) {
    switch (file.type) {
      case SharedMediaType.image:
      case SharedMediaType.file:
      case SharedMediaType.video:
        return _normalizeFileLikeValue(file.path);
      case SharedMediaType.text:
      case SharedMediaType.url:
        return _trimToNull(file.path);
    }
  }

  String? _normalizeFileLikeValue(String? value) {
    final trimmed = _trimToNull(value);
    if (trimmed == null) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      if (uri.scheme == 'file') {
        return uri.toFilePath();
      }

      return trimmed;
    }

    return trimmed;
  }

  String? _extractFileName(String pathValue) {
    final normalized = pathValue.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final baseName = p.basename(normalized).trim();
    return baseName.isEmpty ? null : baseName;
  }

  bool _looksLikeUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  Future<void> _loadPersisted() async {
    final preferences = await _preferencesLoader();
    final rawValue = preferences.getString(_storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      _pendingBatches = const <ShareIntakeBatch>[];
      return;
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! List) {
        _pendingBatches = const <ShareIntakeBatch>[];
        return;
      }

      final batches = decoded
          .whereType<Map>()
          .map(
            (item) => ShareIntakeBatch.fromJson(
              Map<String, dynamic>.from(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            ),
          )
          .whereType<ShareIntakeBatch>()
          .toList(growable: false);

      _pendingBatches = List<ShareIntakeBatch>.unmodifiable(batches);
    } catch (_) {
      _pendingBatches = const <ShareIntakeBatch>[];
    }
  }

  Future<void> _persist() async {
    final preferences = await _preferencesLoader();
    final payload = jsonEncode(
      _pendingBatches.map((batch) => batch.toJson()).toList(growable: false),
    );
    await preferences.setString(_storageKey, payload);
  }
}
