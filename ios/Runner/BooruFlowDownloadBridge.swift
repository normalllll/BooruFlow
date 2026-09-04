import Flutter
import Foundation
import Photos
import UIKit
import CryptoKit
import CFNetwork

final class BooruFlowDownloadBridge: NSObject, FlutterStreamHandler, URLSessionDownloadDelegate {
  static let shared = BooruFlowDownloadBridge()

  private let methodChannelName = "booruflow/download_engine"
  private let eventChannelName = "booruflow/download_engine/events"
  private let queue = DispatchQueue(label: "booruflow.download.bridge")
  private var eventSink: FlutterEventSink?
  private var states: [String: NativeDownloadState] = [:]
  private var tasksByJob: [String: URLSessionDownloadTask] = [:]
  private var sessionsByIdentifier: [String: URLSession] = [:]
  private var backgroundCompletionHandlers: [String: () -> Void] = [:]
  private let sessionIdentifiersKey = "booruflow.download.sessionIdentifiers"
  private let defaultSessionIdentifier = "io.github.normalllll.booruflow.download.background.direct"

  func register(messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }

    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger)
    eventChannel.setStreamHandler(self)
  }

  func handleEventsForBackgroundSession(identifier: String, completionHandler: @escaping () -> Void) {
    queue.async {
      self.backgroundCompletionHandlers[identifier] = completionHandler
      let stored = UserDefaults.standard.dictionary(forKey: self.sessionIdentifiersKey) as? [String: String]
      let proxyUrl = stored?[identifier].flatMap { $0.isEmpty ? nil : $0 }
      _ = self.session(identifier: identifier, proxyUrl: proxyUrl)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    queue.async {
      self.eventSink = events
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    queue.async {
      self.eventSink = nil
    }
    return nil
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      queue.async {
        self.restoreKnownSessions()
        DispatchQueue.main.async { result(nil) }
      }
    case "prepareForDownload":
      prepareForDownload(result: result)
    case "start":
      let args = call.arguments as? [String: Any]
      let jobs = (args?["jobs"] as? [[String: Any]] ?? []).compactMap(NativeDownloadJob.init)
      guard hasPhotosAddAccess() else {
        result(FlutterError(code: "permission_denied", message: "Photos add permission is not granted.", details: nil))
        return
      }
      start(jobs: jobs)
      result(nil)
    case "cancel":
      let args = call.arguments as? [String: Any]
      if let jobId = args?["jobId"] as? String {
        cancel(jobId: jobId)
      }
      result(nil)
    case "sync":
      sync(result: result)
    case "acknowledge":
      let args = call.arguments as? [String: Any]
      let jobIds = args?["jobIds"] as? [String] ?? []
      queue.async {
        for jobId in jobIds {
          guard let state = self.states[jobId] else { continue }
          if state.status == "failed" || state.status == "cancelled" || state.saveState == "saved" || state.saveState == "failed" {
            self.states[jobId] = nil
          }
        }
      }
      result(nil)
    case "saveFile":
      guard
        let args = call.arguments as? [String: Any],
        let jobMap = args["job"] as? [String: Any],
        let job = NativeDownloadJob(jobMap),
        let path = args["path"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "saveFile requires job and path", details: nil))
        return
      }
      let bytesWritten = (args["bytesWritten"] as? NSNumber)?.int64Value ?? 0
      saveToPhotos(job: job, localUrl: URL(fileURLWithPath: path), bytesWritten: bytesWritten) { saveResult in
        DispatchQueue.main.async {
          switch saveResult {
          case .success(let payload):
            result(payload)
          case .failure(let error):
            result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
          }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start(jobs: [NativeDownloadJob]) {
    queue.async {
      for job in jobs {
        if self.tasksByJob[job.id] != nil {
          continue
        }
        guard let url = requestUrl(for: job) else {
          self.states[job.id] = NativeDownloadState(jobId: job.id, status: "failed", saveState: "none", error: "Invalid URL")
          self.emit(["type": "failed", "jobId": job.id, "error": "Invalid URL"])
          continue
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (key, value) in job.networkOptions.headers {
          request.setValue(value, forHTTPHeaderField: key)
        }
        if let hostHeader = job.networkOptions.hostHeader {
          request.setValue(hostHeader, forHTTPHeaderField: "Host")
        }
        request.timeoutInterval = TimeInterval(job.networkOptions.receiveTimeoutSeconds)

        guard let taskDescription = job.encodedTaskDescription() else {
          self.states[job.id] = NativeDownloadState(jobId: job.id, status: "failed", saveState: "none", error: "Could not encode download job")
          self.emit(["type": "failed", "jobId": job.id, "error": "Could not encode download job"])
          continue
        }
        let task = self.session(for: job.networkOptions).downloadTask(with: request)
        task.taskDescription = taskDescription
        self.tasksByJob[job.id] = task
        self.states[job.id] = NativeDownloadState(jobId: job.id, status: "running", saveState: "none", filename: job.filename)
        task.resume()
      }
    }
  }

  private func prepareForDownload(result: @escaping FlutterResult) {
    requestAddOnlyPhotosAccess(openSettingsWhenDenied: true) { outcome in
      DispatchQueue.main.async {
        switch outcome {
        case .granted:
          result(["granted": true])
        case .denied(let message, let openedSettings):
          result(FlutterError(code: openedSettings ? "permission_denied_permanent" : "permission_denied", message: message, details: nil))
        }
      }
    }
  }

  private func cancel(jobId: String) {
    queue.async {
      if let state = self.states[jobId], state.status == "downloaded" || state.saveState == "saving" || state.saveState == "saved" {
        return
      }
      self.tasksByJob[jobId]?.cancel()
      self.tasksByJob[jobId] = nil
      var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "cancelled", saveState: "none")
      state.status = "cancelled"
      state.error = nil
      self.states[jobId] = state
      self.emit(["type": "cancelled", "jobId": jobId])
    }
  }

  private func sync(result: @escaping FlutterResult) {
    queue.async {
      self.restoreKnownSessions()
      let sessions = Array(self.sessionsByIdentifier.values)
      let group = DispatchGroup()
      for session in sessions {
        group.enter()
        session.getAllTasks { tasks in
          self.queue.async {
            for task in tasks {
              guard let job = NativeDownloadJob(task: task) else { continue }
              let jobId = job.id
              self.tasksByJob[jobId] = task as? URLSessionDownloadTask
              var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "running", saveState: "none", filename: job.filename)
              state.status = task.state == .suspended ? "paused" : "running"
              state.receivedBytes = task.countOfBytesReceived
              state.totalBytes = task.countOfBytesExpectedToReceive > 0 ? task.countOfBytesExpectedToReceive : job.validation.expectedBytes
              state.progress = progressOf(received: state.receivedBytes, total: state.totalBytes)
              self.states[jobId] = state
            }
            group.leave()
          }
        }
      }
      group.notify(queue: self.queue) {
        let payload = self.states.values.map { $0.toMap() }
        DispatchQueue.main.async { result(payload) }
      }
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    guard let job = NativeDownloadJob(task: downloadTask) else {
      return
    }
    let jobId = job.id
    queue.async {
      var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "running", saveState: "none")
      state.status = "running"
      state.receivedBytes = totalBytesWritten
      state.totalBytes = job.validation.expectedBytes ?? (totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil)
      state.progress = progressOf(received: totalBytesWritten, total: state.totalBytes)
      self.states[jobId] = state
      self.emit(
        [
          "type": "progress",
          "jobId": jobId,
          "receivedBytes": state.receivedBytes,
          "totalBytes": state.totalBytes as Any,
          "progress": state.progress,
        ]
      )
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let job = NativeDownloadJob(task: downloadTask) else {
      return
    }
    let jobId = job.id

    queue.async {
      var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "downloaded", saveState: "pending")
      let filename = job.filename
      do {
        try validateResponse(downloadTask.response, job: job)
        try validateDownloadedFile(location, validation: job.validation)
        let destination = try self.moveDownloadedFile(location: location, jobId: jobId, filename: filename)
        state.status = "downloaded"
        state.saveState = "saving"
        state.localPath = destination.path
        state.receivedBytes = downloadTask.countOfBytesReceived
        state.totalBytes = job.validation.expectedBytes ?? (downloadTask.countOfBytesExpectedToReceive > 0 ? downloadTask.countOfBytesExpectedToReceive : state.receivedBytes)
        state.progress = 1
        self.states[jobId] = state
        self.emit(["type": "completed", "jobId": jobId, "localPath": destination.path, "bytesWritten": state.receivedBytes])

        self.saveToPhotos(job: job, localUrl: destination, bytesWritten: state.receivedBytes) { saveResult in
          self.queue.async {
            var latest = self.states[jobId] ?? state
            switch saveResult {
            case .success(let payload):
              latest.saveState = "saved"
              latest.galleryAssetId = payload["galleryAssetId"] as? String
              latest.localPath = payload["path"] as? String ?? latest.localPath
              latest.error = nil
              try? FileManager.default.removeItem(at: destination)
              self.emit(["type": "saved", "jobId": jobId, "path": latest.localPath as Any, "galleryAssetId": latest.galleryAssetId as Any])
            case .failure(let error):
              latest.saveState = "failed"
              latest.error = error.localizedDescription
              latest.localPath = destination.path
              self.emit(["type": "saveFailed", "jobId": jobId, "localPath": destination.path, "error": latest.error as Any])
            }
            self.states[jobId] = latest
          }
        }
      } catch {
        state.status = "failed"
        state.saveState = "none"
        state.error = error.localizedDescription
        self.states[jobId] = state
        self.emit(["type": "failed", "jobId": jobId, "error": error.localizedDescription])
      }
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let job = NativeDownloadJob(task: task) else {
      return
    }
    let jobId = job.id
    queue.async {
      self.tasksByJob[jobId] = nil
      guard let error else {
        return
      }

      var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "failed", saveState: "none")
      if (error as NSError).code == NSURLErrorCancelled {
        if state.status == "cancelled" {
          return
        }
        state.status = "cancelled"
        state.error = nil
        self.emit(["type": "cancelled", "jobId": jobId])
      } else {
        state.status = "failed"
        state.error = error.localizedDescription
        self.emit(["type": "failed", "jobId": jobId, "error": error.localizedDescription])
      }
      self.states[jobId] = state
    }
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    queue.async {
      guard let identifier = session.configuration.identifier else { return }
      let handler = self.backgroundCompletionHandlers.removeValue(forKey: identifier)
      DispatchQueue.main.async {
        handler?()
      }
    }
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    guard
      let job = NativeDownloadJob(task: task),
      job.networkOptions.allowInvalidCertificates,
      challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
      let trust = challenge.protectionSpace.serverTrust
    else {
      completionHandler(.performDefaultHandling, nil)
      return
    }
    completionHandler(.useCredential, URLCredential(trust: trust))
  }

  private func restoreKnownSessions() {
    let stored = UserDefaults.standard.dictionary(forKey: sessionIdentifiersKey) as? [String: String] ?? [:]
    if stored.isEmpty {
      _ = session(identifier: defaultSessionIdentifier, proxyUrl: nil)
      return
    }
    for (identifier, proxyUrl) in stored {
      _ = session(identifier: identifier, proxyUrl: proxyUrl.isEmpty ? nil : proxyUrl)
    }
  }

  private func session(for options: NativeNetworkOptions) -> URLSession {
    let proxyUrl = options.proxyUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
    let identifier: String
    if let proxyUrl, !proxyUrl.isEmpty {
      let digest = SHA256.hash(data: Data(proxyUrl.utf8)).prefix(12).map { String(format: "%02x", $0) }.joined()
      identifier = "io.github.normalllll.booruflow.download.background.proxy.\(digest)"
    } else {
      identifier = defaultSessionIdentifier
    }
    return session(identifier: identifier, proxyUrl: proxyUrl)
  }

  private func session(identifier: String, proxyUrl: String?) -> URLSession {
    if let existing = sessionsByIdentifier[identifier] {
      return existing
    }
    let config = URLSessionConfiguration.background(withIdentifier: identifier)
    config.sessionSendsLaunchEvents = true
    config.httpMaximumConnectionsPerHost = 6
    if let proxyUrl, !proxyUrl.isEmpty {
      config.connectionProxyDictionary = proxyDictionary(for: proxyUrl)
    }
    let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    sessionsByIdentifier[identifier] = session
    var stored = UserDefaults.standard.dictionary(forKey: sessionIdentifiersKey) as? [String: String] ?? [:]
    stored[identifier] = proxyUrl ?? ""
    UserDefaults.standard.set(stored, forKey: sessionIdentifiersKey)
    return session
  }

  private func proxyDictionary(for rawUrl: String) -> [AnyHashable: Any] {
    guard let components = URLComponents(string: rawUrl), let host = components.host else {
      return [:]
    }
    let scheme = components.scheme?.lowercased() ?? "http"
    let port = components.port ?? (scheme.hasPrefix("socks") ? 1080 : 8080)
    if scheme.hasPrefix("socks") {
      return [
        kCFNetworkProxiesSOCKSEnable as String: true,
        kCFNetworkProxiesSOCKSProxy as String: host,
        kCFNetworkProxiesSOCKSPort as String: port,
      ]
    }
    return [
      kCFNetworkProxiesHTTPEnable as String: true,
      kCFNetworkProxiesHTTPProxy as String: host,
      kCFNetworkProxiesHTTPPort as String: port,
      kCFNetworkProxiesHTTPSEnable as String: true,
      kCFNetworkProxiesHTTPSProxy as String: host,
      kCFNetworkProxiesHTTPSPort as String: port,
    ]
  }

  private func requestUrl(for job: NativeDownloadJob) -> URL? {
    // URLSession does not expose a safe per-request DNS resolver for
    // background tasks. Preserve the original URL so TLS SNI remains valid;
    // the original Host header is still applied to the request above.
    return URL(string: job.url)
  }

  private func moveDownloadedFile(location: URL, jobId: String, filename: String) throws -> URL {
    let directory = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("booruflow_downloads", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let destination = directory.appendingPathComponent("\(jobId)-\(safeFilename(filename))")
    if FileManager.default.fileExists(atPath: destination.path) {
      try FileManager.default.removeItem(at: destination)
    }
    try FileManager.default.moveItem(at: location, to: destination)
    return destination
  }

  private func saveToPhotos(job: NativeDownloadJob, localUrl: URL, bytesWritten: Int64, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    guard hasPhotosAddAccess() else {
      completion(.failure(NSError(domain: "booruflow.download", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photos add permission is not granted."])))
      return
    }

    do {
      try validateDownloadedFile(localUrl, validation: job.validation)
    } catch {
      completion(.failure(error))
      return
    }

    var localIdentifier: String?
    PHPhotoLibrary.shared().performChanges {
      let options = PHAssetResourceCreationOptions()
      options.originalFilename = safeFilename(job.filename)
      let request = PHAssetCreationRequest.forAsset()
      request.addResource(with: .photo, fileURL: localUrl, options: options)
      localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
    } completionHandler: { success, error in
      if let error {
        completion(.failure(error))
        return
      }
      if !success {
        completion(.failure(NSError(domain: "booruflow.download", code: 2, userInfo: [NSLocalizedDescriptionKey: "Photos save failed."])))
        return
      }
      let savedPath = localIdentifier.map { "ph://\($0)" } ?? localUrl.path
      completion(.success(compactPayload(["path": savedPath, "galleryAssetId": localIdentifier, "bytesWritten": bytesWritten])))
    }
  }

  private func hasPhotosAddAccess() -> Bool {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      switch status {
      case .authorized, .limited:
        return true
      default:
        return false
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .authorized:
        return true
      default:
        return false
      }
    }
  }

  private func requestAddOnlyPhotosAccess(openSettingsWhenDenied: Bool, completion: @escaping (PhotoPermissionOutcome) -> Void) {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      switch status {
      case .authorized, .limited:
        completion(.granted)
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
          self.resolvePhotoAuthorizationStatus(newStatus, openSettingsWhenDenied: openSettingsWhenDenied, completion: completion)
        }
      default:
        resolvePhotoAuthorizationStatus(status, openSettingsWhenDenied: openSettingsWhenDenied, completion: completion)
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .authorized:
        completion(.granted)
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization { newStatus in
          self.resolvePhotoAuthorizationStatus(newStatus, openSettingsWhenDenied: openSettingsWhenDenied, completion: completion)
        }
      default:
        resolvePhotoAuthorizationStatus(status, openSettingsWhenDenied: openSettingsWhenDenied, completion: completion)
      }
    }
  }

  private func resolvePhotoAuthorizationStatus(_ status: PHAuthorizationStatus, openSettingsWhenDenied: Bool, completion: @escaping (PhotoPermissionOutcome) -> Void) {
    if #available(iOS 14, *), status == .limited {
      completion(.granted)
      return
    }

    switch status {
    case .authorized:
      completion(.granted)
    case .denied, .restricted:
      let message = "Photos add permission was denied."
      guard openSettingsWhenDenied else {
        completion(.denied(message: message, openedSettings: false))
        return
      }
      openAppSettings { opened in
        completion(.denied(message: opened ? "\(message) App settings were opened." : message, openedSettings: opened))
      }
    case .notDetermined:
      completion(.denied(message: "Photos add permission has not been requested.", openedSettings: false))
    @unknown default:
      completion(.denied(message: "Photos add permission status is unknown.", openedSettings: false))
    }
  }

  private func openAppSettings(completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.async {
      guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) else {
        completion(false)
        return
      }
      UIApplication.shared.open(settingsUrl, options: [:]) { opened in
        completion(opened)
      }
    }
  }

  private func emit(_ event: [String: Any?]) {
    guard let eventSink else {
      return
    }
    let payload = compactPayload(event)
    DispatchQueue.main.async {
      eventSink(payload)
    }
  }
}

