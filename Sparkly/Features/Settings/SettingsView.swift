import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var cache = BuildCache()

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            CacheSettingsView(viewModel: viewModel, cache: cache)
                .tabItem {
                    Label("Cache", systemImage: "internaldrive")
                }
        }
        .frame(width: 450, height: 300)
    }
}

#Preview {
    SettingsView()
}
