import MobileCoreServices
import UIKit

final class ShareViewController: UIViewController {
  private var hostAppBundleIdentifier = ""
  private var appGroupId = ""
  private let sharedKey = "ShareKey"
  private let imageContentType = kUTTypeImage as String
  private let pdfContentType = kUTTypePDF as String
  private let dataContentType = kUTTypeData as String
  private let textContentType = kUTTypeText as String
  private let urlContentType = kUTTypeURL as String
  private let fileURLType = kUTTypeFileURL as String

  private var sharedMedia: [SharedMediaFile] = []
  private var sharedText: [String] = []
  private var hasProcessedShare = false
  private let resultQueue = DispatchQueue(label: "de.mailsmart.cruiseplanner.share-extension")
  private let activityIndicator = UIActivityIndicatorView(style: .large)
  private let titleLabel = UILabel()
  private let detailLabel = UILabel()
  private let debugLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    loadIds()
    configureUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startProcessingShareIfNeeded()
  }

  private func configureUI() {
    view.backgroundColor = .systemBackground

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.hidesWhenStopped = false
    activityIndicator.startAnimating()

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textAlignment = .center
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.text = "Importing..."

    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = .preferredFont(forTextStyle: .subheadline)
    detailLabel.textAlignment = .center
    detailLabel.textColor = .secondaryLabel
    detailLabel.numberOfLines = 0
    detailLabel.text = "Preparing your shared item for Cruise Planner."

    debugLabel.translatesAutoresizingMaskIntoConstraints = false
    debugLabel.font = .preferredFont(forTextStyle: .caption1)
    debugLabel.textAlignment = .center
    debugLabel.textColor = .tertiaryLabel
    debugLabel.numberOfLines = 0
    debugLabel.text = ""

    view.addSubview(activityIndicator)
    view.addSubview(titleLabel)
    view.addSubview(detailLabel)
    view.addSubview(debugLabel)

    NSLayoutConstraint.activate([
      activityIndicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -30),

      titleLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
      titleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      detailLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      detailLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      debugLabel.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 12),
      debugLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      debugLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
  }

  private func updateStatus(title: String, detail: String, debug: String? = nil, isFailure: Bool = false) {
    DispatchQueue.main.async { [weak self] in
      self?.titleLabel.text = title
      self?.detailLabel.text = detail
      if let debug {
        self?.debugLabel.text = debug
      }
      if isFailure {
        self?.activityIndicator.stopAnimating()
      }
    }
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

  private func startProcessingShareIfNeeded() {
    guard !hasProcessedShare else {
      return
    }

    hasProcessedShare = true
    updateStatus(
      title: "Importing...",
      detail: "Preparing your shared item for Cruise Planner."
    )
    processAttachments()
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

      if let fileTypeIdentifier = preferredFileTypeIdentifier(for: attachment) {
        handledAttachment = true
        dispatchGroup.enter()
        handleFile(attachment, typeIdentifier: fileTypeIdentifier) { dispatchGroup.leave() }
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

  private func preferredFileTypeIdentifier(for attachment: NSItemProvider) -> String? {
    if attachment.hasItemConformingToTypeIdentifier(fileURLType) {
      return fileURLType
    }

    if attachment.hasItemConformingToTypeIdentifier(pdfContentType) {
      return pdfContentType
    }

    if attachment.hasItemConformingToTypeIdentifier(dataContentType) {
      return dataContentType
    }

    return nil
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

  private func handleFile(
    _ attachment: NSItemProvider,
    typeIdentifier: String,
    completion: @escaping () -> Void
  ) {
    if typeIdentifier == fileURLType {
      attachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, error in
        defer { completion() }
        guard error == nil, let self else {
          return
        }

        self.persistLoadedFile(from: item, attachment: attachment, typeIdentifier: typeIdentifier)
      }
      return
    }

    attachment.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
      guard error == nil, let self, let sourceURL = url else {
        self?.loadFileAsItem(attachment, typeIdentifier: typeIdentifier, completion: completion)
        return
      }

      defer { completion() }
      guard let copiedURL = self.copyItemToSharedContainer(from: sourceURL, type: .file) else {
        return
      }

      self.persistSharedMediaFile(from: copiedURL)
    }
  }

  private func loadFileAsItem(
    _ attachment: NSItemProvider,
    typeIdentifier: String,
    completion: @escaping () -> Void
  ) {
    attachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, error in
      defer { completion() }
      guard error == nil, let self else {
        return
      }

      self.persistLoadedFile(from: item, attachment: attachment, typeIdentifier: typeIdentifier)
    }
  }

  private func persistLoadedFile(
    from item: NSSecureCoding?,
    attachment: NSItemProvider,
    typeIdentifier: String
  ) {
    let copiedURL: URL?
    if let sourceURL = item as? URL {
      copiedURL = copyItemToSharedContainer(from: sourceURL, type: .file)
    } else if let data = item as? Data {
      copiedURL = copyDataToSharedContainer(
        data,
        suggestedName: attachment.suggestedName,
        typeIdentifier: typeIdentifier
      )
    } else {
      copiedURL = nil
    }

    guard let copiedURL else {
      return
    }

    persistSharedMediaFile(from: copiedURL)
  }

  private func persistSharedMediaFile(from copiedURL: URL) {
    resultQueue.sync {
      sharedMedia.append(
        SharedMediaFile(
          path: copiedURL.absoluteString,
          thumbnail: nil,
          duration: nil,
          type: .file
        )
      )
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
      updateStatus(
        title: "Payload saved",
        detail: "Saved \(sharedMedia.count) shared item(s).",
        debug: "key=\(sharedKey) group=\(appGroupId)"
      )
      redirectToHostApp(type: .media)
      return
    }

    if !sharedText.isEmpty {
      userDefaults.set(sharedText, forKey: sharedKey)
      userDefaults.synchronize()
      updateStatus(
        title: "Payload saved",
        detail: "Saved \(sharedText.count) shared item(s).",
        debug: "key=\(sharedKey) group=\(appGroupId)"
      )
      redirectToHostApp(type: .text)
      return
    }

    dismissWithError()
  }

  private func redirectToHostApp(type: RedirectType) {
    loadIds()
    guard let url = handoffURL(for: type) else {
      dismissWithError()
      return
    }

    let handoffDescription = url.absoluteString
    updateStatus(
      title: "Opening Cruise Planner...",
      detail: "Attempting final handoff to the app.",
      debug: handoffDescription
    )

    extensionContext?.open(url) { [weak self] success in
      guard let self else {
        return
      }

      if success {
        self.updateStatus(
          title: "Open succeeded",
          detail: "Cruise Planner accepted the handoff.",
          debug: handoffDescription
        )
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
      } else {
        self.updateStatus(
          title: "Open failed",
          detail: "The extension could not open Cruise Planner.",
          debug: handoffDescription,
          isFailure: true
        )
      }
    }
  }

  private func dismissWithError(message: String = "Unable to process shared content.") {
    updateStatus(
      title: "Import failed",
      detail: message,
      debug: "key=\(sharedKey) group=\(appGroupId)",
      isFailure: true
    )
    let error = NSError(
      domain: "de.mailsmart.cruiseplanner.share-extension",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: message]
    )
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      self?.extensionContext?.cancelRequest(withError: error)
    }
  }

  private func handoffURL(for type: RedirectType) -> URL? {
    URL(string: "ShareMedia-\(hostAppBundleIdentifier)://dataUrl=\(sharedKey)#\(type.rawValue)")
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

  private func copyDataToSharedContainer(
    _ data: Data,
    suggestedName: String?,
    typeIdentifier: String
  ) -> URL? {
    guard
      let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupId
      )
    else {
      return nil
    }

    let destinationURL = containerURL.appendingPathComponent(
      fileName(forSuggestedName: suggestedName, typeIdentifier: typeIdentifier)
    )

    do {
      if FileManager.default.fileExists(atPath: destinationURL.path) {
        try FileManager.default.removeItem(at: destinationURL)
      }
      try data.write(to: destinationURL, options: .atomic)
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

  private func fileName(forSuggestedName suggestedName: String?, typeIdentifier: String) -> String {
    let normalizedName = suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !normalizedName.isEmpty {
      let fileExtension = URL(fileURLWithPath: normalizedName).pathExtension
      if !fileExtension.isEmpty {
        return normalizedName
      }

      return "\(normalizedName).\(defaultExtension(for: typeIdentifier))"
    }

    return "\(UUID().uuidString).\(defaultExtension(for: typeIdentifier))"
  }

  private func defaultExtension(for type: SharedMediaType) -> String {
    switch type {
    case .image:
      return "png"
    case .file:
      return "dat"
    }
  }

  private func defaultExtension(for typeIdentifier: String) -> String {
    switch typeIdentifier {
    case pdfContentType:
      return "pdf"
    case imageContentType:
      return "png"
    default:
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
