import Foundation

final class DownloadTask: NSObject, @unchecked Sendable, URLSessionDownloadDelegate {
    let id: String
    let url: URL
    let app: AppEntry
    let item: AppcastItem

    private var session: URLSession!
    private let progressContinuation: AsyncStream<Double>.Continuation
    let progressStream: AsyncStream<Double>

    private let completionContinuation: CheckedContinuation<URL, Error>?
    private var downloadTask: URLSessionDownloadTask?
    private var isCancelled = false

    private let lock = NSLock()

    init(
        url: URL,
        app: AppEntry,
        item: AppcastItem,
        completion: CheckedContinuation<URL, Error>
    ) {
        self.id = "\(app.id)-\(item.bundleVersion)"
        self.url = url
        self.app = app
        self.item = item
        self.completionContinuation = completion

        var continuation: AsyncStream<Double>.Continuation!
        self.progressStream = AsyncStream { cont in
            continuation = cont
        }
        self.progressContinuation = continuation

        super.init()

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func start() {
        lock.lock()
        defer { lock.unlock() }

        guard !isCancelled else {
            completionContinuation?.resume(throwing: SparklyError.downloadCancelled)
            return
        }

        let task = session.downloadTask(with: url)
        self.downloadTask = task
        task.resume()
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let task = downloadTask
        lock.unlock()

        task?.cancel()
        progressContinuation.finish()
    }

    // MARK: - URLSessionDownloadDelegate

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        do {
            let tempDirectory = FileManager.default.temporaryDirectory
            let destinationURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".zip")

            try FileManager.default.copyItem(at: location, to: destinationURL)

            progressContinuation.yield(1.0)
            progressContinuation.finish()
            completionContinuation?.resume(returning: destinationURL)
        } catch {
            progressContinuation.finish()
            completionContinuation?.resume(throwing: SparklyError.downloadFailed(url, underlying: error))
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressContinuation.yield(progress)
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            progressContinuation.finish()

            if (error as NSError).code == NSURLErrorCancelled {
                completionContinuation?.resume(throwing: SparklyError.downloadCancelled)
            } else {
                completionContinuation?.resume(throwing: SparklyError.downloadFailed(url, underlying: error))
            }
        }
    }
}