private struct NativeDownloadJob {
  let id: String
  let url: String
  let filename: String
  let networkOptions: NativeNetworkOptions
  let validation: NativeValidationOptions

  init?(_ map: [String: Any]) {
    guard let id = map["id"] as? String, let url = map["url"] as? String,
      let networkOptions = map["networkOptions"] as? [String: Any],
      let validation = map["validation"] as? [String: Any] else {
      return nil
    }
    self.id = id
    self.url = url
    self.filename = map["filename"] as? String ?? "download"
    self.networkOptions = NativeNetworkOptions(networkOptions)
    self.validation = NativeValidationOptions(validation)
  }

  init?(taskDescription: String?) {
    guard
      let taskDescription,
      let data = taskDescription.data(using: .utf8),
      let map = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return nil
    }
    self.init(map)
  }

  init?(task: URLSessionTask) {
    self.init(taskDescription: task.taskDescription)
  }

  func encodedTaskDescription() -> String? {
    let payload: [String: Any] = [
      "id": id,
      "url": url,
      "filename": filename,
      "networkOptions": networkOptions.toMap(),
      "validation": validation.toMap(),
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
    return String(data: data, encoding: .utf8)
  }
}

private struct NativeNetworkOptions {
  let headers: [String: String]
  let proxyUrl: String?
  let connectHost: String?
  let hostHeader: String?
  let disableTlsSni: Bool
  let allowInvalidCertificates: Bool
  let connectTimeoutSeconds: Int
  let receiveTimeoutSeconds: Int

