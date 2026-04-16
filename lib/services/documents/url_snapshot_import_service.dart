import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../models/documents/document_record.dart';
import 'document_import_service.dart';

class UrlSnapshotImportService {
  UrlSnapshotImportService({
    DocumentImportService? documentImportService,
    http.Client? httpClient,
  })  : _documentImportService = documentImportService ?? DocumentImportService(),
        _httpClient = httpClient ?? http.Client();

  final DocumentImportService _documentImportService;
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
    final snapshot = await _captureSnapshot(parsedSourceUri);
    final effectiveUri = snapshot?.effectiveUri ?? parsedSourceUri;
    final metadata = snapshot?.metadata ??
        _UrlPageMetadata(
          title: title?.trim(),
          host: _hostLabel(effectiveUri),
        );

    final resolvedTitle = _resolveTitle(
      explicitTitle: title,
      metadata: metadata,
      uri: effectiveUri,
    );
    final fileName = _buildFileName(resolvedTitle);
    final bytes = Uint8List.fromList(
      utf8.encode(
        snapshot?.html ??
            _buildLinkOnlyHtml(
              title: resolvedTitle,
              sourceUrl: normalizedSourceUrl,
              description: metadata.description,
              host: metadata.host,
              capturedAtUtc: capturedAtUtc,
            ),
      ),
    );

