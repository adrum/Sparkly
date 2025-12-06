import Foundation
import Observation

@Observable
final class DownloadsViewModel {
    private let downloadManager: DownloadManager

    var downloads: [DownloadInfo] {
        downloadManager.downloads
    }

    var activeDownloads: [DownloadInfo] {
        downloads.filter { download in
            switch download.state {
            case .pending, .downloading, .extracting:
                return true
            default:
                return false
            }
        }
    }

    var hasActiveDownloads: Bool {
        !activeDownloads.isEmpty
    }

    var completedDownloads: [DownloadInfo] {
        downloads.filter { download in
            if case .completed = download.state {
                return true
            }
            return false
        }
    }

    var failedDownloads: [DownloadInfo] {
        downloads.filter { download in
            if case .failed = download.state {
                return true
            }
            return false
        }
    }

    init(downloadManager: DownloadManager) {
        self.downloadManager = downloadManager
    }

    func cancel(_ download: DownloadInfo) {
        downloadManager.cancel(app: download.app, item: download.item)
    }

    func clearCompleted() {
        downloadManager.clearCompleted()
    }
}
