import 'package:flutter/services.dart';

class UrlPdfSnapshotNativeBridge {
  const UrlPdfSnapshotNativeBridge();

  static const MethodChannel _methodChannel = MethodChannel(
    'de.mailsmart.cruiseplanner/url_snapshot',
  );

  Future<UrlPdfSnapshotCaptureResult?> captureUrlAsPdf({
    required String sourceUrl,
  }) async {
    try {
      final rawResult = await _methodChannel.invokeMapMethod<Object?, Object?>(
        'captureUrlAsPdf',
        <String, Object?>{
          'sourceUrl': sourceUrl,
        },
      );
      if (rawResult == null) {
        return null;
      }

      final pdfBytes = rawResult['pdfBytes'];
      if (pdfBytes is! Uint8List || pdfBytes.isEmpty) {
        return null;
      }

      final effectiveUrl = rawResult['effectiveUrl'];
      final pageTitle = rawResult['pageTitle'];

      return UrlPdfSnapshotCaptureResult(
        pdfBytes: pdfBytes,
        effectiveUrl: effectiveUrl is String ? effectiveUrl.trim() : null,
        pageTitle: pageTitle is String ? pageTitle.trim() : null,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

class UrlPdfSnapshotCaptureResult {
  const UrlPdfSnapshotCaptureResult({
    required this.pdfBytes,
    this.effectiveUrl,
    this.pageTitle,
  });

  final Uint8List pdfBytes;
  final String? effectiveUrl;
  final String? pageTitle;
}
