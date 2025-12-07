import Foundation

struct AppEntry: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: URL?
    let platform: Platform
    let appcastURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case platform
        case appcastURL
    }
}
