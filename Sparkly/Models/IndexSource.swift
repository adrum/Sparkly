import Foundation

struct IndexSource: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var name: String
    var urlString: String
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, urlString: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.isEnabled = isEnabled
    }

    var url: URL? {
        URL(string: urlString)
    }

    var isValid: Bool {
        guard let url else { return false }
        return url.scheme == "http" || url.scheme == "https" || url.scheme == "file"
    }
}
