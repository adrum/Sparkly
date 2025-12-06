import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                TextField("Index URL", text: $viewModel.indexURLString, prompt: Text("https://example.com/sparkley-index.json"))
                    .textFieldStyle(.roundedBorder)

                if !viewModel.indexURLString.isEmpty && !viewModel.isIndexURLValid {
                    Label("Please enter a valid HTTP or HTTPS URL", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            } header: {
                Text("App Index")
            } footer: {
                Text("The URL to your Sparkley JSON index file containing app definitions and appcast URLs.")
            }

            Section {
                Toggle("Auto-refresh", isOn: $viewModel.autoRefreshEnabled)

                if viewModel.autoRefreshEnabled {
                    Picker("Refresh every", selection: $viewModel.autoRefreshIntervalMinutes) {
                        Text("5 minutes").tag(5)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                    }
                }
            } header: {
                Text("Refresh")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    GeneralSettingsView(viewModel: SettingsViewModel())
        .frame(width: 450, height: 300)
}
