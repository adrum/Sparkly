import Foundation

struct AppcastItem: Sendable, Identifiable, Hashable {
    var id: String { "\(bundleVersion)-\(shortVersion)" }

    let title: String
    let pubDate: Date
    let bundleVersion: String
    let shortVersion: String
    let releaseNotes: String?
    let enclosureURL: URL
    let enclosureLength: Int64?
    let edSignature: String?

    var displayVersion: String {
        "\(shortVersion) (\(bundleVersion))"
    }
}
