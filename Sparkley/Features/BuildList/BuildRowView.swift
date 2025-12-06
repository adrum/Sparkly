import SwiftUI

struct BuildRowView: View {
    let build: AppcastItem
    let app: AppEntry
    let isCached: Bool
    let downloadInfo: DownloadInfo?
    let selectedDevice: AnyDevice?
    let onInstall: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(build.shortVersion)
                        .font(.headline)

                    Text("(\(build.bundleVersion))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if isCached {
                        Image(systemName: "internaldrive.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .help("Cached locally")
                    }
                }

                Text(build.pubDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            actionButton
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var actionButton: some View {
        if let downloadInfo {
            switch downloadInfo.state {
            case .pending:
                ProgressView()
                    .controlSize(.small)

            case .downloading(let progress):
                HStack(spacing: 8) {
                    ProgressView(value: progress)
                        .frame(width: 60)

                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

            case .extracting:
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Extracting...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .completed:
                Label("Installed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)

            case .failed(let error):
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .lineLimit(1)

            case .cancelled:
                Text("Cancelled")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        } else {
            Menu {
                if let device = selectedDevice {
                    // Only show install option if platform matches
                    let platformMatches = (app.platform == .ios && device.simulator != nil) ||
                                         (app.platform == .android && device.emulator != nil)

                    if platformMatches {
                        Button("Install on \(device.displayName)") {
                            onInstall()
                        }
                    } else {
                        Text("Select a \(app.platform.displayName) device")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No device selected")
                        .foregroundStyle(.secondary)
                }
            } label: {
                Label(isCached ? "Install" : "Download", systemImage: isCached ? "arrow.down.app" : "arrow.down.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

#Preview {
    let build = AppcastItem(
        title: "Version 1.0.0",
        pubDate: Date(),
        bundleVersion: "100",
        shortVersion: "1.0.0",
        releaseNotes: "Initial release",
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

    VStack {
        BuildRowView(
            build: build,
            app: app,
            isCached: true,
            downloadInfo: nil,
            selectedDevice: nil,
            onInstall: {},
            onCancel: {}
        )

        BuildRowView(
            build: build,
            app: app,
            isCached: false,
            downloadInfo: DownloadInfo(app: app, item: build),
            selectedDevice: nil,
            onInstall: {},
            onCancel: {}
        )
    }
    .padding()
}