  init(_ map: [String: Any]) {
    self.headers = map["headers"] as? [String: String] ?? [:]
    self.proxyUrl = nonEmptyString(map["proxyUrl"])
    self.connectHost = nonEmptyString(map["connectHost"])
    self.hostHeader = nonEmptyString(map["hostHeader"])
    self.disableTlsSni = map["disableTlsSni"] as? Bool ?? false
    self.allowInvalidCertificates = map["allowInvalidCertificates"] as? Bool ?? false
    self.connectTimeoutSeconds = max((map["connectTimeoutSeconds"] as? NSNumber)?.intValue ?? 30, 1)
    self.receiveTimeoutSeconds = max((map["receiveTimeoutSeconds"] as? NSNumber)?.intValue ?? 120, 1)
  }

  func toMap() -> [String: Any] {
    compactPayload([
      "headers": headers,
      "proxyUrl": proxyUrl,
      "connectHost": connectHost,
      "hostHeader": hostHeader,
      "disableTlsSni": disableTlsSni,
      "allowInvalidCertificates": allowInvalidCertificates,
      "connectTimeoutSeconds": connectTimeoutSeconds,
      "receiveTimeoutSeconds": receiveTimeoutSeconds,
    ])
  }
}

private struct NativeChecksum {
  let algorithm: String
  let value: String

