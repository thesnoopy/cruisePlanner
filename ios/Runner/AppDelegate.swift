import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private let shareMethodChannelName = "de.mailsmart.cruiseplanner/share_intake"
  private let shareEventChannelName = "de.mailsmart.cruiseplanner/share_intake/events"
  private let shareKey = "ShareKey"

  private var pendingInitialShareItems: [[String: Any]]?
  private var shareEventSink: FlutterEventSink?
  private var shareBridgeConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      pendingInitialShareItems = readSharedItems(from: url)
    }

    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      configureShareBridge(for: controller.binaryMessenger)
    }

    return result
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let handledShare = handleShareURL(url)
    let handledByFlutter = super.application(app, open: url, options: options)
    return handledShare || handledByFlutter
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    shareEventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    shareEventSink = nil
    return nil
  }

  private func configureShareBridge(for messenger: FlutterBinaryMessenger) {
    if shareBridgeConfigured {
      return
    }

    shareBridgeConfigured = true

    let methodChannel = FlutterMethodChannel(
      name: shareMethodChannelName,
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "getInitialSharedItems":
        result(self.pendingInitialShareItems ?? [])
        self.pendingInitialShareItems = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: shareEventChannelName,
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(self)
  }

  private func handleShareURL(_ url: URL) -> Bool {
    guard let sharedItems = readSharedItems(from: url) else {
      return false
    }

    if let shareEventSink, !sharedItems.isEmpty {
      shareEventSink(sharedItems)
    } else {
      pendingInitialShareItems = sharedItems
    }

    return true
  }

  private func readSharedItems(from url: URL) -> [[String: Any]]? {
    guard isShareURL(url) else {
      return nil
    }

    guard
      let appGroupId = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String,
      let userDefaults = UserDefaults(
        suiteName: appGroupId.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    else {
      return []
    }

    defer {
      userDefaults.removeObject(forKey: shareKey)
      userDefaults.synchronize()
    }

    switch url.fragment?.lowercased() {
    case "media":
      guard let data = userDefaults.data(forKey: shareKey) else {
        return []
      }

      let decoder = JSONDecoder()
      let sharedMedia = (try? decoder.decode([SharedMediaFile].self, from: data)) ?? []
      return sharedMedia.compactMap(normalizeSharedMediaFile)
    case "text":
      let sharedText = userDefaults.stringArray(forKey: shareKey) ?? []
      return sharedText.compactMap(normalizeSharedText)
    default:
      return []
    }
  }

  private func isShareURL(_ url: URL) -> Bool {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier?.lowercased() else {
      return false
    }

    return url.scheme?.lowercased() == "sharemedia-\(bundleIdentifier)"
      && url.host?.lowercased() == "dataurl=\(shareKey.lowercased())"
  }

  private func normalizeSharedMediaFile(_ file: SharedMediaFile) -> [String: Any]? {
    guard let normalizedValue = normalizeFileLikeValue(file.path) else {
      return nil
    }

    var item: [String: Any] = [
      "kind": file.type == .image ? "image" : "file",
      "value": normalizedValue,
    ]

    if let fileName = extractFileName(from: normalizedValue) {
      item["fileName"] = fileName
    }

    return item
  }

  private func normalizeSharedText(_ value: String) -> [String: Any]? {
    let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedValue.isEmpty else {
      return nil
    }

    return [
      "kind": looksLikeURL(normalizedValue) ? "url" : "text",
      "value": normalizedValue,
    ]
  }

  private func normalizeFileLikeValue(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return nil
    }

    guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else {
      return trimmed
    }

    if scheme == "file" {
      return url.path
    }

    return trimmed
  }

  private func extractFileName(from value: String) -> String? {
    let url = URL(fileURLWithPath: value)
    let fileName = url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
    return fileName.isEmpty ? nil : fileName
  }

  private func looksLikeURL(_ value: String) -> Bool {
    guard let url = URL(string: value), let scheme = url.scheme?.lowercased() else {
      return false
    }

    return scheme == "http" || scheme == "https"
  }
}

private enum SharedMediaType: Int, Codable {
  case image
  case file
}

private struct SharedMediaFile: Codable {
  let path: String
  let thumbnail: String?
  let duration: Double?
  let type: SharedMediaType
}
