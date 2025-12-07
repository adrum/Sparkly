import SwiftUI

struct DeviceRowView: View {
    let device: SimulatorDevice
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: deviceIcon)
                .foregroundStyle(device.isBooted ? .green : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .fontWeight(isSelected ? .semibold : .regular)

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
        .padding(.vertical, 4)
        .contentShape(Rectangle())
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

#Preview {
    VStack {
        DeviceRowView(
            device: SimulatorDevice(
                udid: "123",
                name: "iPhone 15 Pro",
                deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro",
                runtime: "com.apple.CoreSimulator.SimRuntime.iOS-17-0",
                state: .booted,
                isAvailable: true
            ),
            isSelected: true
        )

        DeviceRowView(
            device: SimulatorDevice(
                udid: "456",
                name: "iPad Pro (12.9-inch)",
                deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-12-9-inch",
                runtime: "com.apple.CoreSimulator.SimRuntime.iOS-17-0",
                state: .shutdown,
                isAvailable: true
            ),
            isSelected: false
        )
    }
    .padding()
    .frame(width: 250)
}
