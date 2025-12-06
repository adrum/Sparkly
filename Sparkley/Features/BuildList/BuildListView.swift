import SwiftUI

struct BuildListView: View {
    @Bindable var viewModel: BuildListViewModel
    @Bindable var deviceViewModel: DeviceListViewModel
    let cache: BuildCache

    @State private var cachedStatus: [String: Bool] = [:]

    var body: some View {
        Group {
            if let selectedApp = viewModel.selectedApp {
                buildList(for: selectedApp)
            } else {
                EmptyStateView(
                    systemImage: "square.stack.3d.up",
                    title: "Select an App",
                    description: "Choose an app from the sidebar to see available builds."
                )
            }
        }
        .onChange(of: viewModel.selectedApp) { _, newApp in
            if let app = newApp {
                Task {
                    await refreshCacheStatus(for: app)
                }
            }
        }
    }

    @ViewBuilder
    private func buildList(for app: AppEntry) -> some View {
        let builds = viewModel.selectedAppBuilds

        if builds.isEmpty {
            EmptyStateView(
                systemImage: "tray",
                title: "No Builds",
                description: "No builds available for \(app.name)."
            )
        } else {
            VStack(spacing: 0) {
                appHeader(app: app, buildCount: builds.count)

                Divider()

                List(selection: $viewModel.selectedBuild) {
                    ForEach(builds) { build in
                        BuildRowView(
                            build: build,
                            app: app,
                            isCached: cachedStatus[build.id] ?? false,
                            downloadInfo: viewModel.downloadManager.downloadInfo(for: build, app: app),
                            selectedDevice: deviceViewModel.selectedDevice,
                            onInstall: {
                                Task {
                                    await install(build, for: app)
                                }
                            },
                            onCancel: {
                                viewModel.cancelDownload(build, for: app)
                            }
                        )
                        .tag(build)
                    }
                }
                .listStyle(.inset)

                if let selectedBuild = viewModel.selectedBuild {
                    Divider()

                    BuildDetailView(build: selectedBuild, app: app)
                        .frame(height: 250)
                }
            }
        }
    }

    private func appHeader(app: AppEntry, buildCount: Int) -> some View {
        HStack(spacing: 12) {
            AsyncImageView(url: app.icon, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.headline)

                Text("\(buildCount) build\(buildCount == 1 ? "" : "s") available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: app.platform.systemImage)
                Text(app.platform.displayName)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.2))
            .clipShape(Capsule())
        }
        .padding()
    }

    private func refreshCacheStatus(for app: AppEntry) async {
        let builds = viewModel.apps.first { $0.app.id == app.id }?.builds ?? []

        for build in builds {
            let isCached = await cache.cachedPath(for: build, app: app) != nil
            await MainActor.run {
                cachedStatus[build.id] = isCached
            }
        }
    }

    private func install(_ build: AppcastItem, for app: AppEntry) async {
        guard let device = deviceViewModel.selectedDevice else { return }

        do {
            try await viewModel.install(build, for: app, on: device)
            cachedStatus[build.id] = true
        } catch {
            print("Installation failed: \(error)")
        }
    }
}
