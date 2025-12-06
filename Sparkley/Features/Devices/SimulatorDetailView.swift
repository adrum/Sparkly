import SwiftUI

struct SimulatorDetailView: View {
    let device: SimulatorDevice
    @Bindable var viewModel: DeviceListViewModel

    var body: some View {
        VStack(spacing: 0) {
            deviceHeader

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    deviceInfoSection
                    actionsSection
                }
                .padding()
            }
        }
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