    return _documentImportService.createStoredDocument(
      bytes: bytes,
      originalFileName: fileName,
      mimeType: 'text/html',
      title: resolvedTitle,
      origin: DocumentOrigin.urlImport,
      sourceUrl: normalizedSourceUrl,
      snapshotStatus: snapshot == null
          ? DocumentSnapshotStatus.linkOnly
          : DocumentSnapshotStatus.available,
      capturedAtUtc: capturedAtUtc,
      sourceDescription: metadata.description,
      sourceHost: metadata.host,
    );
  }

  Future<_SnapshotCapture?> _captureSnapshot(Uri sourceUri) async {
    try {
      final response = await _httpClient.get(sourceUri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!_isHtmlContentType(contentType)) {
        return null;
      }

      final effectiveUri = response.request?.url ?? sourceUri;
      final html = _decodeBody(response.bodyBytes, contentType);
      if (html.trim().isEmpty) {
        return null;
      }

      final metadata = _extractMetadata(html, effectiveUri);
      final embeddedHtml = await _embedImages(
        html: html,
        pageUri: effectiveUri,
      );

      return _SnapshotCapture(
        html: _injectSnapshotMetadata(
          html: embeddedHtml,
          sourceUrl: effectiveUri.toString(),
          capturedAtUtc: DateTime.now().toUtc(),
        ),
        effectiveUri: effectiveUri,
        metadata: metadata,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> _embedImages({
    required String html,
    required Uri pageUri,
  }) async {
    final replacements = <String, String>{};
    final imgTagPattern = RegExp(r'<img\b[^>]*>', caseSensitive: false);
    final srcPattern = RegExp(
      "\\bsrc\\s*=\\s*(\"([^\"]*)\"|'([^']*)'|([^\"'\\s>]+))",
      caseSensitive: false,
    );

    for (final match in imgTagPattern.allMatches(html)) {
      final tag = match.group(0);
      if (tag == null || replacements.containsKey(tag)) {
        continue;
      }

      final srcMatch = srcPattern.firstMatch(tag);
      if (srcMatch == null) {
        continue;
      }

      final originalSrc =
          srcMatch.group(2) ?? srcMatch.group(3) ?? srcMatch.group(4) ?? '';
      final trimmedSrc = originalSrc.trim();
      if (trimmedSrc.isEmpty ||
          trimmedSrc.startsWith('data:') ||
          trimmedSrc.startsWith('javascript:')) {
        continue;
      }

      final imageUri = Uri.tryParse(trimmedSrc);
      final resolvedUri = imageUri == null ? null : pageUri.resolveUri(imageUri);
      if (resolvedUri == null ||
          !(resolvedUri.isScheme('http') || resolvedUri.isScheme('https'))) {
        continue;
      }

      final dataUrl = await _downloadImageAsDataUrl(resolvedUri);
      if (dataUrl == null) {
        continue;
      }

      replacements[tag] = tag.replaceFirst(originalSrc, dataUrl);
    }

    if (replacements.isEmpty) {
      return html;
    }

    var result = html;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  Future<String?> _downloadImageAsDataUrl(Uri uri) async {
    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final contentTypeHeader = response.headers['content-type'] ?? '';
      final mimeType = _normalizeMimeType(contentTypeHeader);
      if (!mimeType.startsWith('image/')) {
        return null;
      }

      final encoded = base64Encode(response.bodyBytes);
      return 'data:$mimeType;base64,$encoded';
    } catch (_) {
      return null;
    }
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

  String _injectSnapshotMetadata({
    required String html,
    required String sourceUrl,
    required DateTime capturedAtUtc,
  }) {
    final metadataTags =
        '<meta name="cruiseplanner-source-url" content="${_escapeHtmlAttribute(sourceUrl)}">\n'
        '<meta name="cruiseplanner-captured-at-utc" content="${capturedAtUtc.toIso8601String()}">\n';
    final headPattern = RegExp(r'<head\b[^>]*>', caseSensitive: false);
    final headMatch = headPattern.firstMatch(html);
    if (headMatch == null) {
      return '<head>\n$metadataTags</head>\n$html';
    }

    final insertAt = headMatch.end;
    return '${html.substring(0, insertAt)}\n$metadataTags${html.substring(insertAt)}';
  }

  String _buildLinkOnlyHtml({
    required String title,
    required String sourceUrl,
    String? description,
    String? host,
    required DateTime capturedAtUtc,
  }) {
    final escapedTitle = _escapeHtmlText(title);
    final escapedUrl = _escapeHtmlAttribute(sourceUrl);
    final escapedHost = host == null ? '' : _escapeHtmlText(host);
    final escapedDescription =
        description == null ? '' : _escapeHtmlText(description);
    final descriptionBlock = escapedDescription.isEmpty
        ? ''
        : '<p>$escapedDescription</p>';
    final hostBlock = escapedHost.isEmpty ? '' : '<p><strong>Host:</strong> $escapedHost</p>';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="cruiseplanner-source-url" content="$escapedUrl">
  <meta name="cruiseplanner-captured-at-utc" content="${capturedAtUtc.toIso8601String()}">
  <title>$escapedTitle</title>
</head>
<body>
  <main>
    <h1>$escapedTitle</h1>
    <p>An offline page snapshot was not available for this shared URL.</p>
    <p><a href="$escapedUrl">$escapedUrl</a></p>
    $hostBlock
    $descriptionBlock
  </main>
</body>
</html>
''';
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

  String _buildFileName(String title) {
    final sanitized = title
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final baseName = sanitized.isEmpty ? 'shared_url' : sanitized;
    return '${p.basenameWithoutExtension(baseName)}.html';
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
    return (encoding ?? utf8).decode(bodyBytes, allowMalformed: true);
  }

  String _normalizeMimeType(String contentTypeHeader) {
    final normalized = contentTypeHeader.split(';').first.trim().toLowerCase();
    return normalized.isEmpty ? 'application/octet-stream' : normalized;
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

  String _escapeHtmlText(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  String _escapeHtmlAttribute(String value) {
    return _escapeHtmlText(value)
        .replaceAll('"', '&quot;')
        .replaceAll('\'', '&#39;');
  }

  static String _hostLabel(Uri uri) {
    final host = uri.host.trim();
    return host.isEmpty ? '' : host;
  }
}

class _SnapshotCapture {
  const _SnapshotCapture({
    required this.html,
    required this.effectiveUri,
    required this.metadata,
  });

  final String html;
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
