import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../models/documents/document_import_resolution.dart';
import '../../models/documents/document_record.dart';
import '../../models/documents/url_document_target.dart';
import '../../models/documents/url_snapshot_capture_result.dart';
import 'document_attachment_service.dart';
import 'document_import_service.dart';

class UrlDocumentSaveResult {
  const UrlDocumentSaveResult({
    required this.document,
    required this.outcome,
  });

  final DocumentRecord document;
  final UrlDocumentSaveOutcome outcome;
}

enum UrlDocumentSaveOutcome {
  importedAndLinked,
  existingLinked,
  alreadyLinked,
}

class UrlDocumentService {
  UrlDocumentService({
    DocumentImportService? documentImportService,
    DocumentAttachmentService? attachmentService,
  }) : _documentImportService = documentImportService ?? DocumentImportService(),
       _attachmentService = attachmentService ?? DocumentAttachmentService();

  final DocumentImportService _documentImportService;
  final DocumentAttachmentService _attachmentService;

  String normalizeSourceUrl(String rawUrl) {
    final normalized = rawUrl.trim();
    final uri = Uri.tryParse(normalized);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw ArgumentError.value(rawUrl, 'rawUrl', 'Invalid URL.');
    }

    return uri.toString();
  }

  Future<UrlDocumentSaveResult> saveSnapshot({
    required UrlDocumentTarget target,
    required UrlSnapshotCaptureResult snapshot,
  }) async {
    final sourceUrl = normalizeSourceUrl(snapshot.sourceUrl);
    final effectiveUrl = normalizeSourceUrl(snapshot.effectiveUrl);
    final snapshotFile = File(snapshot.filePath);
    if (!await snapshotFile.exists()) {
      throw FileSystemException(
        'URL snapshot PDF file does not exist.',
        snapshot.filePath,
      );
    }

    final capturedAtUtc = DateTime.now().toUtc();
    final resolvedTitle = suggestDocumentTitle(
      pageTitle: snapshot.pageTitle,
      effectiveUrl: effectiveUrl,
      capturedAtUtc: capturedAtUtc,
    );
    final sourceHost = Uri.parse(effectiveUrl).host.trim();
    try {
      final pdfBytes = await snapshotFile.readAsBytes();
      final resolution = await _documentImportService.createStoredDocumentIfNeeded(
        bytes: pdfBytes,
        originalFileName: _buildFileName(resolvedTitle, 'pdf'),
        mimeType: 'application/pdf',
        title: resolvedTitle,
        origin: DocumentOrigin.urlImport,
        sourceUrl: sourceUrl,
        snapshotStatus: DocumentSnapshotStatus.available,
        capturedAtUtc: capturedAtUtc,
        sourceHost: sourceHost.isEmpty ? null : sourceHost,
      );

      final alreadyLinked = await _isDocumentAlreadyLinked(
        target: target,
        documentId: resolution.document.id,
      );
      if (alreadyLinked) {
        return UrlDocumentSaveResult(
          document: resolution.document,
          outcome: UrlDocumentSaveOutcome.alreadyLinked,
        );
      }

      final attached = await _attachDocument(
        target: target,
        documentId: resolution.document.id,
      );
      if (!attached) {
        throw StateError('Failed to attach URL snapshot document.');
      }

      return UrlDocumentSaveResult(
        document: resolution.document,
        outcome: resolution.kind == DocumentImportResolutionKind.imported
            ? UrlDocumentSaveOutcome.importedAndLinked
            : UrlDocumentSaveOutcome.existingLinked,
      );
    } finally {
      if (await snapshotFile.exists()) {
        try {
          await snapshotFile.delete();
        } on FileSystemException {
          // Best effort cleanup for native temp files.
        }
      }
    }
  }

  Future<UrlDocumentSaveResult> saveLinkOnly({
    required UrlDocumentTarget target,
    required String sourceUrl,
    String? title,
  }) async {
    final normalizedUrl = normalizeSourceUrl(sourceUrl);
    final resolvedTitle = _resolveLinkOnlyTitle(
      sourceUrl: normalizedUrl,
      explicitTitle: title,
    );
    final sourceHost = Uri.parse(normalizedUrl).host.trim();
    final resolution = await _documentImportService.createStoredDocumentIfNeeded(
      bytes: Uint8List.fromList(utf8.encode('$normalizedUrl\n')),
      originalFileName: _buildFileName(resolvedTitle, 'txt'),
      mimeType: 'text/plain',
      title: resolvedTitle,
      origin: DocumentOrigin.urlImport,
      sourceUrl: normalizedUrl,
      snapshotStatus: DocumentSnapshotStatus.linkOnly,
      sourceDescription: normalizedUrl,
      sourceHost: sourceHost.isEmpty ? null : sourceHost,
    );

    final alreadyLinked = await _isDocumentAlreadyLinked(
      target: target,
      documentId: resolution.document.id,
    );
    if (alreadyLinked) {
      return UrlDocumentSaveResult(
        document: resolution.document,
        outcome: UrlDocumentSaveOutcome.alreadyLinked,
      );
    }

    final attached = await _attachDocument(
      target: target,
      documentId: resolution.document.id,
    );
    if (!attached) {
      throw StateError('Failed to attach URL link document.');
    }

    return UrlDocumentSaveResult(
      document: resolution.document,
      outcome: resolution.kind == DocumentImportResolutionKind.imported
          ? UrlDocumentSaveOutcome.importedAndLinked
          : UrlDocumentSaveOutcome.existingLinked,
    );
  }

  String suggestDocumentTitle({
    String? pageTitle,
    required String effectiveUrl,
    required DateTime capturedAtUtc,
  }) {
    final normalizedPageTitle = pageTitle?.trim();
    if (normalizedPageTitle != null && normalizedPageTitle.isNotEmpty) {
      return normalizedPageTitle;
    }

    final uri = Uri.parse(effectiveUrl);
    final host = uri.host.trim();
    final timestamp = DateFormat('yyyy-MM-dd HH-mm').format(
      capturedAtUtc.toLocal(),
    );
    if (host.isNotEmpty) {
      return '$host $timestamp';
    }

    return timestamp;
  }

  String _buildFileName(String title, String extension) {
    final sanitized = title
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), '_');
    final baseName = sanitized.isEmpty ? 'url_snapshot' : sanitized;
    return '${p.basenameWithoutExtension(baseName)}.$extension';
  }

  String _resolveLinkOnlyTitle({
    required String sourceUrl,
    String? explicitTitle,
  }) {
    final normalizedTitle = explicitTitle?.trim();
    if (normalizedTitle != null && normalizedTitle.isNotEmpty) {
      return normalizedTitle;
    }

    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) {
      return sourceUrl;
    }

    final pathSegments = uri.pathSegments
        .map((segment) => Uri.decodeComponent(segment).trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (pathSegments.isNotEmpty) {
      final baseName = p.basenameWithoutExtension(pathSegments.last).trim();
      if (baseName.isNotEmpty) {
        return baseName;
      }
    }

    final host = uri.host.trim();
    if (host.isNotEmpty) {
      return host;
    }

    return sourceUrl;
  }

  Future<bool> _isDocumentAlreadyLinked({
    required UrlDocumentTarget target,
    required String documentId,
  }) {
    return switch (target.type) {
      UrlDocumentTargetType.cruise => _attachmentService.isDocumentLinkedToCruise(
        cruiseId: target.id,
        documentId: documentId,
      ),
      UrlDocumentTargetType.excursion =>
        _attachmentService.isDocumentLinkedToExcursion(
          excursionId: target.id,
          documentId: documentId,
        ),
      UrlDocumentTargetType.travelItem =>
        _attachmentService.isDocumentLinkedToTravelItem(
          travelItemId: target.id,
          documentId: documentId,
        ),
      UrlDocumentTargetType.portCall =>
        _attachmentService.isDocumentLinkedToPortCall(
          portCallId: target.id,
          documentId: documentId,
        ),
      UrlDocumentTargetType.seaDay =>
        _attachmentService.isDocumentLinkedToSeaDay(
          seaDayId: target.id,
          documentId: documentId,
        ),
    };
  }

  Future<bool> _attachDocument({
    required UrlDocumentTarget target,
    required String documentId,
  }) {
    return switch (target.type) {
      UrlDocumentTargetType.cruise => _attachmentService.attachDocumentToCruise(
        cruiseId: target.id,
        documentId: documentId,
      ),
      UrlDocumentTargetType.excursion =>
        _attachmentService.attachDocumentToExcursion(
          excursionId: target.id,
          documentId: documentId,
        ),
      UrlDocumentTargetType.travelItem =>
        _attachmentService.attachDocumentToTravelItem(
          travelItemId: target.id,
          documentId: documentId,
        ),
      UrlDocumentTargetType.portCall =>
        _attachmentService.attachDocumentToPortCall(
          portCallId: target.id,
          documentId: documentId,
        ),
      UrlDocumentTargetType.seaDay => _attachmentService.attachDocumentToSeaDay(
        seaDayId: target.id,
        documentId: documentId,
      ),
    };
  }
}
