import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../models/documents/document_record.dart';
import 'document_import_service.dart';
import 'url_pdf_snapshot_native_bridge.dart';

class UrlSnapshotImportService {
  UrlSnapshotImportService({
    DocumentImportService? documentImportService,
    UrlPdfSnapshotNativeBridge? pdfSnapshotNativeBridge,
    http.Client? httpClient,
  })  : _documentImportService = documentImportService ?? DocumentImportService(),
        _pdfSnapshotNativeBridge =
            pdfSnapshotNativeBridge ?? const UrlPdfSnapshotNativeBridge(),
        _httpClient = httpClient ?? http.Client();

  final DocumentImportService _documentImportService;
  final UrlPdfSnapshotNativeBridge _pdfSnapshotNativeBridge;
  final http.Client _httpClient;

  Future<DocumentRecord> importUrl({
    required String sourceUrl,
    String? title,
  }) async {
    final normalizedSourceUrl = sourceUrl.trim();
    final parsedSourceUri = Uri.tryParse(normalizedSourceUrl);
    if (parsedSourceUri == null ||
        !(parsedSourceUri.isScheme('http') || parsedSourceUri.isScheme('https'))) {
      throw ArgumentError.value(sourceUrl, 'sourceUrl', 'Invalid URL.');
    }

    final capturedAtUtc = DateTime.now().toUtc();
    final metadataSnapshot = await _fetchPageMetadata(parsedSourceUri);
    final pdfSnapshot = await _pdfSnapshotNativeBridge.captureUrlAsPdf(
      sourceUrl: normalizedSourceUrl,
    );
    final effectiveUri = _resolveEffectiveUri(
      originalUri: parsedSourceUri,
      metadataUri: metadataSnapshot?.effectiveUri,
      pdfUrl: pdfSnapshot?.effectiveUrl,
    );
    final metadata = _resolveMetadata(
      explicitTitle: title,
      metadataSnapshot: metadataSnapshot,
      pdfSnapshot: pdfSnapshot,
      effectiveUri: effectiveUri,
    );
    final resolvedTitle = _resolveTitle(
      explicitTitle: title,
      metadata: metadata,
      uri: effectiveUri,
    );

    if (pdfSnapshot != null) {
      return _documentImportService.createStoredDocument(
        bytes: pdfSnapshot.pdfBytes,
        originalFileName: _buildFileName(resolvedTitle, 'pdf'),
        mimeType: 'application/pdf',
        title: resolvedTitle,
        origin: DocumentOrigin.urlImport,
        sourceUrl: normalizedSourceUrl,
        snapshotStatus: DocumentSnapshotStatus.available,
        capturedAtUtc: capturedAtUtc,
        sourceDescription: metadata.description,
        sourceHost: metadata.host,
      );
    }

    return _documentImportService.createStoredDocument(
      bytes: Uint8List.fromList(
        utf8.encode(
          _buildLinkOnlyText(
            title: resolvedTitle,
            sourceUrl: normalizedSourceUrl,
            description: metadata.description,
            host: metadata.host,
            capturedAtUtc: capturedAtUtc,
          ),
        ),
      ),
      originalFileName: _buildFileName(resolvedTitle, 'txt'),
      mimeType: 'text/plain',
      title: resolvedTitle,
      origin: DocumentOrigin.urlImport,
      sourceUrl: normalizedSourceUrl,
      snapshotStatus: DocumentSnapshotStatus.linkOnly,
      capturedAtUtc: capturedAtUtc,
      sourceDescription: metadata.description,
      sourceHost: metadata.host,
    );
  }

  Future<_MetadataSnapshot?> _fetchPageMetadata(Uri sourceUri) async {
    try {
      final response = await _httpClient.get(sourceUri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!_isHtmlContentType(contentType)) {
        return _MetadataSnapshot(
          effectiveUri: response.request?.url ?? sourceUri,
          metadata: _UrlPageMetadata(
            host: _hostLabel(response.request?.url ?? sourceUri),
          ),
        );
      }

      final effectiveUri = response.request?.url ?? sourceUri;
      final html = _decodeBody(response.bodyBytes, contentType);
      if (html.trim().isEmpty) {
        return _MetadataSnapshot(
          effectiveUri: effectiveUri,
          metadata: _UrlPageMetadata(
            host: _hostLabel(effectiveUri),
          ),
        );
      }

      return _MetadataSnapshot(
        effectiveUri: effectiveUri,
        metadata: _extractMetadata(html, effectiveUri),
      );
    } catch (_) {
      return null;
    }
  }

  Uri _resolveEffectiveUri({
    required Uri originalUri,
    Uri? metadataUri,
    String? pdfUrl,
  }) {
    final parsedPdfUri = Uri.tryParse(pdfUrl?.trim() ?? '');
    if (parsedPdfUri != null &&
        (parsedPdfUri.isScheme('http') || parsedPdfUri.isScheme('https'))) {
      return parsedPdfUri;
    }
    if (metadataUri != null) {
      return metadataUri;
    }
    return originalUri;
  }

