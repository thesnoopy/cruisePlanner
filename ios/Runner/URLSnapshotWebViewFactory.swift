import Flutter
import UIKit
import WebKit

final class URLSnapshotWebViewFactory: NSObject, FlutterPlatformViewFactory {
  static let viewType = "de.mailsmart.cruiseplanner/url_snapshot_webview"
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    URLSnapshotWebViewPlatformView(
      frame: frame,
      viewId: viewId,
      messenger: messenger
    )
  }
}

private final class URLSnapshotWebViewPlatformView: NSObject, FlutterPlatformView, FlutterStreamHandler, WKNavigationDelegate {
  private static let channelBase = "de.mailsmart.cruiseplanner/url_snapshot_webview"
  private static let captureDelay: TimeInterval = 0.35
  private static let overlap: CGFloat = 24
  private static let overlapDetectionMaxPx = 72
  private static let overlapDetectionMaxMultiplier = 3
  private static let overlapDetectionMinPx = 8
  private static let overlapDetectionRowStridePx = 2
  private static let overlapDetectionHorizontalSamples = 32
  private static let overlapDetectionMaxScore = 12.0
  private static let overlapDetectionScoreTolerance = 1.5
  private static let overlapDetectionFarMatchMinScoreGain = 2.0
  private static let overlapDetectionMinDetailScore = 3.0
  private static let minPdfContentHeightPx = 48
  private static let minCapturePages = 40
  private static let capturePageBuffer = 12
  private static let maxCapturePagesSafetyLimit = 100
  private static let hideCaptureOverlaysScript = """
    (function() {
      const body = document.body;
      if (!body) {
        return 0;
      }
      const overlayAttr = 'data-url-snapshot-overlay-hidden';
      const visibilityAttr = 'data-url-snapshot-overlay-visibility';
      const displayAttr = 'data-url-snapshot-overlay-display';
      const pointerAttr = 'data-url-snapshot-overlay-pointer-events';
      const nodes = body.querySelectorAll('*');
      const viewportHeight = window.innerHeight || document.documentElement.clientHeight || 0;
      const edgeThreshold = Math.max(24, viewportHeight * 0.12);
      let hiddenCount = 0;
      for (const node of nodes) {
        if (!(node instanceof HTMLElement)) {
          continue;
        }
        if (node.getAttribute(overlayAttr) === '1') {
          continue;
        }
        const style = window.getComputedStyle(node);
        if (style.position !== 'fixed' && style.position !== 'sticky') {
          continue;
        }
        if (style.display === 'none' || style.visibility === 'hidden') {
          continue;
        }
        const opacity = parseFloat(style.opacity || '1');
        if (!Number.isFinite(opacity) || opacity <= 0.01) {
          continue;
        }
        const rect = node.getBoundingClientRect();
        if (rect.width <= 0 || rect.height <= 0) {
          continue;
        }
        if (viewportHeight <= 0 || rect.height > viewportHeight * 0.35) {
          continue;
        }
        const nearTop = rect.top <= edgeThreshold;
        const nearBottom = rect.bottom >= (viewportHeight - edgeThreshold);
        if (!nearTop && !nearBottom) {
          continue;
        }
        node.setAttribute(overlayAttr, '1');
        node.setAttribute(visibilityAttr, node.style.visibility || '');
        node.setAttribute(displayAttr, node.style.display || '');
        node.setAttribute(pointerAttr, node.style.pointerEvents || '');
        node.style.visibility = 'hidden';
        node.style.pointerEvents = 'none';
        hiddenCount += 1;
      }
      return hiddenCount;
    })();
    """
  private static let restoreCaptureOverlaysScript = """
    (function() {
      const body = document.body;
      if (!body) {
        return 0;
      }
      const overlayAttr = 'data-url-snapshot-overlay-hidden';
      const visibilityAttr = 'data-url-snapshot-overlay-visibility';
      const displayAttr = 'data-url-snapshot-overlay-display';
      const pointerAttr = 'data-url-snapshot-overlay-pointer-events';
      const nodes = body.querySelectorAll('[' + overlayAttr + '="1"]');
      let restoredCount = 0;
      for (const node of nodes) {
        if (!(node instanceof HTMLElement)) {
          continue;
        }
        node.style.visibility = node.getAttribute(visibilityAttr) || '';
        node.style.display = node.getAttribute(displayAttr) || '';
        node.style.pointerEvents = node.getAttribute(pointerAttr) || '';
        node.removeAttribute(overlayAttr);
        node.removeAttribute(visibilityAttr);
        node.removeAttribute(displayAttr);
        node.removeAttribute(pointerAttr);
        restoredCount += 1;
      }
      return restoredCount;
    })();
    """

