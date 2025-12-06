import Foundation

enum Platform: String, Codable, Sendable, CaseIterable, Identifiable {
    case ios
    case android

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ios:
            return "iOS"
        case .android:
            return "Android"
        }
    }

    var systemImage: String {
        switch self {
        case .ios:
            return "iphone"
        case .android:
            return "play.rectangle.fill"
        }
    }
}