  _UrlPageMetadata _resolveMetadata({
    required String? explicitTitle,
    required _MetadataSnapshot? metadataSnapshot,
    required UrlPdfSnapshotCaptureResult? pdfSnapshot,
    required Uri effectiveUri,
  }) {
    final metadata = metadataSnapshot?.metadata;
    final pdfTitle = pdfSnapshot?.pageTitle?.trim();

    return _UrlPageMetadata(
      title: _firstNonEmpty(
        explicitTitle,
        metadata?.title,
        pdfTitle,
      ),
      description: metadata?.description,
      host: _firstNonEmpty(
        metadata?.host,
        _hostLabel(effectiveUri),
      ),
    );
  }

  _UrlPageMetadata _extractMetadata(String html, Uri effectiveUri) {
    final title = _matchFirstGroup(
      RegExp(
        r'<title[^>]*>([\s\S]*?)</title>',
        caseSensitive: false,
      ),
      html,
    );
    final description = _extractMetaContent(html, 'description');

    return _UrlPageMetadata(
      title: _decodeHtmlText(title),
      description: _decodeHtmlText(description),
      host: _hostLabel(effectiveUri),
    );
  }

  String _buildLinkOnlyText({
    required String title,
    required String sourceUrl,
    String? description,
    String? host,
    required DateTime capturedAtUtc,
  }) {
    final lines = <String>[
      title,
      '',
      'Offline PDF snapshot unavailable for this shared URL.',
      'Source URL: $sourceUrl',
      'Captured at (UTC): ${capturedAtUtc.toIso8601String()}',
      if (host != null && host.trim().isNotEmpty) 'Host: ${host.trim()}',
      if (description != null && description.trim().isNotEmpty)
        'Description: ${description.trim()}',
    ];
    return lines.join('\n');
  }

  String _resolveTitle({
    required String? explicitTitle,
    required _UrlPageMetadata metadata,
    required Uri uri,
  }) {
    final normalizedExplicit = explicitTitle?.trim();
    if (normalizedExplicit != null && normalizedExplicit.isNotEmpty) {
      return normalizedExplicit;
    }

    final metadataTitle = metadata.title?.trim();
    if (metadataTitle != null && metadataTitle.isNotEmpty) {
      return metadataTitle;
    }

    final host = _hostLabel(uri);
    if (host.isNotEmpty) {
      return host;
    }

    return uri.toString();
  }

  String _buildFileName(String title, String extension) {
    final sanitized = title
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), '_');
    final baseName = sanitized.isEmpty ? 'shared_url' : sanitized;
    return '${p.basenameWithoutExtension(baseName)}.$extension';
  }

  bool _isHtmlContentType(String contentType) {
    final normalized = contentType.toLowerCase();
    return normalized.contains('text/html') ||
        normalized.contains('application/xhtml+xml');
  }

  String _decodeBody(List<int> bodyBytes, String contentType) {
    final charsetMatch = RegExp(
      r'charset\s*=\s*([^\s;]+)',
      caseSensitive: false,
    ).firstMatch(contentType);
    final charset = charsetMatch?.group(1)?.trim().replaceAll('"', '');
    final encoding = charset == null ? null : Encoding.getByName(charset);
    if (encoding != null) {
      return encoding.decode(bodyBytes);
    }

    return utf8.decode(bodyBytes, allowMalformed: true);
  }

  String? _extractMetaContent(String html, String name) {
    final metaPattern = RegExp(
      "<meta\\b[^>]*?(?:name|property)\\s*=\\s*(\"|')${RegExp.escape(name)}\\1[^>]*?content\\s*=\\s*(\"|')(.*?)\\2[^>]*?>",
      caseSensitive: false,
    );
    final contentFirstPattern = RegExp(
      "<meta\\b[^>]*?content\\s*=\\s*(\"|')(.*?)\\1[^>]*?(?:name|property)\\s*=\\s*(\"|')${RegExp.escape(name)}\\3[^>]*?>",
      caseSensitive: false,
    );

    final directMatch = metaPattern.firstMatch(html);
    if (directMatch != null) {
      return directMatch.group(3);
    }

    final reverseMatch = contentFirstPattern.firstMatch(html);
    if (reverseMatch != null) {
      return reverseMatch.group(2);
    }

    return null;
  }

  String? _matchFirstGroup(RegExp pattern, String value) {
    final match = pattern.firstMatch(value);
    return match?.group(1);
  }

  String? _decodeHtmlText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', '\'')
        .replaceAll('&nbsp;', ' ');
  }

  String? _firstNonEmpty(String? first, [String? second, String? third]) {
    for (final value in [first, second, third]) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  static String _hostLabel(Uri uri) {
    final host = uri.host.trim();
    return host.isEmpty ? '' : host;
  }
}

class _MetadataSnapshot {
  const _MetadataSnapshot({
    required this.effectiveUri,
    required this.metadata,
  });

  final Uri effectiveUri;
  final _UrlPageMetadata metadata;
}

class _UrlPageMetadata {
  const _UrlPageMetadata({
    this.title,
    this.description,
    this.host,
  });

  final String? title;
  final String? description;
  final String? host;
}
