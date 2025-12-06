import SwiftUI

struct DownloadRowView: View {
    let download: DownloadInfo
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(download.app.name)
                    .font(.callout)
                    .fontWeight(.medium)

                Text(download.item.displayVersion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusView
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusView: some View {
        switch download.state {
        case .pending:
            HStack(spacing: 8) {
                Text("Waiting...")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProgressView()
                    .controlSize(.small)
            }

        case .downloading(let progress):
            HStack(spacing: 8) {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)

                ProgressView(value: progress)
                    .frame(width: 80)

                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

        case .extracting:
            HStack(spacing: 8) {
                Text("Extracting...")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProgressView()
                    .controlSize(.small)
            }

        case .completed:
            Label("Complete", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)

        case .failed(let error):
            Label(error, systemImage: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(1)
                .help(error)

        case .cancelled:
            Text("Cancelled")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let app = AppEntry(
        id: "com.example.app",
        name: "Example App",
        icon: nil,
        platform: .ios,
        appcastURL: URL(string: "https://example.com/appcast.xml")!
    )

    let item = AppcastItem(
        title: "Version 1.0.0",
        pubDate: Date(),
        bundleVersion: "100",
        shortVersion: "1.0.0",
        releaseNotes: nil,
        enclosureURL: URL(string: "https://example.com/app.zip")!,
        enclosureLength: nil,
        edSignature: nil
    )

    var download = DownloadInfo(app: app, item: item)
    download.state = .downloading(progress: 0.65)
    download.progress = 0.65

    return VStack {
        DownloadRowView(download: download, onCancel: {})
    }
    .padding()
    .frame(width: 350)
}
