import Foundation

struct SimulatorDevice: Identifiable, Sendable, Hashable {
    let udid: String
    let name: String
    let deviceTypeIdentifier: String
    let runtime: String
    let state: DeviceState
    let isAvailable: Bool

    var id: String { udid }

    enum DeviceState: String, Codable, Sendable {
        case shutdown = "Shutdown"
        case booted = "Booted"
        case shuttingDown = "Shutting Down"
        case unknown

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = DeviceState(rawValue: rawValue) ?? .unknown
        }
    }

    var isBooted: Bool {
        state == .booted
    }

    var stateIcon: String {
        switch state {
        case .booted:
            return "circle.fill"
        case .shutdown:
            return "circle"
        case .shuttingDown:
            return "circle.dotted"
        case .unknown:
            return "questionmark.circle"
        }
    }

    var runtimeDisplayName: String {
        // Handle both identifier format (com.apple.CoreSimulator.SimRuntime.iOS-26-0)
        // and display format (iOS 26.0)
        if runtime.contains("com.apple.CoreSimulator") {
            return runtime
                .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
                .replacingOccurrences(of: "-", with: " ")
        }
        return runtime
    }
}

struct SimctlDeviceList: Codable, Sendable {
    let devices: [String: [SimctlDevice]]
}

struct SimctlDevice: Codable, Sendable {
    let udid: String
    let name: String
    let deviceTypeIdentifier: String
    let state: String
    let isAvailable: Bool

    func toSimulatorDevice(runtime: String) -> SimulatorDevice {
        SimulatorDevice(
            udid: udid,
            name: name,
            deviceTypeIdentifier: deviceTypeIdentifier,
            runtime: runtime,
            state: SimulatorDevice.DeviceState(rawValue: state) ?? .unknown,
            isAvailable: isAvailable
        )
    }
}
