import Foundation

struct AppWithBuilds: Identifiable, Sendable {
    let app: AppEntry
    let builds: [AppcastItem]

    var id: String { app.id }

    var latestBuild: AppcastItem? {
        builds.first
    }

    var sortedBuilds: [AppcastItem] {
        builds.sorted { $0.pubDate > $1.pubDate }
    }
}
