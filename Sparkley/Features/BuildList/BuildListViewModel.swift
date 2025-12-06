import Foundation
import Observation

@Observable
final class BuildListViewModel: @unchecked Sendable {
    private(set) var apps: [AppWithBuilds] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var selectedApp: AppEntry?
    var selectedBuild: AppcastItem?
    var searchText: String = ""
    var platformFilter: Platform?

    private let indexService: AppIndexService
    let downloadManager: DownloadManager
    private let cache: BuildCache
    private let simctlService: SimctlService
    private let adbService: ADBService
    private let simulatorInstaller: SimulatorInstaller
    private let emulatorInstaller: EmulatorInstaller

    var filteredApps: [AppWithBuilds] {
        var result = apps

        if let filter = platformFilter {
            result = result.filter { $0.app.platform == filter }
        }

        if !searchText.isEmpty {
            result = result.filter { appWithBuilds in
                appWithBuilds.app.name.localizedCaseInsensitiveContains(searchText) ||
                appWithBuilds.app.id.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var selectedAppBuilds: [AppcastItem] {
        guard let selectedApp else { return [] }
        return apps.first { $0.app.id == selectedApp.id }?.sortedBuilds ?? []
    }

    init(
        indexService: AppIndexService,
        downloadManager: DownloadManager,
        cache: BuildCache,
        simctlService: SimctlService,
        adbService: ADBService = ADBService()
    ) {
        self.indexService = indexService
        self.downloadManager = downloadManager
        self.cache = cache
        self.simctlService = simctlService
        self.adbService = adbService
        self.simulatorInstaller = SimulatorInstaller(simctlService: simctlService)
        self.emulatorInstaller = EmulatorInstaller(adbService: adbService)
    }

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let index = try await indexService.fetchIndex()
            let appsWithBuilds = try await indexService.fetchAllAppcasts(for: index)
            apps = appsWithBuilds
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func install(
        _ item: AppcastItem,
        for app: AppEntry,
        on device: AnyDevice
    ) async throws {
        let archivePath = try await downloadManager.download(item, for: app)

        switch device {
        case .simulator(let simulator):
            guard app.platform == .ios else {
                throw SparkleyError.platformMismatch(expected: .ios, got: app.platform)
            }
            try await simulatorInstaller.install(archivePath: archivePath, app: app, device: simulator)

        case .emulator(let emulator):
            guard app.platform == .android else {
                throw SparkleyError.platformMismatch(expected: .android, got: app.platform)
            }
            try await emulatorInstaller.install(archivePath: archivePath, app: app, device: emulator)
        }
    }

    func isCached(_ item: AppcastItem, for app: AppEntry) async -> Bool {
        await cache.cachedPath(for: item, app: app) != nil
    }

    func isDownloading(_ item: AppcastItem, for app: AppEntry) -> Bool {
        downloadManager.isDownloading(item, for: app)
    }

    func downloadProgress(for item: AppcastItem, app: AppEntry) -> Double? {
        downloadManager.downloadInfo(for: item, app: app)?.progress
    }

    func cancelDownload(_ item: AppcastItem, for app: AppEntry) {
        downloadManager.cancel(app: app, item: item)
    }

    func selectFirstApp() {
        selectedApp = filteredApps.first?.app
    }
}
