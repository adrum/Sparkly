import Foundation

enum SidebarSelection: Hashable, Sendable {
    case device(SimulatorDevice)
    case app(AppEntry)

    var device: SimulatorDevice? {
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
}
