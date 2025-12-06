import SwiftUI

struct MainView: View {
    @State var buildListViewModel: BuildListViewModel
    @State var deviceListViewModel: DeviceListViewModel
    @State var downloadsViewModel: DownloadsViewModel
    @State var settingsViewModel: SettingsViewModel

    let indexService: AppIndexService
    let cache: BuildCache
    let downloadManager: DownloadManager

    @State private var showDownloads = false
    @State private var sidebarSelection: SidebarSelection?

    var body: some View {
        NavigationSplitView {
            SidebarView(
                buildListViewModel: buildListViewModel,
                deviceListViewModel: deviceListViewModel,
                selection: $sidebarSelection
            )
        } detail: {
            VStack(spacing: 0) {
                detailContent

                if showDownloads || downloadsViewModel.hasActiveDownloads {
                    Divider()

                    DownloadsView(viewModel: downloadsViewModel)
                }
            }
        }
        .navigationTitle("Sparkley")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarItems
            }
        }
        .task {
            await configureAndLoad()
        }
        .onChange(of: settingsViewModel.indexSources) { _, _ in
            Task {
                await configureAndLoad()
            }
        }
        .onChange(of: sidebarSelection) { _, newSelection in
            // Sync selection state to view models
            if let selection = newSelection {
                switch selection {
                case .device(let anyDevice):
                    deviceListViewModel.selectedDevice = anyDevice
                    buildListViewModel.selectedApp = nil
                case .app(let app):
                    buildListViewModel.selectedApp = app
                    // Keep device selected for installation target, but clear from "viewing" perspective
                }
            } else {
                buildListViewModel.selectedApp = nil
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch sidebarSelection {
        case .device(let anyDevice):
            switch anyDevice {
            case .simulator(let device):
                SimulatorDetailView(
                    device: device,
                    viewModel: deviceListViewModel,
                    knownApps: buildListViewModel.apps
                )
            case .emulator(let device):
                EmulatorDetailView(
                    device: device,
                    viewModel: deviceListViewModel,
                    knownApps: buildListViewModel.apps
                )
            }
        case .app:
            BuildListView(
                viewModel: buildListViewModel,
                deviceViewModel: deviceListViewModel,
                cache: cache
            )
        case nil:
            EmptyStateView(
                systemImage: "sidebar.squares.left",
                title: "Select an Item",
                description: "Choose a device or app from the sidebar."
            )
        }
    }

    @ViewBuilder
    private var toolbarItems: some View {
        Button {
            Task {
                await refresh()
            }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        .keyboardShortcut("r", modifiers: .command)
        .disabled(buildListViewModel.isLoading)

        Picker("Platform", selection: $buildListViewModel.platformFilter) {
            Text("All Platforms").tag(nil as Platform?)
            Divider()
            ForEach(Platform.allCases) { platform in
                Label(platform.displayName, systemImage: platform.systemImage)
                    .tag(platform as Platform?)
            }
        }
        .pickerStyle(.menu)

        TextField("Search", text: $buildListViewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .frame(width: 150)

        Toggle(isOn: $showDownloads) {
            Label("Downloads", systemImage: "arrow.down.circle")
        }
        .toggleStyle(.button)
    }

    private func configureAndLoad() async {
        await deviceListViewModel.refresh()

        // Auto-select first device if none selected
        if sidebarSelection == nil, let firstDevice = deviceListViewModel.allDevices.first {
            sidebarSelection = .device(firstDevice)
        }

        let indexURLs = settingsViewModel.enabledIndexURLs
        if !indexURLs.isEmpty {
            await indexService.configure(indexURLs: indexURLs)
            await buildListViewModel.refresh()

            // If we have apps but nothing selected, select first app
            if sidebarSelection == nil || sidebarSelection?.isDevice == true {
                if let firstApp = buildListViewModel.filteredApps.first?.app {
                    sidebarSelection = .app(firstApp)
                }
            }
        }
    }

    private func refresh() async {
        await deviceListViewModel.refresh()
        await buildListViewModel.refresh()
    }
}

#Preview {
    let indexService = AppIndexService()
    let simctlService = SimctlService()
    let cache = BuildCache()
    let downloadManager = DownloadManager(cache: cache)

    let buildListViewModel = BuildListViewModel(
        indexService: indexService,
        downloadManager: downloadManager,
        cache: cache,
        simctlService: simctlService
    )

    let deviceListViewModel = DeviceListViewModel(simctlService: simctlService)
    let downloadsViewModel = DownloadsViewModel(downloadManager: downloadManager)
    let settingsViewModel = SettingsViewModel()

    return MainView(
        buildListViewModel: buildListViewModel,
        deviceListViewModel: deviceListViewModel,
        downloadsViewModel: downloadsViewModel,
        settingsViewModel: settingsViewModel,
        indexService: indexService,
        cache: cache,
        downloadManager: downloadManager
    )
    .frame(width: 900, height: 600)
}