  private let webView: WKWebView
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private var eventSink: FlutterEventSink?
  private var titleObservation: NSKeyValueObservation?
  private var isCapturing = false

  private enum OverlapStrategy: String {
    case none
    case detected
    case fallback
  }

  private struct OverlapCropDecision {
    let cropTopPx: Int
    let score: Double?
    let strategy: OverlapStrategy
  }

  private struct LumaProfile {
    let rowStridePx: Int
    let sampleCount: Int
    let rows: Int
    let values: [UInt8]
  }

  private struct OverlapReference {
    let heightPx: Int
    let profile: LumaProfile
  }

  private struct OverlapCandidate {
    let overlapPx: Int
    let score: Double
  }

  private struct RasterImage {
    let width: Int
    let height: Int
    let bytesPerRow: Int
    let data: Data
  }

  init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
    let configuration = WKWebViewConfiguration()
    configuration.preferences.javaScriptEnabled = true
    self.webView = WKWebView(frame: frame, configuration: configuration)
    self.methodChannel = FlutterMethodChannel(
      name: "\(Self.channelBase)/\(viewId)",
      binaryMessenger: messenger
    )
    self.eventChannel = FlutterEventChannel(
      name: "\(Self.channelBase)/\(viewId)/events",
      binaryMessenger: messenger
    )
    super.init()

