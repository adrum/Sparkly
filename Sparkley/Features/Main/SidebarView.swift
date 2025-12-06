import SwiftUI

struct SidebarView: View {
    @Bindable var buildListViewModel: BuildListViewModel
    @Bindable var deviceListViewModel: DeviceListViewModel
    @Binding var selection: SidebarSelection?

    @State private var sidebarSearchText: String = ""
    @State private var isDevicesSectionExpanded = true
    @State private var isAppsSectionExpanded = true

    private var filteredDevices: [SimulatorDevice] {
        if sidebarSearchText.isEmpty {
            return deviceListViewModel.devices
        }
        return deviceListViewModel.devices.filter {
            $0.name.localizedCaseInsensitiveContains(sidebarSearchText) ||
            $0.runtimeDisplayName.localizedCaseInsensitiveContains(sidebarSearchText)
        }
    }

    private var filteredApps: [AppWithBuilds] {
        var result = buildListViewModel.filteredApps
        if !sidebarSearchText.isEmpty {
            result = result.filter {
                $0.app.name.localizedCaseInsensitiveContains(sidebarSearchText) ||
                $0.app.id.localizedCaseInsensitiveContains(sidebarSearchText)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField

            List(selection: $selection) {
                Section(isExpanded: $isDevicesSectionExpanded) {
                    devicesSection
                } header: {
                    Text("Devices")
                }

                Section(isExpanded: $isAppsSectionExpanded) {
                    appsSection
                } header: {
                    Text("Apps")
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 220)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter", text: $sidebarSearchText)
                .textFieldStyle(.plain)
            if !sidebarSearchText.isEmpty {
                Button {
                    sidebarSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(8)
    }

    @ViewBuilder
    private var devicesSection: some View {
        if filteredDevices.isEmpty && !deviceListViewModel.isLoading {
            Text(sidebarSearchText.isEmpty ? "No simulators" : "No matches")
                .foregroundStyle(.secondary)
                .font(.caption)
        } else {
            ForEach(filteredDevices) { device in
                DeviceRow(device: device)
                    .tag(SidebarSelection.device(device))
                    .contextMenu {
                        deviceContextMenu(for: device)
                    }
            }
        }
    }

    @ViewBuilder
    private func deviceContextMenu(for device: SimulatorDevice) -> some View {
        if device.isBooted {
            Button("Shutdown") {
                Task { await deviceListViewModel.shutdown(device) }
            }
        } else {
            Button("Boot") {
                Task { await deviceListViewModel.boot(device) }
            }
        }

        Divider()

        Button("Open Simulator") {
            Task { await deviceListViewModel.openSimulatorApp() }
        }

        Divider()

        Button("Copy UDID") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(device.udid, forType: .string)
        }
    }

    @ViewBuilder
    private var appsSection: some View {
        if buildListViewModel.isLoading {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } else if let error = buildListViewModel.errorMessage {
            VStack(alignment: .leading, spacing: 4) {
                Label("Error", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
                Text(error)
                    .foregroundStyle(.secondary)
                    .font(.caption2)
                    .lineLimit(3)
            }
            .padding(.vertical, 4)
        } else if filteredApps.isEmpty {
            Text(sidebarSearchText.isEmpty ? "No apps" : "No matches")
                .foregroundStyle(.secondary)
                .font(.caption)
        } else {
            ForEach(filteredApps) { appWithBuilds in
                AppRow(
                    app: appWithBuilds.app,
                    buildCount: appWithBuilds.builds.count
                )
                .tag(SidebarSelection.app(appWithBuilds.app))
                .contextMenu {
                    appContextMenu(for: appWithBuilds)
                }
            }
        }
    }

    @ViewBuilder
    private func appContextMenu(for appWithBuilds: AppWithBuilds) -> some View {
        Button("Refresh Builds") {
            Task { await buildListViewModel.refresh() }
        }

        Divider()

        Button("Copy Bundle ID") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(appWithBuilds.app.id, forType: .string)
        }

        Button("Copy Appcast URL") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(appWithBuilds.app.appcastURL.absoluteString, forType: .string)
        }
    }
}

struct DeviceRow: View {
    let device: SimulatorDevice

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: deviceIcon)
                .foregroundStyle(device.isBooted ? .green : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .lineLimit(1)

                Text(device.runtimeDisplayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if device.isBooted {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 2)
    }

    private var deviceIcon: String {
        let name = device.name.lowercased()
        if name.contains("ipad") {
            return "ipad"
        } else if name.contains("watch") {
            return "applewatch"
        } else if name.contains("tv") {
            return "appletv"
        } else {
            return "iphone"
        }
    }
}

struct AppRow: View {
    let app: AppEntry
    let buildCount: Int

    var body: some View {
        HStack(spacing: 8) {
            AsyncImageView(url: app.icon, size: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: app.platform.systemImage)
                        .font(.caption2)

                    Text("\(buildCount) build\(buildCount == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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

    return SidebarView(
        buildListViewModel: buildListViewModel,
        deviceListViewModel: deviceListViewModel,
        selection: .constant(nil)
    )
    .frame(width: 250, height: 500)
}
