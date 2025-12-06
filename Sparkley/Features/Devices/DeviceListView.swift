import SwiftUI

struct DeviceListView: View {
    @Bindable var viewModel: DeviceListViewModel

    var body: some View {
        Group {
            if viewModel.devices.isEmpty && !viewModel.isLoading {
                Text("No simulators")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(.horizontal)
            } else {
                ForEach(viewModel.devices) { device in
                    DeviceRowView(
                        device: device,
                        isSelected: viewModel.selectedDevice?.id == device.id
                    )
                    .tag(device)
                    .onTapGesture {
                        viewModel.selectedDevice = device
                    }
                    .contextMenu {
                        if device.isBooted {
                            Button("Shutdown") {
                                Task {
                                    await viewModel.shutdown(device)
                                }
                            }
                        } else {
                            Button("Boot") {
                                Task {
                                    await viewModel.boot(device)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
