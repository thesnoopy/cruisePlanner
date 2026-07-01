import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/documents/url_snapshot_capture_result.dart';
import '../../models/documents/url_snapshot_view_state.dart';

class UrlSnapshotWebViewController extends ChangeNotifier {
  UrlSnapshotWebViewController()
    : _state = UrlSnapshotViewState.initial(
        isSupported: _supportsPlatformViews,
      );

  static const String viewType =
      'de.mailsmart.cruiseplanner/url_snapshot_webview';
  static const String _channelBase =
      'de.mailsmart.cruiseplanner/url_snapshot_webview';

  static bool get _supportsPlatformViews =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  UrlSnapshotViewState _state;
  UrlSnapshotViewState get state => _state;

  MethodChannel? _methodChannel;
  StreamSubscription<dynamic>? _eventSubscription;
  String? _pendingUrlToLoad;

  bool get isSupported => _state.isSupported;

  Future<void> attachToPlatformView(int viewId) async {
    if (!isSupported) {
      return;
    }

    await _eventSubscription?.cancel();
    _methodChannel = MethodChannel('$_channelBase/$viewId');
    final eventChannel = EventChannel('$_channelBase/$viewId/events');
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (_) {
        _updateState(
          _state.copyWith(
            isLoading: false,
            hasLoadedPage: false,
            canCapture: false,
          ),
        );
      },
    );

    final pendingUrlToLoad = _pendingUrlToLoad;
    if (pendingUrlToLoad != null) {
      _pendingUrlToLoad = null;
      await loadUrl(pendingUrlToLoad);
    }
  }

  Future<void> loadUrl(String url) async {
    _ensureSupported();
    final channel = _methodChannel;
    if (channel == null) {
      _pendingUrlToLoad = url;
      return;
    }

    _updateState(
      _state.copyWith(
        isLoading: true,
        hasLoadedPage: false,
        canCapture: false,
        currentUrl: url,
        clearPageTitle: true,
        clearErrorMessage: true,
      ),
    );
    await channel.invokeMethod<void>('loadUrl', <String, Object?>{
      'url': url,
    });
  }

  Future<void> reload() async {
    _ensureSupported();
    final channel = _methodChannel;
    if (channel == null) {
      throw StateError('URL snapshot web view is not attached.');
    }

    await channel.invokeMethod<void>('reload');
  }

  Future<UrlSnapshotCaptureResult> capturePdf({
    required String sourceUrl,
  }) async {
    _ensureSupported();
    final channel = _methodChannel;
    if (channel == null) {
      throw StateError('URL snapshot web view is not attached.');
    }

    final rawResult = await channel.invokeMethod<Object?>(
      'capturePdf',
      <String, Object?>{
        'sourceUrl': sourceUrl,
      },
    );
    if (rawResult is! Map) {
      throw StateError('Invalid URL snapshot capture result.');
    }

    final result = Map<String, Object?>.from(
      rawResult.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    final filePath = (result['filePath'] as String?)?.trim();
    if (filePath == null || filePath.isEmpty) {
      throw StateError('Missing snapshot file path.');
    }

    final effectiveUrl = (result['url'] as String?)?.trim();
    if (effectiveUrl == null || effectiveUrl.isEmpty) {
      throw StateError('Missing effective URL.');
    }

    final pageTitle = (result['title'] as String?)?.trim();
    final pageCount = _asInt(result['pageCount']);
    final fileSizeBytes = _asInt(result['fileSizeBytes']);
    return UrlSnapshotCaptureResult(
      sourceUrl: sourceUrl,
      effectiveUrl: effectiveUrl,
      filePath: filePath,
      pageTitle: pageTitle == null || pageTitle.isEmpty ? null : pageTitle,
      pageCount: pageCount,
      fileSizeBytes: fileSizeBytes,
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _methodChannel = null;
    super.dispose();
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) {
      return;
    }

    final payload = Map<String, Object?>.from(
      event.map((key, value) => MapEntry(key.toString(), value)),
    );
    final type = (payload['type'] as String?)?.trim();
    final currentUrl = (payload['url'] as String?)?.trim();
    final pageTitle = (payload['pageTitle'] as String?)?.trim();
    final errorMessage = (payload['message'] as String?)?.trim();

    switch (type) {
      case 'pageStarted':
        _updateState(
          _state.copyWith(
            isLoading: true,
            hasLoadedPage: false,
            canCapture: false,
            currentUrl: currentUrl,
            clearPageTitle: true,
            clearErrorMessage: true,
          ),
        );
        return;
      case 'pageFinished':
        _updateState(
          _state.copyWith(
            isLoading: false,
            hasLoadedPage: true,
            canCapture: true,
            currentUrl: currentUrl,
            pageTitle: pageTitle,
            clearErrorMessage: true,
          ),
        );
        return;
      case 'titleChanged':
        _updateState(
          _state.copyWith(
            pageTitle: pageTitle,
          ),
        );
        return;
      case 'loadFailed':
        _updateState(
          _state.copyWith(
            isLoading: false,
            hasLoadedPage: false,
            canCapture: false,
            currentUrl: currentUrl,
            errorMessage: errorMessage,
          ),
        );
        return;
      default:
        return;
    }
  }

  void _ensureSupported() {
    if (!isSupported) {
      throw UnsupportedError('URL snapshots are not supported on this platform.');
    }
  }

  void _updateState(UrlSnapshotViewState nextState) {
    if (_state == nextState) {
      return;
    }

    _state = nextState;
    notifyListeners();
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed;
  }
}
