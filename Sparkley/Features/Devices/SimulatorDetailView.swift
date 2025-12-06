import SwiftUI

struct SimulatorDetailView: View {
    let device: SimulatorDevice
    @Bindable var viewModel: DeviceListViewModel
    let knownApps: [AppWithBuilds]

    @State private var installedApps: [InstalledApp] = []
    @State private var isLoadingApps = false

    private func matchingAppEntry(for installedApp: InstalledApp) -> AppEntry? {
        knownApps.first { $0.app.id == installedApp.bundleID }?.app
    }

    var body: some View {
        VStack(spacing: 0) {
            deviceHeader

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    deviceInfoSection
                    actionsSection
                    if device.isBooted {
                        installedAppsSection
                    }
                }
                .padding()
            }
        }
        .task(id: device.udid) {
            await loadInstalledApps()
        }
        .onChange(of: device.isBooted) { _, isBooted in
            if isBooted {
                Task { await loadInstalledApps() }
            } else {
                installedApps = []
            }
        }
    }

    private func loadInstalledApps() async {
        guard device.isBooted else {
            installedApps = []
            return
        }
        isLoadingApps = true
        installedApps = await viewModel.listInstalledApps(on: .simulator(device))
        isLoadingApps = false
    }

    private var deviceHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: deviceIcon)
                .font(.system(size: 40))
                .foregroundStyle(device.isBooted ? .green : .secondary)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.headline)

                Text(device.runtimeDisplayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge
        }
        .padding()
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(device.isBooted ? .green : .secondary)
                .frame(width: 8, height: 8)
            Text(device.state.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(device.isBooted ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
        .clipShape(Capsule())
    }

    private var deviceInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Information")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("UDID")
                        .foregroundStyle(.secondary)
                    Text(device.udid)
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                }

                GridRow {
                    Text("Runtime")
                        .foregroundStyle(.secondary)
                    Text(device.runtimeDisplayName)
                }

                GridRow {
                    Text("Device Type")
                        .foregroundStyle(.secondary)
                    Text(deviceTypeName)
                }

                GridRow {
                    Text("State")
                        .foregroundStyle(.secondary)
                    Text(device.state.displayName)
                }
            }
            .font(.body)
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            HStack(spacing: 12) {
                if device.isBooted {
                    Button {
                        Task { await viewModel.shutdown(device) }
                    } label: {
                        Label("Shutdown", systemImage: "power")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        Task { await viewModel.boot(device) }
                    } label: {
                        Label("Boot", systemImage: "power")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    Task { await viewModel.openSimulatorApp() }
                } label: {
                    Label("Open Simulator", systemImage: "macwindow")
                }
                .buttonStyle(.bordered)

                Spacer()
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var installedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Installed Apps")
                    .font(.headline)

                Spacer()

                Button {
                    Task { await loadInstalledApps() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isLoadingApps)
            }

            if isLoadingApps {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading apps...")
                        .foregroundStyle(.secondary)
                }
            } else if installedApps.isEmpty {
                Text("No third-party apps installed")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 8) {
                    ForEach(installedApps) { app in
                        InstalledAppRow(
                            app: app,
                            matchingEntry: matchingAppEntry(for: app)
                        ) {
                            Task {
                                await viewModel.launchApp(app, on: .simulator(device))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

    private var deviceTypeName: String {
        device.deviceTypeIdentifier
            .replacingOccurrences(of: "com.apple.CoreSimulator.SimDeviceType.", with: "")
            .replacingOccurrences(of: "-", with: " ")
    }
}

extension SimulatorDevice.DeviceState {
    var displayName: String {
        switch self {
        case .booted: return "Booted"
        case .shutdown: return "Shutdown"
        case .shuttingDown: return "Shutting Down"
        case .unknown: return "Unknown"
        }
    }
}

struct InstalledAppRow: View {
    let app: InstalledApp
    let matchingEntry: AppEntry?
    let onLaunch: () -> Void

    private var displayName: String {
        matchingEntry?.name ?? app.displayName
    }

    private var hasMatch: Bool {
        matchingEntry != nil
    }

    var body: some View {
        HStack(spacing: 8) {
            if let iconURL = matchingEntry?.icon {
                AsyncImageView(url: iconURL, size: 32)
            } else {
                Image(systemName: app.platform == .ios ? "app.fill" : "play.rectangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(displayName)
                        .lineLimit(1)
                        .font(.subheadline)
                        .fontWeight(hasMatch ? .medium : .regular)

                    if hasMatch {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .help("App from your library")
                    }
                }

                Text(app.bundleID)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onLaunch()
            } label: {
                Image(systemName: "play.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(8)
        .background(hasMatch ? Color.blue.opacity(0.05) : Color.clear)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(hasMatch ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}
