import Foundation

enum SidebarSelection: Hashable, Sendable {
    case device(AnyDevice)
    case app(AppEntry)

    var device: AnyDevice? {
        if case .device(let d) = self { return d }
        return nil
    }

    var app: AppEntry? {
        if case .app(let a) = self { return a }
        return nil
    }

    var isDevice: Bool {
        if case .device = self { return true }
        return false
    }

    var isApp: Bool {
        if case .app = self { return true }
        return false
    }

    /// Convenience for getting a SimulatorDevice if the selection is an iOS simulator
    var simulator: SimulatorDevice? {
        device?.simulator
    }

    /// Convenience for getting an EmulatorDevice if the selection is an Android emulator
    var emulator: EmulatorDevice? {
        device?.emulator
    }
}
