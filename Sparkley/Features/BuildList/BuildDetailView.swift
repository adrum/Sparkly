import SwiftUI

struct BuildDetailView: View {
    let build: AppcastItem
    let app: AppEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                Divider()

                ReleaseNotesView(html: build.releaseNotes, title: build.displayVersion)

                Spacer()
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImageView(url: app.icon, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(build.displayVersion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                platformBadge
            }

            HStack(spacing: 16) {
                Label {
                    Text(build.pubDate, style: .date)
                } icon: {
                    Image(systemName: "calendar")
                }

                if let size = build.enclosureLength {
                    Label {
                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    } icon: {
                        Image(systemName: "doc.zipper")
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var platformBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: app.platform == .ios ? "iphone" : "android")
            Text(app.platform.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.secondary.opacity(0.2))
        .clipShape(Capsule())
    }
}

#Preview {
    let build = AppcastItem(
        title: "Version 1.2.3",
        pubDate: Date(),
        bundleVersion: "456",
        shortVersion: "1.2.3",
        releaseNotes: """
        <h2>What's New</h2>
        <ul>
            <li>Added dark mode support</li>
            <li>Fixed crash on launch</li>
            <li>Performance improvements</li>
        </ul>
        """,
        enclosureURL: URL(string: "https://example.com/app.zip")!,
        enclosureLength: 50_000_000,
        edSignature: nil
    )

    let app = AppEntry(
        id: "com.example.app",
        name: "Example App",
        icon: nil,
        platform: .ios,
        appcastURL: URL(string: "https://example.com/appcast.xml")!
    )

    BuildDetailView(build: build, app: app)
        .frame(width: 400, height: 500)
}
