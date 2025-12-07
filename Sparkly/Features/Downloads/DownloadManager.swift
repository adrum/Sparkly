import Foundation
import Observation

enum DownloadState: Sendable, Equatable {
    case pending
    case downloading(progress: Double)
    case extracting
    case completed(URL)
    case failed(String)
    case cancelled

    static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending),
             (.extracting, .extracting),
             (.cancelled, .cancelled):
            return true
        case (.downloading(let p1), .downloading(let p2)):
            return p1 == p2
        case (.completed(let u1), .completed(let u2)):
            return u1 == u2
        case (.failed(let e1), .failed(let e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

struct DownloadInfo: Identifiable, Sendable {
    let id: String
    let app: AppEntry
    let item: AppcastItem
    var state: DownloadState
    var progress: Double

    init(app: AppEntry, item: AppcastItem) {
        self.id = "\(app.id)-\(item.bundleVersion)"
        self.app = app
        self.item = item
        self.state = .pending
        self.progress = 0
    }
}

@Observable
final class DownloadManager: @unchecked Sendable {
    private(set) var downloads: [DownloadInfo] = []

    private var activeTasks: [String: DownloadTask] = [:]
    private let cache: BuildCache
    private let lock = NSLock()

    init(cache: BuildCache = BuildCache()) {
        self.cache = cache
    }

    func download(_ item: AppcastItem, for app: AppEntry) async throws -> URL {
        if let cached = await cache.cachedPath(for: item, app: app) {
            return cached
        }

        let taskID = "\(app.id)-\(item.bundleVersion)"

        lock.lock()
        if activeTasks[taskID] != nil {
            lock.unlock()
            throw SparklyError.downloadFailed(item.enclosureURL, underlying: NSError(
                domain: "Sparkly",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Download already in progress"]
            ))
        }

        var info = DownloadInfo(app: app, item: item)
        info.state = .pending
        downloads.append(info)
        lock.unlock()

        defer {
            lock.lock()
            activeTasks.removeValue(forKey: taskID)
            lock.unlock()
        }

        do {
            let tempURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let task = DownloadTask(
                    url: item.enclosureURL,
                    app: app,
                    item: item,
                    completion: continuation
                )

                lock.lock()
                activeTasks[taskID] = task
                lock.unlock()

                Task {
                    for await progress in task.progressStream {
                        await MainActor.run {
                            self.updateDownloadState(taskID: taskID, state: .downloading(progress: progress), progress: progress)
                        }
                    }
                }

                task.start()
            }

            await MainActor.run {
                self.updateDownloadState(taskID: taskID, state: .extracting, progress: 1.0)
            }

            let cachedURL = try await cache.store(tempURL, for: item, app: app)

            try? FileManager.default.removeItem(at: tempURL)

            await MainActor.run {
                self.updateDownloadState(taskID: taskID, state: .completed(cachedURL), progress: 1.0)
            }

            return cachedURL

        } catch let error as SparklyError {
            await MainActor.run {
                if case .downloadCancelled = error {
                    self.updateDownloadState(taskID: taskID, state: .cancelled, progress: 0)
                } else {
                    self.updateDownloadState(taskID: taskID, state: .failed(error.localizedDescription), progress: 0)
                }
            }
            throw error
        } catch {
            await MainActor.run {
                self.updateDownloadState(taskID: taskID, state: .failed(error.localizedDescription), progress: 0)
            }
            throw SparklyError.downloadFailed(item.enclosureURL, underlying: error)
        }
    }

    func cancel(app: AppEntry, item: AppcastItem) {
        let taskID = "\(app.id)-\(item.bundleVersion)"

        lock.lock()
        let task = activeTasks[taskID]
        lock.unlock()

        task?.cancel()
    }

    func clearCompleted() {
        lock.lock()
        downloads.removeAll { download in
            switch download.state {
            case .completed, .failed, .cancelled:
                return true
            default:
                return false
            }
        }
        lock.unlock()
    }

    func isDownloading(_ item: AppcastItem, for app: AppEntry) -> Bool {
        let taskID = "\(app.id)-\(item.bundleVersion)"
        lock.lock()
        let exists = activeTasks[taskID] != nil
        lock.unlock()
        return exists
    }

    func downloadInfo(for item: AppcastItem, app: AppEntry) -> DownloadInfo? {
        let taskID = "\(app.id)-\(item.bundleVersion)"
        return downloads.first { $0.id == taskID }
    }

    private func updateDownloadState(taskID: String, state: DownloadState, progress: Double) {
        if let index = downloads.firstIndex(where: { $0.id == taskID }) {
            downloads[index].state = state
            downloads[index].progress = progress
        }
    }
}
