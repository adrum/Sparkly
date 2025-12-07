import SwiftUI

struct CacheSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let cache: BuildCache

    @State private var currentCacheSize: Int64 = 0
    @State private var isClearing = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Location") {
                    HStack {
                        Text(cache.cacheLocation.path)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Button {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: cache.cacheLocation.path)
                        } label: {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                LabeledContent("Current Size") {
                    Text(ByteCountFormatter.string(fromByteCount: currentCacheSize, countStyle: .file))
                        .foregroundStyle(.secondary)
                }

                Slider(value: $viewModel.maxCacheSizeGB, in: 1...100, step: 1) {
                    Text("Maximum Size")
                } minimumValueLabel: {
                    Text("1 GB")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("100 GB")
                        .font(.caption)
                }

                Text("Maximum: \(Int(viewModel.maxCacheSizeGB)) GB")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } header: {
                Text("Cache")
            } footer: {
                Text("Downloaded builds are cached locally for faster reinstallation. Old builds are automatically removed when the cache exceeds the maximum size.")
            }

            Section {
                Button(role: .destructive) {
                    clearCache()
                } label: {
                    if isClearing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Clear Cache")
                    }
                }
                .disabled(isClearing || currentCacheSize == 0)
            }
        }
        .formStyle(.grouped)
        .task {
            await refreshCacheSize()
        }
    }

    private func refreshCacheSize() async {
        do {
            currentCacheSize = try await cache.currentCacheSize()
        } catch {
            currentCacheSize = 0
        }
    }

    private func clearCache() {
        isClearing = true
        Task {
            do {
                try await cache.clearCache()
                await refreshCacheSize()
            } catch {
                print("Failed to clear cache: \(error)")
            }
            await MainActor.run {
                isClearing = false
            }
        }
    }
}

#Preview {
    CacheSettingsView(
        viewModel: SettingsViewModel(),
        cache: BuildCache()
    )
    .frame(width: 450, height: 350)
}
