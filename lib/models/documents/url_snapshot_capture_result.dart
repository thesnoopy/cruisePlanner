class UrlSnapshotCaptureResult {
  const UrlSnapshotCaptureResult({
    required this.sourceUrl,
    required this.effectiveUrl,
    required this.filePath,
    this.pageTitle,
    this.pageCount,
    this.fileSizeBytes,
  });

  final String sourceUrl;
  final String effectiveUrl;
  final String filePath;
  final String? pageTitle;
  final int? pageCount;
  final int? fileSizeBytes;
}
