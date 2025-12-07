import Foundation

struct InstalledApp: Identifiable, Sendable, Hashable {
    let bundleID: String
    let name: String
    let platform: Platform

    var id: String { bundleID }

    var displayName: String {
        name.isEmpty ? bundleID : name
    }
}
