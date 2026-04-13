import MobileCoreServices
import Social
import UIKit

final class ShareViewController: SLComposeServiceViewController {
  private var hostAppBundleIdentifier = ""
  private var appGroupId = ""
  private let sharedKey = "ShareKey"
  private let imageContentType = kUTTypeImage as String
  private let textContentType = kUTTypeText as String
  private let urlContentType = kUTTypeURL as String
  private let fileURLType = kUTTypeFileURL as String

  private var sharedMedia: [SharedMediaFile] = []
  private var sharedText: [String] = []
  private let resultQueue = DispatchQueue(label: "de.mailsmart.cruiseplanner.share-extension")

  override func isContentValid() -> Bool {
    true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    loadIds()
  }

  override func didSelectPost() {
    processAttachments()
  }

  override func configurationItems() -> [Any]! {
    []
  }

  private func loadIds() {
    guard let shareExtensionBundleIdentifier = Bundle.main.bundleIdentifier else {
      return
    }

    if let lastDotIndex = shareExtensionBundleIdentifier.lastIndex(of: ".") {
      hostAppBundleIdentifier = String(shareExtensionBundleIdentifier[..<lastDotIndex])
    } else {
      hostAppBundleIdentifier = shareExtensionBundleIdentifier
    }

    appGroupId =
      (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      ?? "group.\(hostAppBundleIdentifier)"
  }

  private func processAttachments() {
    guard
      let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
      let attachments = extensionItem.attachments,
      !attachments.isEmpty
    else {
      dismissWithError()
      return
    }

    let dispatchGroup = DispatchGroup()
    var handledAttachment = false

    for attachment in attachments {
      if attachment.hasItemConformingToTypeIdentifier(imageContentType) {
        handledAttachment = true
        dispatchGroup.enter()
        handleImage(attachment) { dispatchGroup.leave() }
        continue
      }

      if attachment.hasItemConformingToTypeIdentifier(fileURLType) {
        handledAttachment = true
        dispatchGroup.enter()
        handleFile(attachment) { dispatchGroup.leave() }
        continue
      }

      if attachment.hasItemConformingToTypeIdentifier(urlContentType) {
        handledAttachment = true
        dispatchGroup.enter()
        handleTextLike(attachment, typeIdentifier: urlContentType, asURL: true) { dispatchGroup.leave() }
        continue
      }

      if attachment.hasItemConformingToTypeIdentifier(textContentType) {
        handledAttachment = true
        dispatchGroup.enter()
        handleTextLike(attachment, typeIdentifier: textContentType, asURL: false) { dispatchGroup.leave() }
      }
    }

    guard handledAttachment else {
      dismissWithError()
      return
    }

    dispatchGroup.notify(queue: .main) { [weak self] in
      self?.persistAndRedirect()
    }
  }

  private func handleImage(_ attachment: NSItemProvider, completion: @escaping () -> Void) {
    attachment.loadItem(forTypeIdentifier: imageContentType, options: nil) { [weak self] item, error in
      defer { completion() }
      guard error == nil, let self, let sourceURL = item as? URL else {
        return
      }

      guard let copiedURL = self.copyItemToSharedContainer(from: sourceURL, type: .image) else {
        return
      }

      self.resultQueue.sync {
        self.sharedMedia.append(
          SharedMediaFile(
            path: copiedURL.absoluteString,
            thumbnail: nil,
            duration: nil,
            type: .image
          )
        )
      }
    }
  }

  private func handleFile(_ attachment: NSItemProvider, completion: @escaping () -> Void) {
    attachment.loadItem(forTypeIdentifier: fileURLType, options: nil) { [weak self] item, error in
      defer { completion() }
      guard error == nil, let self, let sourceURL = item as? URL else {
        return
      }

      guard let copiedURL = self.copyItemToSharedContainer(from: sourceURL, type: .file) else {
        return
      }

      self.resultQueue.sync {
        self.sharedMedia.append(
          SharedMediaFile(
            path: copiedURL.absoluteString,
            thumbnail: nil,
            duration: nil,
            type: .file
          )
        )
      }
    }
  }

  private func handleTextLike(
    _ attachment: NSItemProvider,
    typeIdentifier: String,
    asURL: Bool,
    completion: @escaping () -> Void
  ) {
    attachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, error in
      defer { completion() }
      guard error == nil, let self else {
        return
      }

      let value: String?
      if asURL {
        value = (item as? URL)?.absoluteString
      } else {
        value = item as? String
      }

      guard let normalizedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
        !normalizedValue.isEmpty
      else {
        return
      }

      self.resultQueue.sync {
        self.sharedText.append(normalizedValue)
      }
    }
  }

  private func persistAndRedirect() {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
      dismissWithError()
      return
    }

    if !sharedMedia.isEmpty {
      guard let encodedMedia = try? JSONEncoder().encode(sharedMedia) else {
        dismissWithError()
        return
      }

      userDefaults.set(encodedMedia, forKey: sharedKey)
      userDefaults.synchronize()
      redirectToHostApp(type: .media)
      return
    }

    if !sharedText.isEmpty {
      userDefaults.set(sharedText, forKey: sharedKey)
      userDefaults.synchronize()
      redirectToHostApp(type: .text)
      return
    }

    dismissWithError()
  }

  private func redirectToHostApp(type: RedirectType) {
    loadIds()

    guard let url = URL(string: "ShareMedia-\(hostAppBundleIdentifier)://dataUrl=\(sharedKey)#\(type.rawValue)") else {
      dismissWithError()
      return
    }

    var responder: UIResponder? = self
    let selector = sel_registerName("openURL:")

    while let currentResponder = responder {
      if currentResponder.responds(to: selector) {
        _ = currentResponder.perform(selector, with: url)
      }
      responder = currentResponder.next
    }

    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }

  private func dismissWithError() {
    let error = NSError(
      domain: "de.mailsmart.cruiseplanner.share-extension",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Unable to process shared content."]
    )
    extensionContext?.cancelRequest(withError: error)
  }

  private func copyItemToSharedContainer(from sourceURL: URL, type: SharedMediaType) -> URL? {
    guard
      let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupId
      )
    else {
      return nil
    }

    let destinationURL = containerURL.appendingPathComponent(fileName(for: sourceURL, type: type))

    do {
      if FileManager.default.fileExists(atPath: destinationURL.path) {
        try FileManager.default.removeItem(at: destinationURL)
      }
      try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
      return destinationURL
    } catch {
      return nil
    }
  }

  private func fileName(for url: URL, type: SharedMediaType) -> String {
    let lastPathComponent = url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
    if !lastPathComponent.isEmpty {
      return lastPathComponent
    }

    return "\(UUID().uuidString).\(defaultExtension(for: type))"
  }

  private func defaultExtension(for type: SharedMediaType) -> String {
    switch type {
    case .image:
      return "png"
    case .file:
      return "dat"
    }
  }
}

private enum RedirectType: String {
  case media
  case text
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
