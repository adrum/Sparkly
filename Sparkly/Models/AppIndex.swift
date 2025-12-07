import Foundation

struct AppIndex: Codable, Sendable {
    let version: Int
    let title: String?
    let apps: [AppEntry]
}
