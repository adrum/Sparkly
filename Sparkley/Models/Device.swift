import Foundation

/// A unified protocol for both iOS Simulators and Android Emulators
protocol DeviceProtocol: Identifiable, Hashable, Sendable {
    var id: String { get }
    var displayName: String { get }
    var platform: Platform { get }
    var isReady: Bool { get }
    var statusText: String { get }
}

/// Wrapper enum to hold either device type
enum AnyDevice: Identifiable, Hashable, Sendable {
    case simulator(SimulatorDevice)
    case emulator(EmulatorDevice)

    var id: String {
        switch self {
        case .simulator(let device): return "sim-\(device.id)"
        case .emulator(let device): return "emu-\(device.id)"
        }
    }

    var displayName: String {
        switch self {
        case .simulator(let device): return device.name
        case .emulator(let device): return device.displayName
        }
    }

    var platform: Platform {
        switch self {
        case .simulator: return .ios
        case .emulator: return .android
        }
    }

    var isReady: Bool {
        switch self {
        case .simulator(let device): return device.isBooted
        case .emulator(let device): return device.isOnline
        }
    }

    var statusText: String {
        switch self {
        case .simulator(let device): return device.runtimeDisplayName
        case .emulator(let device): return device.runtimeDisplayName
        }
    }

    var simulator: SimulatorDevice? {
        if case .simulator(let device) = self { return device }
        return nil
    }

    var emulator: EmulatorDevice? {
        if case .emulator(let device) = self { return device }
        return nil
    }

    var deviceIcon: String {
        switch self {
        case .simulator(let device):
            let name = device.name.lowercased()
            if name.contains("ipad") { return "ipad" }
            else if name.contains("watch") { return "applewatch" }
            else if name.contains("tv") { return "appletv" }
            else { return "iphone" }
        case .emulator:
            return "flipphone"
        }
    }
}