  init?(_ map: [String: Any]) {
    guard let algorithm = nonEmptyString(map["algorithm"]), let value = nonEmptyString(map["value"]) else { return nil }
    self.algorithm = algorithm.lowercased()
    self.value = value.lowercased()
  }

  func toMap() -> [String: Any] { ["algorithm": algorithm, "value": value] }
}

private struct NativeValidationOptions {
  let expectedBytes: Int64?
  let allowedContentTypes: [String]
  let checksum: NativeChecksum?

  init(_ map: [String: Any]) {
    let bytes = (map["expectedBytes"] as? NSNumber)?.int64Value
    self.expectedBytes = bytes.flatMap { $0 > 0 ? $0 : nil }
    self.allowedContentTypes = (map["allowedContentTypes"] as? [Any] ?? []).map { String(describing: $0).lowercased() }
    self.checksum = (map["checksum"] as? [String: Any]).flatMap(NativeChecksum.init)
  }

  func toMap() -> [String: Any] {
    compactPayload([
      "expectedBytes": expectedBytes,
      "allowedContentTypes": allowedContentTypes,
      "checksum": checksum?.toMap(),
    ])
  }
}

private struct NativeDownloadState {
  let jobId: String
  var status: String
  var saveState: String
  var filename: String?
  var receivedBytes: Int64 = 0
  var totalBytes: Int64?
  var progress: Double = 0
  var localPath: String?
  var galleryAssetId: String?
  var error: String?

