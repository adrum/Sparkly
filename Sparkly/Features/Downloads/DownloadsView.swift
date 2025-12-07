import SwiftUI

struct DownloadsView: View {
    @Bindable var viewModel: DownloadsViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if viewModel.downloads.isEmpty {
                emptyState
            } else {
                downloadsList
            }
        }
        .frame(height: 150)
        .background(.background)
    }

    private var header: some View {
        HStack {
            Label("Downloads", systemImage: "arrow.down.circle")
                .font(.headline)

            Spacer()

            if !viewModel.completedDownloads.isEmpty || !viewModel.failedDownloads.isEmpty {
                Button("Clear Completed") {
                    viewModel.clearCompleted()
                }
                .buttonStyle(.link)
                .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("No active downloads")
                .foregroundStyle(.secondary)
                .font(.callout)
            Spacer()
        }
    }

    private var downloadsList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.downloads) { download in
                    DownloadRowView(download: download) {
                        viewModel.cancel(download)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    let manager = DownloadManager()
    let viewModel = DownloadsViewModel(downloadManager: manager)

    return DownloadsView(viewModel: viewModel)
        .frame(width: 400)
}
