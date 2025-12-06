import SwiftUI

struct EmulatorDetailView: View {
    let device: EmulatorDevice
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
}
