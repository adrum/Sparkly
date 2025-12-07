//
//  SparklyApp.swift
//  Sparkly
//
//  Created by Austin Drummond on 12/6/25.
//

import SwiftUI
import Sparkle

@main
struct SparklyApp: App {
    @State private var indexService = AppIndexService()
    @State private var simctlService = SimctlService()
    @State private var cache = BuildCache()
    @State private var downloadManager: DownloadManager
    @State private var settingsViewModel = SettingsViewModel()

    @State private var buildListViewModel: BuildListViewModel
    @State private var deviceListViewModel: DeviceListViewModel
    @State private var downloadsViewModel: DownloadsViewModel

    @StateObject private var updaterController = UpdaterController()

    init() {
        let cache = BuildCache()
        let indexService = AppIndexService()
        let simctlService = SimctlService()
        let downloadManager = DownloadManager(cache: cache)

        _cache = State(initialValue: cache)
        _indexService = State(initialValue: indexService)
        _simctlService = State(initialValue: simctlService)
        _downloadManager = State(initialValue: downloadManager)

        _buildListViewModel = State(initialValue: BuildListViewModel(
            indexService: indexService,
            downloadManager: downloadManager,
            cache: cache,
            simctlService: simctlService
        ))

        _deviceListViewModel = State(initialValue: DeviceListViewModel(
            simctlService: simctlService
        ))

        _downloadsViewModel = State(initialValue: DownloadsViewModel(
            downloadManager: downloadManager
        ))
    }

    var body: some Scene {
        WindowGroup {
            MainView(
                buildListViewModel: buildListViewModel,
                deviceListViewModel: deviceListViewModel,
                downloadsViewModel: downloadsViewModel,
                settingsViewModel: settingsViewModel,
                indexService: indexService,
                cache: cache,
                downloadManager: downloadManager
            )
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updaterController: updaterController)
            }

            AppCommands {
                await buildListViewModel.refresh()
                await deviceListViewModel.refresh()
            }
        }
        .defaultSize(width: 1000, height: 700)

        Settings {
            SettingsView()
        }
    }
}
