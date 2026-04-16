import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private let shareMethodChannelName = "de.mailsmart.cruiseplanner/share_intake"
  private let shareEventChannelName = "de.mailsmart.cruiseplanner/share_intake/events"
  private let shareKey = "ShareKey"
  private let shareTypeKey = "ShareTypeKey"
  private let shareQueueKey = "ShareQueueKey"

  private var pendingInitialShareBatches: [[[String: Any]]] = []
  private var shareEventSink: FlutterEventSink?
  private var shareBridgeConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      pendingInitialShareBatches = readSharedBatches(from: url)
    } else {
      pendingInitialShareBatches = readPendingSharedBatches()
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

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    publishPendingSharedItemsIfNeeded()
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    shareEventSink = events
    flushPendingSharedBatchesIfNeeded()
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
        if self.pendingInitialShareBatches.isEmpty {
          self.pendingInitialShareBatches = self.readPendingSharedBatches()
        }

        let currentItems = self.pendingInitialShareBatches.isEmpty
          ? []
          : self.pendingInitialShareBatches.removeFirst()
        result(currentItems)
        self.flushPendingSharedBatchesIfNeeded()
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
    let sharedBatches = readSharedBatches(from: url)
    guard !sharedBatches.isEmpty else {
      return false
    }

    dispatchSharedBatches(sharedBatches)
    return true
  }

  private func publishPendingSharedItemsIfNeeded() {
    let sharedBatches = readPendingSharedBatches()
    guard !sharedBatches.isEmpty else {
      return
    }

    dispatchSharedBatches(sharedBatches)
  }

  private func dispatchSharedBatches(_ sharedBatches: [[[String: Any]]]) {
    guard !sharedBatches.isEmpty else {
      return
    }

    if shareEventSink != nil {
      for batch in sharedBatches {
        dispatchSharedItems(batch)
      }
      return
    }

    pendingInitialShareBatches.append(contentsOf: sharedBatches)
  }

  private func dispatchSharedItems(_ sharedItems: [[String: Any]]) {
    guard let shareEventSink, !sharedItems.isEmpty else {
      if !sharedItems.isEmpty {
        pendingInitialShareBatches.append(sharedItems)
      }
      return
    }

    shareEventSink(sharedItems)
  }

  private func flushPendingSharedBatchesIfNeeded() {
    guard shareEventSink != nil, !pendingInitialShareBatches.isEmpty else {
      return
    }

    let queuedBatches = pendingInitialShareBatches
    pendingInitialShareBatches.removeAll(keepingCapacity: false)
    for batch in queuedBatches {
      dispatchSharedItems(batch)
    }
  }

  private func readSharedBatches(from url: URL) -> [[[String: Any]]] {
    guard isShareURL(url) else {
      return []
    }

    return readPendingSharedBatches(typeOverride: url.fragment?.lowercased())
  }

  private func readPendingSharedBatches(typeOverride: String? = nil) -> [[[String: Any]]] {
    guard
      let appGroupId = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String,
      let userDefaults = UserDefaults(
        suiteName: appGroupId.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    else {
      return []
    }

    if let queuedBatches = readQueuedSharedBatches(from: userDefaults), !queuedBatches.isEmpty {
      return queuedBatches
    }

    guard
      let shareType = (typeOverride ?? userDefaults.string(forKey: shareTypeKey))?.lowercased(),
      !shareType.isEmpty
    else {
      return []
    }

    defer {
      userDefaults.removeObject(forKey: shareKey)
      userDefaults.removeObject(forKey: shareTypeKey)
      userDefaults.synchronize()
    }

    let items: [[String: Any]]
    switch shareType {
    case "media":
      guard let data = userDefaults.data(forKey: shareKey) else {
        return []
      }

      let decoder = JSONDecoder()
      let sharedMedia = (try? decoder.decode([SharedMediaFile].self, from: data)) ?? []
      items = sharedMedia.compactMap(normalizeSharedMediaFile)
    case "text":
      let sharedText = userDefaults.stringArray(forKey: shareKey) ?? []
      items = sharedText.compactMap(normalizeSharedText)
    default:
      return []
    }

    return items.isEmpty ? [] : [items]
  }

  private func readQueuedSharedBatches(from userDefaults: UserDefaults) -> [[[String: Any]]]? {
    guard let queueData = userDefaults.data(forKey: shareQueueKey) else {
      return nil
    }

    defer {
      userDefaults.removeObject(forKey: shareQueueKey)
      userDefaults.removeObject(forKey: shareKey)
      userDefaults.removeObject(forKey: shareTypeKey)
      userDefaults.synchronize()
    }

    let decoder = JSONDecoder()
    let queuedBatches = (try? decoder.decode([PersistedShareBatch].self, from: queueData)) ?? []
    let normalizedBatches = queuedBatches.compactMap(normalizePersistedShareBatch)
    return normalizedBatches.isEmpty ? [] : normalizedBatches
  }

  private func normalizePersistedShareBatch(_ batch: PersistedShareBatch) -> [[String: Any]]? {
    let items: [[String: Any]]
    switch batch {
    case let .media(files):
      items = files.compactMap(normalizeSharedMediaFile)
    case let .text(values):
      items = values.compactMap(normalizeSharedText)
    }

    return items.isEmpty ? nil : items
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

private enum PersistedShareBatch: Codable {
  case media([SharedMediaFile])
  case text([String])

  private enum CodingKeys: String, CodingKey {
    case type
    case media
    case text
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(String.self, forKey: .type) {
    case "media":
      self = .media(try container.decode([SharedMediaFile].self, forKey: .media))
    case "text":
      self = .text(try container.decode([String].self, forKey: .text))
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .type,
        in: container,
        debugDescription: "Unsupported persisted share batch type."
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .media(items):
      try container.encode("media", forKey: .type)
      try container.encode(items, forKey: .media)
    case let .text(items):
      try container.encode("text", forKey: .type)
      try container.encode(items, forKey: .text)
    }
  }
}
