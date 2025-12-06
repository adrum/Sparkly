import Foundation

struct EmulatorDevice: Identifiable, Sendable, Hashable {
    let serial: String
    let name: String
    let avdName: String?
    let state: DeviceState
    let isEmulator: Bool

    var id: String { serial }

    enum DeviceState: String, Sendable {
        case online = "device"
        case offline = "offline"
        case unauthorized = "unauthorized"
        case noDevice = "no device"
        case unknown

        var displayName: String {
            switch self {
            case .online: return "Online"
            case .offline: return "Offline"
            case .unauthorized: return "Unauthorized"
            case .noDevice: return "No Device"
            case .unknown: return "Unknown"
            }
        }

        var isReady: Bool {
            self == .online
        }
    }

    var isOnline: Bool {
        state == .online
    }

    var displayName: String {
        if let avd = avdName, !avd.isEmpty {
            return avd.replacingOccurrences(of: "_", with: " ")
        }
        return name.isEmpty ? serial : name
    }

    var runtimeDisplayName: String {
        isEmulator ? "Android Emulator" : "Android Device"
    }
}