  func toMap() -> [String: Any] {
    compactPayload([
      "jobId": jobId,
      "status": status,
      "saveState": saveState,
      "receivedBytes": receivedBytes,
      "totalBytes": totalBytes,
      "progress": progress,
      "localPath": localPath,
      "galleryAssetId": galleryAssetId,
      "error": error,
    ])
  }
}

private enum PhotoPermissionOutcome {
  case granted
  case denied(message: String, openedSettings: Bool)
}

private func progressOf(received: Int64, total: Int64?) -> Double {
  guard let total, total > 0 else {
    return 0
  }
  return min(max(Double(received) / Double(total), 0), 1)
}

private func safeFilename(_ filename: String) -> String {
  let invalid = CharacterSet(charactersIn: "/\\\0")
  let sanitized = filename.components(separatedBy: invalid).joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)
  return sanitized.isEmpty ? "download" : sanitized
}

private func validateReadableFile(_ url: URL) throws {
  guard url.isFileURL else {
    throw NSError(domain: "booruflow.download", code: 3, userInfo: [NSLocalizedDescriptionKey: "Downloaded file URL is invalid."])
  }
  let path = url.path
  guard FileManager.default.fileExists(atPath: path) else {
    throw NSError(domain: "booruflow.download", code: 4, userInfo: [NSLocalizedDescriptionKey: "Downloaded file does not exist: \(path)"])
  }
  let attributes = try FileManager.default.attributesOfItem(atPath: path)
  let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
  guard size > 0 else {
    throw NSError(domain: "booruflow.download", code: 5, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is empty: \(path)"])
  }
}

private func validateResponse(_ response: URLResponse?, job: NativeDownloadJob) throws {
  guard let response = response as? HTTPURLResponse else {
    throw downloadError(6, "Download response is not HTTP.")
  }
  guard (200...299).contains(response.statusCode) else {
    throw downloadError(7, "Download failed with HTTP \(response.statusCode).")
  }
  let allowed = job.validation.allowedContentTypes
  if !allowed.isEmpty {
    guard let actual = response.mimeType?.lowercased() else {
      throw downloadError(8, "Download response has no valid Content-Type.")
    }
    let matches = allowed.contains { candidate in
      let normalized = candidate.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      return normalized.hasSuffix("/*") ? actual.hasPrefix(String(normalized.dropLast())) : actual == normalized
    }
    if !matches {
      throw downloadError(9, "Unexpected download Content-Type: \(actual).")
    }
  }
  if let expected = job.validation.expectedBytes, response.expectedContentLength > 0, response.expectedContentLength != expected {
    throw downloadError(10, "Response byte count mismatch: expected \(expected), got \(response.expectedContentLength).")
  }
}

private func validateDownloadedFile(_ url: URL, validation: NativeValidationOptions) throws {
  try validateReadableFile(url)
  let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
  let actualBytes = (attributes[.size] as? NSNumber)?.int64Value ?? 0
  if let expected = validation.expectedBytes, actualBytes != expected {
    throw downloadError(11, "Downloaded byte count mismatch: expected \(expected), got \(actualBytes).")
  }
  guard let checksum = validation.checksum else { return }
  let data = try Data(contentsOf: url, options: .mappedIfSafe)
  let actual: String
  switch checksum.algorithm {
  case "md5":
    actual = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
  case "sha256":
    actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  default:
    throw downloadError(12, "Unsupported checksum algorithm: \(checksum.algorithm).")
  }
  if actual.caseInsensitiveCompare(checksum.value) != .orderedSame {
    throw downloadError(13, "Downloaded \(checksum.algorithm) checksum mismatch: expected \(checksum.value), got \(actual).")
  }
}

private func nonEmptyString(_ value: Any?) -> String? {
  guard let text = value as? String else { return nil }
  let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
  return trimmed.isEmpty ? nil : trimmed
}

private func downloadError(_ code: Int, _ message: String) -> NSError {
  NSError(domain: "booruflow.download", code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

private func compactPayload(_ payload: [String: Any?]) -> [String: Any] {
  var result: [String: Any] = [:]
  for (key, value) in payload {
    if let value {
      result[key] = value
    }
  }
  return result
}
