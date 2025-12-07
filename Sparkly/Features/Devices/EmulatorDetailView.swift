import SwiftUI

struct EmulatorDetailView: View {
    let device: EmulatorDevice
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
                    if device.isOnline {
                        installedAppsSection
                    }
                }
                .padding()
            }
        }
        .task(id: device.serial) {
            await loadInstalledApps()
        }
        .onChange(of: device.isOnline) { _, isOnline in
            if isOnline {
                Task { await loadInstalledApps() }
            } else {
                installedApps = []
            }
        }
    }

    private func loadInstalledApps() async {
        guard device.isOnline else {
            installedApps = []
            return
        }
        isLoadingApps = true
        installedApps = await viewModel.listInstalledApps(on: .emulator(device))
        isLoadingApps = false
    }

    private var deviceHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "flipphone")
                .font(.system(size: 40))
                .foregroundStyle(device.isOnline ? .green : .secondary)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.displayName)
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
                .fill(device.isOnline ? .green : .secondary)
                .frame(width: 8, height: 8)
            Text(device.state.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(device.isOnline ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
        .clipShape(Capsule())
    }

    private var deviceInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Information")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("Serial")
                        .foregroundStyle(.secondary)
                    Text(device.serial)
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                }

                if let avdName = device.avdName {
                    GridRow {
                        Text("AVD Name")
                            .foregroundStyle(.secondary)
                        Text(avdName)
                    }
                }

                GridRow {
                    Text("Type")
                        .foregroundStyle(.secondary)
                    Text(device.isEmulator ? "Emulator" : "Physical Device")
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
                if device.isOnline && device.isEmulator {
                    Button {
                        Task { await viewModel.killEmulator(device) }
                    } label: {
                        Label("Kill Emulator", systemImage: "power")
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }

            if !device.isOnline {
                Text("Device is offline")
                    .foregroundStyle(.secondary)
                    .font(.caption)
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
                                await viewModel.launchApp(app, on: .emulator(device))
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
}
