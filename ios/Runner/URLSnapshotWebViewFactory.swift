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
    let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
    let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let outputURL = tempDirectory.appendingPathComponent("url_snapshot_\(UUID().uuidString).pdf")
    var didBeginPdfContext = false
    var pageCount = 0
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

    func appendImagePage(_ image: UIImage, pageIndex: Int) {
      UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
      guard let context = UIGraphicsGetCurrentContext() else {
        return
      }
      UIColor.white.setFill()
      context.fill(pageRect)

      let scale = min(
        pageRect.width / image.size.width,
        pageRect.height / image.size.height
      )
      let targetWidth = image.size.width * scale
      let targetHeight = image.size.height * scale
      let targetRect = CGRect(
        x: (pageRect.width - targetWidth) / 2,
        y: (pageRect.height - targetHeight) / 2,
        width: targetWidth,
        height: targetHeight
      )
      image.draw(in: targetRect)
      NSLog(
        "UrlSnapshot pdf page=%d image=%.0fx%.0f pdf=%.1fx%.1f",
        pageIndex,
        image.size.width,
        image.size.height,
        pageRect.width,
        pageRect.height
      )
    }

    UIGraphicsBeginPDFContextToFile(outputURL.path, pageRect, nil)
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
          pageCount += 1
          NSLog(
            "UrlSnapshot capture page=%d scrollY=%.0f offset=%.0f extent=%.0f range=%.0f image=%.0fx%.0f estimatedPages=%d maxPages=%d",
            pageCount,
            scrollView.contentOffset.y,
            scrollView.contentOffset.y,
            scrollExtent,
            scrollRange,
            image.size.width,
            image.size.height,
            estimatedPages,
            maxPages
          )
          appendImagePage(image, pageIndex: pageCount)

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