    webView.navigationDelegate = self
    titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
      self?.emitEvent(
        type: "titleChanged",
        url: webView.url?.absoluteString,
        pageTitle: webView.title
      )
    }

    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
    eventChannel.setStreamHandler(self)
  }

  deinit {
    titleObservation?.invalidate()
    methodChannel.setMethodCallHandler(nil)
    eventChannel.setStreamHandler(nil)
    webView.stopLoading()
    webView.navigationDelegate = nil
  }

  func view() -> UIView {
    webView
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    emitEvent(
      type: "pageStarted",
      url: webView.url?.absoluteString,
      pageTitle: webView.title
    )
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    emitEvent(
      type: "pageFinished",
      url: webView.url?.absoluteString,
      pageTitle: webView.title
    )
  }

  func webView(
    _ webView: WKWebView,
    didFail navigation: WKNavigation!,
    withError error: Error
  ) {
    emitEvent(
      type: "loadFailed",
      url: webView.url?.absoluteString,
      pageTitle: webView.title,
      message: error.localizedDescription
    )
  }

  func webView(
    _ webView: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    emitEvent(
      type: "loadFailed",
      url: webView.url?.absoluteString,
      pageTitle: webView.title,
      message: error.localizedDescription
    )
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadUrl":
      guard
        let arguments = call.arguments as? [String: Any],
        let urlString = (arguments["url"] as? String)?
          .trimmingCharacters(in: .whitespacesAndNewlines),
        let url = URL(string: urlString),
        !urlString.isEmpty
      else {
        result(
          FlutterError(
            code: "invalid_args",
            message: "Missing URL.",
            details: nil
          )
        )
        return
      }

      webView.load(URLRequest(url: url))
      result(nil)
    case "reload":
      webView.reload()
      result(nil)
    case "capturePdf":
      guard
        let arguments = call.arguments as? [String: Any],
        let sourceUrl = (arguments["sourceUrl"] as? String)?
          .trimmingCharacters(in: .whitespacesAndNewlines),
        !sourceUrl.isEmpty
      else {
        result(
          FlutterError(
            code: "invalid_args",
            message: "Missing sourceUrl.",
            details: nil
          )
        )
        return
      }

      capturePdf(sourceUrl: sourceUrl, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func capturePdf(sourceUrl: String, result: @escaping FlutterResult) {
    guard webView.url != nil else {
      result(
        FlutterError(
          code: "page_not_loaded",
          message: "No page is currently loaded.",
          details: nil
        )
      )
      return
    }

    guard !webView.isLoading else {
      result(
        FlutterError(
          code: "page_not_loaded",
          message: "The page is still loading.",
          details: nil
        )
      )
      return
    }

    guard !isCapturing else {
      result(
        FlutterError(
          code: "capture_in_progress",
          message: "A PDF capture is already running.",
          details: nil
        )
      )
      return
    }

    captureVisibleSegmentsAsPdf(sourceUrl: sourceUrl, result: result)
  }

  private func captureVisibleSegmentsAsPdf(
    sourceUrl: String,
    result: @escaping FlutterResult
  ) {
    let viewportSize = webView.bounds.size
    guard viewportSize.width > 0, viewportSize.height > 0 else {
      result(
        FlutterError(
          code: "layout_failed",
          message: "The webpage view has no visible size.",
          details: nil
        )
      )
      return
    }

    let scrollView = webView.scrollView
    let originalOffset = scrollView.contentOffset
    let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let outputURL = tempDirectory.appendingPathComponent("url_snapshot_\(UUID().uuidString).pdf")
    var didBeginPdfContext = false
    var pageCount = 0
    var previousOverlapReference: OverlapReference?
    isCapturing = true

    func closePdfContext() {
      guard didBeginPdfContext else {
        return
      }
      UIGraphicsEndPDFContext()
      didBeginPdfContext = false
    }

    func restoreCaptureOverlayState(completion: @escaping () -> Void) {
      restoreCaptureOverlays {
        completion()
      }
    }

    func finishWithError(code: String, message: String) {
      restoreCaptureOverlayState {
        scrollView.setContentOffset(originalOffset, animated: false)
        closePdfContext()
        try? FileManager.default.removeItem(at: outputURL)
        self.isCapturing = false
        result(
          FlutterError(
            code: code,
            message: message,
            details: nil
          )
        )
      }
    }

    func finishWithSuccess(pdfFile: URL, pageCount: Int) {
      restoreCaptureOverlayState {
        scrollView.setContentOffset(originalOffset, animated: false)
        closePdfContext()
        self.isCapturing = false
        let fileSize = (try? pdfFile.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard fileSize > 0 else {
          try? FileManager.default.removeItem(at: pdfFile)
          result(
            FlutterError(
              code: "empty_pdf",
              message: "Generated PDF is empty.",
              details: nil
            )
          )
          return
        }
        NSLog(
          "UrlSnapshot capture complete pageCount=%d fileSizeBytes=%d filePath=%@",
          pageCount,
          fileSize,
          pdfFile.path
        )
        result([
          "filePath": pdfFile.path,
          "title": self.webView.title as Any,
          "url": self.webView.url?.absoluteString ?? sourceUrl,
          "pageCount": pageCount,
          "fileSizeBytes": fileSize,
        ])
      }
    }

    func appendImagePage(_ image: UIImage, pageIndex: Int, topCropPx: Int) {
      let safeTopCropPx = self.sanitizedTopCropPx(
        topCropPx,
        imagePixelHeight: self.pixelHeight(for: image)
      )
      let cropTopPoints = CGFloat(safeTopCropPx) / max(image.scale, 1)
      let visibleWidth = image.size.width
      let visibleHeight = max(image.size.height - cropTopPoints, 1 / max(image.scale, 1))
      let pageRect = CGRect(
        x: 0,
        y: 0,
        width: visibleWidth,
        height: visibleHeight
      )
      UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
      guard let context = UIGraphicsGetCurrentContext() else {
        return
      }
      UIColor.white.setFill()
      context.fill(pageRect)

      context.saveGState()
      context.clip(to: pageRect)
      let drawRect = CGRect(
        x: 0,
        y: -cropTopPoints,
        width: image.size.width,
        height: image.size.height
      )
      image.draw(in: drawRect)
      context.restoreGState()
      NSLog(
        "UrlSnapshot pdf page=%d image=%.0fx%.0f cropTopPx=%d pdf=%.1fx%.1f",
        pageIndex,
        image.size.width,
        image.size.height,
        safeTopCropPx,
        pageRect.width,
        pageRect.height
      )
    }

    UIGraphicsBeginPDFContextToFile(outputURL.path, .zero, nil)
    didBeginPdfContext = true

    let initialScrollExtent = max(scrollView.bounds.height, 1)
    let initialScrollRange = max(scrollView.contentSize.height, initialScrollExtent)
    let initialStep = max(initialScrollExtent - Self.overlap, 1)
    let initialEstimatedPages = estimateRequiredPages(
      scrollRange: initialScrollRange,
      scrollExtent: initialScrollExtent,
      step: initialStep
    )
    let initialMaxPages = determineMaxCapturePages(estimatedPages: initialEstimatedPages)
    NSLog(
      "UrlSnapshot capture start range=%.0f extent=%.0f step=%.0f estimatedPages=%d maxPages=%d",
      initialScrollRange,
      initialScrollExtent,
      initialStep,
      initialEstimatedPages,
      initialMaxPages
    )

    func captureStep() {
      let currentOffsetY = scrollView.contentOffset.y
      hideCaptureOverlays {
        self.webView.takeSnapshot(with: nil) { [weak self] image, error in
          guard let self else {
            finishWithError(code: "cancelled", message: "PDF capture was cancelled.")
            return
          }

          if let error {
            finishWithError(code: "write_failed", message: error.localizedDescription)
            return
          }

          guard let image else {
            finishWithError(
              code: "write_failed",
              message: "Failed to capture the visible webpage area."
            )
            return
          }

          pageCount += 1
          let overlapDecision: OverlapCropDecision
          let currentRasterImage = self.makeRasterImage(from: image)
          if let currentRasterImage {
            overlapDecision = self.determineOverlapCrop(
              pageIndex: pageCount,
              currentRasterImage: currentRasterImage,
              previousReference: previousOverlapReference
            )
          } else if pageCount == 1 {
            overlapDecision = OverlapCropDecision(
              cropTopPx: 0,
              score: nil,
              strategy: .none
            )
          } else {
            overlapDecision = self.fallbackOverlapDecision(
              fallbackCropPx: self.safeFallbackCropPx(forImagePixelHeight: self.pixelHeight(for: image)),
              fallbackScore: nil
            )
          }

          let scrollExtent = max(scrollView.bounds.height, 1)
          let scrollRange = max(scrollView.contentSize.height, scrollExtent)
          let maxOffsetY = max(0, scrollRange - scrollExtent)
          let step = max(scrollExtent - Self.overlap, 1)
          let estimatedPages = estimateRequiredPages(
            scrollRange: scrollRange,
            scrollExtent: scrollExtent,
            step: step
          )
          let maxPages = determineMaxCapturePages(estimatedPages: estimatedPages)
          NSLog(
            "UrlSnapshot capture page=%d scrollY=%.0f offset=%.0f extent=%.0f range=%.0f image=%.0fx%.0f estimatedPages=%d maxPages=%d overlapCropPx=%d overlapScore=%@ overlapStrategy=%@",
            pageCount,
            scrollView.contentOffset.y,
            scrollView.contentOffset.y,
            scrollExtent,
            scrollRange,
            image.size.width,
            image.size.height,
            estimatedPages,
            maxPages,
            overlapDecision.cropTopPx,
            self.formatOverlapScore(overlapDecision.score),
            overlapDecision.strategy.rawValue
          )
          appendImagePage(
            image,
            pageIndex: pageCount,
            topCropPx: overlapDecision.cropTopPx
          )
          if let currentRasterImage {
            previousOverlapReference = self.buildOverlapReference(
              from: currentRasterImage,
              topCropPx: overlapDecision.cropTopPx
            )
          } else {
            previousOverlapReference = nil
          }

          if currentOffsetY >= maxOffsetY - 1 {
            finishWithSuccess(pdfFile: outputURL, pageCount: pageCount)
            return
          }

          if pageCount >= maxPages {
            NSLog(
              "UrlSnapshot capture limit estimatedPages=%d maxPages=%d lastScrollY=%.0f",
              estimatedPages,
              maxPages,
              scrollView.contentOffset.y
            )
            finishWithError(
              code: "capture_limit_exceeded",
              message: "Page requires about \(estimatedPages) pages, limit is \(maxPages)."
            )
            return
          }

          let nextOffsetY = min(
            maxOffsetY,
            currentOffsetY + step
          )
          if nextOffsetY <= currentOffsetY {
            finishWithSuccess(pdfFile: outputURL, pageCount: pageCount)
            return
          }

          scrollView.setContentOffset(
            CGPoint(x: originalOffset.x, y: nextOffsetY),
            animated: false
          )
          DispatchQueue.main.asyncAfter(deadline: .now() + Self.captureDelay) {
            captureStep()
          }
        }
      }
    }

    scrollView.setContentOffset(
      CGPoint(x: originalOffset.x, y: 0),
      animated: false
    )
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.captureDelay) {
      captureStep()
    }
  }

  private func hideCaptureOverlays(completion: @escaping () -> Void) {
    NSLog("UrlSnapshot overlay cleanup start")
    runOverlayScript(
      Self.hideCaptureOverlaysScript,
      logPrefix: "overlay cleanup hiddenOverlayCount",
      completion: { _ in completion() }
    )
  }

  private func restoreCaptureOverlays(completion: @escaping () -> Void) {
    runOverlayScript(
      Self.restoreCaptureOverlaysScript,
      logPrefix: "overlay cleanup restored",
      completion: { _ in completion() }
    )
  }

  private func runOverlayScript(
    _ script: String,
    logPrefix: String,
    completion: @escaping (Int) -> Void
  ) {
    webView.evaluateJavaScript(script) { result, error in
      let count = Self.integerResult(from: result)
      if let error {
        NSLog("UrlSnapshot %@=%d error=%@", logPrefix, count, error.localizedDescription)
      } else {
        NSLog("UrlSnapshot %@=%d", logPrefix, count)
      }
      completion(count)
    }
  }

  private static func integerResult(from value: Any?) -> Int {
    if let number = value as? NSNumber {
      return number.intValue
    }
    if let string = value as? String, let count = Int(string) {
      return count
    }
    return 0
  }

  private func determineOverlapCrop(
    pageIndex: Int,
    currentRasterImage: RasterImage,
    previousReference: OverlapReference?
  ) -> OverlapCropDecision {
    if pageIndex == 1 {
      return OverlapCropDecision(cropTopPx: 0, score: nil, strategy: .none)
    }

    guard let previousReference else {
      return fallbackOverlapDecision(
        fallbackCropPx: safeFallbackCropPx(forImagePixelHeight: currentRasterImage.height),
        fallbackScore: nil
      )
    }

    let safeMaxCropPx = max(currentRasterImage.height - Self.minPdfContentHeightPx, 0)
    let fallbackCropPx = min(Int(Self.overlap.rounded()), safeMaxCropPx)
    let preferredSearchLimitPx = min(
      Self.overlapDetectionMaxPx,
      max(
        Self.overlapDetectionMinPx,
        Int(Self.overlap.rounded()) * Self.overlapDetectionMaxMultiplier
      )
    )
    let searchLimitPx = min(
      safeMaxCropPx,
      min(previousReference.heightPx, preferredSearchLimitPx)
    )
    if searchLimitPx < Self.overlapDetectionMinPx {
      return fallbackOverlapDecision(fallbackCropPx: fallbackCropPx, fallbackScore: nil)
    }

    guard
      let currentProfile = buildLumaProfile(
        from: currentRasterImage,
        startY: 0,
        endYExclusive: searchLimitPx
      )
    else {
      return fallbackOverlapDecision(fallbackCropPx: fallbackCropPx, fallbackScore: nil)
    }

    let previousProfile = previousReference.profile
    guard
      previousProfile.rowStridePx == currentProfile.rowStridePx,
      previousProfile.sampleCount == currentProfile.sampleCount
    else {
      return fallbackOverlapDecision(fallbackCropPx: fallbackCropPx, fallbackScore: nil)
    }

    let maxCandidateRows = min(previousProfile.rows, currentProfile.rows)
    let minCandidateRows = ceilDiv(Self.overlapDetectionMinPx, currentProfile.rowStridePx)
    if maxCandidateRows < minCandidateRows {
      return fallbackOverlapDecision(fallbackCropPx: fallbackCropPx, fallbackScore: nil)
    }

    let fallbackScore = overlapScoreForCrop(
      previousProfile: previousProfile,
      currentProfile: currentProfile,
      overlapCropPx: fallbackCropPx
    )
    var validCandidates: [OverlapCandidate] = []
    var bestScore = Double.greatestFiniteMagnitude

    for candidateRows in minCandidateRows...maxCandidateRows {
      let overlapCandidatePx = candidateRows * currentProfile.rowStridePx
      let score = compareOverlapScore(
        previousProfile: previousProfile,
        currentProfile: currentProfile,
        comparedRows: candidateRows
      )
      bestScore = min(bestScore, score)
      let previousDetail = profileDetailScore(
        profile: previousProfile,
        startRow: previousProfile.rows - candidateRows,
        rowCount: candidateRows
      )
      let currentDetail = profileDetailScore(
        profile: currentProfile,
        startRow: 0,
        rowCount: candidateRows
      )
      if
        min(previousDetail, currentDetail) >= Self.overlapDetectionMinDetailScore &&
        score <= Self.overlapDetectionMaxScore
      {
        validCandidates.append(
          OverlapCandidate(
            overlapPx: overlapCandidatePx,
            score: score
          )
        )
      }
    }

    if !validCandidates.isEmpty {
      let toleratedScore = bestScore + Self.overlapDetectionScoreTolerance
      if let detectedCandidate = validCandidates
        .filter({ $0.score <= toleratedScore })
        .min(
          by: {
            let leftDistance = abs($0.overlapPx - Int(Self.overlap.rounded()))
            let rightDistance = abs($1.overlapPx - Int(Self.overlap.rounded()))
            if leftDistance != rightDistance {
              return leftDistance < rightDistance
            }
            if $0.score != $1.score {
              return $0.score < $1.score
            }
            return $0.overlapPx < $1.overlapPx
          }
        )
      {
        let isFarFromExpected = abs(detectedCandidate.overlapPx - Int(Self.overlap.rounded())) > Int(Self.overlap.rounded())
        let hasClearlyBetterScore: Bool
        if let fallbackScore {
          hasClearlyBetterScore =
            detectedCandidate.score <= fallbackScore - Self.overlapDetectionFarMatchMinScoreGain
        } else {
          hasClearlyBetterScore = true
        }
        if isFarFromExpected && !hasClearlyBetterScore {
          return fallbackOverlapDecision(
            fallbackCropPx: fallbackCropPx,
            fallbackScore: fallbackScore
          )
        }
        return OverlapCropDecision(
          cropTopPx: min(detectedCandidate.overlapPx, safeMaxCropPx),
          score: detectedCandidate.score,
          strategy: .detected
        )
      }
    }

    return fallbackOverlapDecision(
      fallbackCropPx: fallbackCropPx,
      fallbackScore: fallbackScore
    )
  }

  private func buildOverlapReference(
    from rasterImage: RasterImage,
    topCropPx: Int
  ) -> OverlapReference? {
    let safeTopCropPx = sanitizedTopCropPx(topCropPx, imagePixelHeight: rasterImage.height)
    let writtenHeightPx = max(rasterImage.height - safeTopCropPx, 0)
    if writtenHeightPx < Self.overlapDetectionMinPx {
      return nil
    }

    let preferredReferenceHeightPx = min(
      Self.overlapDetectionMaxPx,
      max(
        Self.overlapDetectionMinPx,
        Int(Self.overlap.rounded()) * Self.overlapDetectionMaxMultiplier
      )
    )
    let referenceHeightPx = min(writtenHeightPx, preferredReferenceHeightPx)
    let startY = rasterImage.height - referenceHeightPx
    guard
      let profile = buildLumaProfile(
        from: rasterImage,
        startY: startY,
        endYExclusive: rasterImage.height
      )
    else {
      return nil
    }

    return OverlapReference(heightPx: referenceHeightPx, profile: profile)
  }

  private func makeRasterImage(from image: UIImage) -> RasterImage? {
    let width = max(Int((image.size.width * image.scale).rounded()), 1)
    let height = max(Int((image.size.height * image.scale).rounded()), 1)
    let bytesPerRow = width * 4
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
      CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    )
    var data = Data(count: bytesPerRow * height)
    let rendered = data.withUnsafeMutableBytes { rawBuffer -> Bool in
      guard
        let baseAddress = rawBuffer.baseAddress,
        let context = CGContext(
          data: baseAddress,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: bytesPerRow,
          space: colorSpace,
          bitmapInfo: bitmapInfo.rawValue
        )
      else {
        return false
      }

      context.setFillColor(UIColor.white.cgColor)
      context.fill(
        CGRect(
          x: 0,
          y: 0,
          width: CGFloat(width),
          height: CGFloat(height)
        )
      )
      UIGraphicsPushContext(context)
      image.draw(
        in: CGRect(
          x: 0,
          y: 0,
          width: CGFloat(width),
          height: CGFloat(height)
        )
      )
      UIGraphicsPopContext()
      return true
    }

    guard rendered else {
      return nil
    }

    return RasterImage(
      width: width,
      height: height,
      bytesPerRow: bytesPerRow,
      data: data
    )
  }

  private func buildLumaProfile(
    from rasterImage: RasterImage,
    startY: Int,
    endYExclusive: Int
  ) -> LumaProfile? {
    let safeStartY = min(max(startY, 0), rasterImage.height)
    let safeEndY = min(max(endYExclusive, safeStartY), rasterImage.height)
    let sampledHeightPx = safeEndY - safeStartY
    if rasterImage.width <= 0 || sampledHeightPx <= 0 {
      return nil
    }

    let sampleCount = max(1, min(Self.overlapDetectionHorizontalSamples, rasterImage.width))
    let rowStridePx = max(Self.overlapDetectionRowStridePx, 1)
    let rowCount = ceilDiv(sampledHeightPx, rowStridePx)
    let values: [UInt8]? = rasterImage.data.withUnsafeBytes { rawBuffer in
      let buffer = rawBuffer.bindMemory(to: UInt8.self)
      guard let baseAddress = buffer.baseAddress else {
        return nil
      }

      var sampledValues = [UInt8](repeating: 0, count: rowCount * sampleCount)
      var rowIndex = 0
      var y = safeStartY
      while y < safeEndY && rowIndex < rowCount {
        let rowOffset = rowIndex * sampleCount
        let pixelRowOffset = y * rasterImage.bytesPerRow
        for sampleIndex in 0..<sampleCount {
          let x = min(
            rasterImage.width - 1,
            Int(
              ((Int64(sampleIndex) * 2 + 1) * Int64(rasterImage.width)) /
                Int64(sampleCount * 2)
            )
          )
          let pixelOffset = pixelRowOffset + (x * 4)
          let red = baseAddress[pixelOffset]
          let green = baseAddress[pixelOffset + 1]
          let blue = baseAddress[pixelOffset + 2]
          sampledValues[rowOffset + sampleIndex] = luminanceValue(
            red: red,
            green: green,
            blue: blue
          )
        }
        rowIndex += 1
        y += rowStridePx
      }
      return sampledValues
    }

    guard let values else {
      return nil
    }

    return LumaProfile(
      rowStridePx: rowStridePx,
      sampleCount: sampleCount,
      rows: rowCount,
      values: values
    )
  }

  private func overlapScoreForCrop(
    previousProfile: LumaProfile,
    currentProfile: LumaProfile,
    overlapCropPx: Int
  ) -> Double? {
    let comparedRows = overlapCropPx / currentProfile.rowStridePx
    if
      overlapCropPx < Self.overlapDetectionMinPx ||
      comparedRows <= 0 ||
      previousProfile.rows < comparedRows ||
      currentProfile.rows < comparedRows
    {
      return nil
    }

    return compareOverlapScore(
      previousProfile: previousProfile,
      currentProfile: currentProfile,
      comparedRows: comparedRows
    )
  }

  private func compareOverlapScore(
    previousProfile: LumaProfile,
    currentProfile: LumaProfile,
    comparedRows: Int
  ) -> Double {
    let sampleCount = previousProfile.sampleCount
    let previousStartRow = previousProfile.rows - comparedRows
    var totalDifference = 0.0
    var comparedValues = 0

    for rowIndex in 0..<comparedRows {
      let previousOffset = (previousStartRow + rowIndex) * sampleCount
      let currentOffset = rowIndex * sampleCount
      for sampleIndex in 0..<sampleCount {
        totalDifference += Double(
          abs(
            Int(previousProfile.values[previousOffset + sampleIndex]) -
              Int(currentProfile.values[currentOffset + sampleIndex])
          )
        )
        comparedValues += 1
      }
    }

    if comparedValues == 0 {
      return .greatestFiniteMagnitude
    }
    return totalDifference / Double(comparedValues)
  }

  private func profileDetailScore(
    profile: LumaProfile,
    startRow: Int,
    rowCount: Int
  ) -> Double {
    if rowCount < 2 || profile.rows < 2 {
      return 0
    }

    let clampedStartRow = min(max(startRow, 0), profile.rows - 1)
    let clampedEndRow = min(clampedStartRow + rowCount, profile.rows)
    if clampedEndRow - clampedStartRow < 2 {
      return 0
    }

    let sampleCount = profile.sampleCount
    var totalDifference = 0.0
    var comparedValues = 0

    for rowIndex in clampedStartRow..<(clampedEndRow - 1) {
      let currentOffset = rowIndex * sampleCount
      let nextOffset = (rowIndex + 1) * sampleCount
      for sampleIndex in 0..<sampleCount {
        totalDifference += Double(
          abs(
            Int(profile.values[currentOffset + sampleIndex]) -
              Int(profile.values[nextOffset + sampleIndex])
          )
        )
        comparedValues += 1
      }
    }

    if comparedValues == 0 {
      return 0
    }
    return totalDifference / Double(comparedValues)
  }

  private func luminanceValue(red: UInt8, green: UInt8, blue: UInt8) -> UInt8 {
    UInt8((Int(red) * 54 + Int(green) * 183 + Int(blue) * 19) / 256)
  }

  private func safeFallbackCropPx(forImagePixelHeight imagePixelHeight: Int) -> Int {
    sanitizedTopCropPx(Int(Self.overlap.rounded()), imagePixelHeight: imagePixelHeight)
  }

  private func fallbackOverlapDecision(
    fallbackCropPx: Int,
    fallbackScore: Double?
  ) -> OverlapCropDecision {
    if fallbackCropPx > 0 {
      return OverlapCropDecision(
        cropTopPx: fallbackCropPx,
        score: fallbackScore,
        strategy: .fallback
      )
    }
    return OverlapCropDecision(cropTopPx: 0, score: fallbackScore, strategy: .none)
  }

  private func sanitizedTopCropPx(_ topCropPx: Int, imagePixelHeight: Int) -> Int {
    let maxCropPx = max(imagePixelHeight - Self.minPdfContentHeightPx, 0)
    return min(max(topCropPx, 0), maxCropPx)
  }

  private func pixelHeight(for image: UIImage) -> Int {
    max(Int((image.size.height * image.scale).rounded()), 1)
  }

  private func formatOverlapScore(_ score: Double?) -> String {
    guard let score else {
      return "n/a"
    }
    return String(format: "%.2f", score)
  }

  private func ceilDiv(_ value: Int, _ divisor: Int) -> Int {
    guard divisor > 0 else {
      return 0
    }
    return (value + divisor - 1) / divisor
  }

  private func estimateRequiredPages(
    scrollRange: CGFloat,
    scrollExtent: CGFloat,
    step: CGFloat
  ) -> Int {
    let safeExtent = max(scrollExtent, 1)
    let safeStep = max(step, 1)
    let maxOffset = max(0, scrollRange - safeExtent)
    if maxOffset <= 0 {
      return 1
    }
    return 1 + Int(ceil(maxOffset / safeStep))
  }

  private func determineMaxCapturePages(estimatedPages: Int) -> Int {
    min(
      Self.maxCapturePagesSafetyLimit,
      max(Self.minCapturePages, estimatedPages + Self.capturePageBuffer)
    )
  }

  private func emitEvent(
    type: String,
    url: String? = nil,
    pageTitle: String? = nil,
    message: String? = nil
  ) {
    eventSink?([
      "type": type,
      "url": url as Any,
      "pageTitle": pageTitle as Any,
      "message": message as Any,
    ])
  }
}
