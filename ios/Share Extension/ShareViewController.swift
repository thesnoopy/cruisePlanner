import MobileCoreServices
import UIKit

final class ShareViewController: UIViewController {
  private var appGroupId = ""
  private let sharedKey = "ShareKey"
  private let sharedTypeKey = "ShareTypeKey"
  private let sharedQueueKey = "ShareQueueKey"
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

    appGroupId =
      (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      ?? "group.\(shareExtensionBundleIdentifier)"
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
      let extensionItems = extensionContext?.inputItems as? [NSExtensionItem]
    else {
      dismissWithError()
      return
    }

    let attachments = extensionItems
      .compactMap(\.attachments)
      .flatMap { $0 }

    guard
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
        handleFile(attachment, typeIdentifier: fileURLType) { dispatchGroup.leave() }
        continue
      }

      if attachment.hasItemConformingToTypeIdentifier(pdfContentType) {
        handledAttachment = true
        dispatchGroup.enter()
        handleFile(attachment, typeIdentifier: pdfContentType) { dispatchGroup.leave() }
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
        continue
      }

      if attachment.hasItemConformingToTypeIdentifier(dataContentType) {
        handledAttachment = true
        dispatchGroup.enter()
        handleFile(attachment, typeIdentifier: dataContentType) { dispatchGroup.leave() }
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
    let typeIdentifier = preferredImageTypeIdentifier(for: attachment)

    attachment.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
      guard error == nil, let self, let sourceURL = url else {
        self?.loadImageAsItem(
          attachment,
          typeIdentifier: typeIdentifier,
          completion: completion
        )
        return
      }

      defer { completion() }
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

  private func loadImageAsItem(
    _ attachment: NSItemProvider,
    typeIdentifier: String,
    completion: @escaping () -> Void
  ) {
    attachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, error in
      defer { completion() }
      guard error == nil, let self else {
        return
      }

      self.persistLoadedImage(from: item, attachment: attachment, typeIdentifier: typeIdentifier)
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

  private func persistLoadedImage(
    from item: NSSecureCoding?,
    attachment: NSItemProvider,
    typeIdentifier: String
  ) {
    let copiedURL: URL?
    if let sourceURL = item as? URL {
      copiedURL = copyItemToSharedContainer(from: sourceURL, type: .image)
    } else if let data = item as? Data {
      copiedURL = copyDataToSharedContainer(
        data,
        suggestedName: attachment.suggestedName,
        typeIdentifier: typeIdentifier
      )
    } else if let image = item as? UIImage {
      copiedURL = copyImageToSharedContainer(
        image,
        suggestedName: attachment.suggestedName,
        typeIdentifier: typeIdentifier
      )
    } else {
      copiedURL = nil
    }

    guard let copiedURL else {
      return
    }

    resultQueue.sync {
      sharedMedia.append(
        SharedMediaFile(
          path: copiedURL.absoluteString,
          thumbnail: nil,
          duration: nil,
          type: .image
        )
      )
    }
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
        value = self.extractURLString(from: item)
      } else {
        value = self.extractTextString(from: item)
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
      let batch = PersistedShareBatch.media(sharedMedia)
      guard appendPersistedBatch(batch, to: userDefaults) else {
        dismissWithError()
        return
      }

      updateStatus(
        title: "Imported",
        detail: "Open Cruise Planner to continue.",
        debug: "queued \(sharedMedia.count) item(s) in \(appGroupId)"
      )
      finishAfterSuccess()
      return
    }

    if !sharedText.isEmpty {
      let batch = PersistedShareBatch.text(sharedText)
      guard appendPersistedBatch(batch, to: userDefaults) else {
        dismissWithError()
        return
      }

      updateStatus(
        title: "Imported",
        detail: "Open Cruise Planner to continue.",
        debug: "queued \(sharedText.count) item(s) in \(appGroupId)"
      )
      finishAfterSuccess()
      return
    }

    dismissWithError()
  }

  private func finishAfterSuccess() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
      self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
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

  private func copyImageToSharedContainer(
    _ image: UIImage,
    suggestedName: String?,
    typeIdentifier: String
  ) -> URL? {
    guard
      let imageData = encodedImageData(from: image, typeIdentifier: typeIdentifier)
    else {
      return nil
    }

    return copyDataToSharedContainer(
      imageData,
      suggestedName: suggestedName,
      typeIdentifier: typeIdentifier
    )
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
    if typeIdentifier == pdfContentType {
      return "pdf"
    }

    if let preferredExtension = preferredFileExtension(for: typeIdentifier) {
      return preferredExtension
    }

    switch typeIdentifier {
    case imageContentType:
      return "png"
    default:
      return "dat"
    }
  }

  private func preferredImageTypeIdentifier(for attachment: NSItemProvider) -> String {
    for identifier in attachment.registeredTypeIdentifiers {
      if UTTypeConformsTo(identifier as CFString, imageContentType as CFString) {
        return identifier
      }
    }

    return imageContentType
  }

  private func preferredFileExtension(for typeIdentifier: String) -> String? {
    guard
      let unmanagedExtension = UTTypeCopyPreferredTagWithClass(
        typeIdentifier as CFString,
        kUTTagClassFilenameExtension
      )
    else {
      return nil
    }

    let fileExtension = unmanagedExtension.takeRetainedValue() as String
    let normalizedExtension = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    return normalizedExtension.isEmpty ? nil : normalizedExtension
  }

  private func encodedImageData(from image: UIImage, typeIdentifier: String) -> Data? {
    if typeIdentifier == "public.jpeg" || typeIdentifier == "public.jpg" {
      return image.jpegData(compressionQuality: 1.0)
    }

    return image.pngData() ?? image.jpegData(compressionQuality: 1.0)
  }

  private func extractURLString(from item: NSSecureCoding?) -> String? {
    if let url = item as? URL {
      return url.absoluteString
    }

    if let text = extractTextString(from: item), looksLikeWebURL(text) {
      return text
    }

    return nil
  }

  private func extractTextString(from item: NSSecureCoding?) -> String? {
    if let text = item as? String {
      return text
    }

    if let attributedText = item as? NSAttributedString {
      return attributedText.string
    }

    if let url = item as? URL {
      return url.absoluteString
    }

    return nil
  }

  private func looksLikeWebURL(_ value: String) -> Bool {
    guard let url = URL(string: value), let scheme = url.scheme?.lowercased() else {
      return false
    }

    return scheme == "http" || scheme == "https"
  }

  private func appendPersistedBatch(
    _ batch: PersistedShareBatch,
    to userDefaults: UserDefaults
  ) -> Bool {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    let existingQueue: [PersistedShareBatch]
    if let queueData = userDefaults.data(forKey: sharedQueueKey) {
      existingQueue = (try? decoder.decode([PersistedShareBatch].self, from: queueData)) ?? []
    } else {
      existingQueue = []
    }

    guard let encodedQueue = try? encoder.encode(existingQueue + [batch]) else {
      return false
    }

    userDefaults.set(encodedQueue, forKey: sharedQueueKey)
    userDefaults.removeObject(forKey: sharedKey)
    userDefaults.removeObject(forKey: sharedTypeKey)
    userDefaults.synchronize()
    return true
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
    case RedirectType.media.rawValue:
      self = .media(try container.decode([SharedMediaFile].self, forKey: .media))
    case RedirectType.text.rawValue:
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
      try container.encode(RedirectType.media.rawValue, forKey: .type)
      try container.encode(items, forKey: .media)
    case let .text(items):
      try container.encode(RedirectType.text.rawValue, forKey: .type)
      try container.encode(items, forKey: .text)
    }
  }
}
