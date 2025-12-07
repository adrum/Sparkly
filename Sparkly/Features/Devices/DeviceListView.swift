import SwiftUI

struct DeviceListView: View {
    @Bindable var viewModel: DeviceListViewModel

    var body: some View {
        Group {
            if viewModel.allDevices.isEmpty && !viewModel.isLoading {
                Text("No devices")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(.horizontal)
            } else {
                ForEach(viewModel.allDevices) { device in
                    UnifiedDeviceRowView(
                        device: device,
                        isSelected: viewModel.selectedDevice?.id == device.id
                    )
                    .tag(device)
                    .onTapGesture {
                        viewModel.selectedDevice = device
                    }
                    .contextMenu {
                        switch device {
                        case .simulator(let sim):
                            if sim.isBooted {
                                Button("Shutdown") {
                                    Task {
                                        await viewModel.shutdown(sim)
                                    }
                                }
                            } else {
                                Button("Boot") {
                                    Task {
                                        await viewModel.boot(sim)
                                    }
                                }
                            }
                        case .emulator(let emu):
                            if emu.isOnline {
                                Button("Kill Emulator") {
                                    Task {
                                        await viewModel.killEmulator(emu)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct UnifiedDeviceRowView: View {
    let device: AnyDevice
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: device.deviceIcon)
                .foregroundStyle(device.isReady ? .green : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.displayName)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)

                Text(device.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if device.isReady {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }
}
