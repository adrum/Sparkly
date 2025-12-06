import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showingAddSheet = false
    @State private var editingSource: IndexSource?

    var body: some View {
        Form {
            Section {
                if viewModel.indexSources.isEmpty {
                    Text("No index sources configured")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(viewModel.indexSources) { source in
                        IndexSourceRow(
                            source: source,
                            onToggle: { viewModel.toggleSource(source) },
                            onEdit: { editingSource = source },
                            onDelete: { viewModel.removeSource(source) }
                        )
                    }
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Index Source", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            } header: {
                Text("Index Sources")
            } footer: {
                Text("Add multiple Sparkley JSON index files. Apps from all enabled sources will be combined.")
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
        .sheet(isPresented: $showingAddSheet) {
            IndexSourceEditorSheet(
                source: nil,
                onSave: { name, url in
                    viewModel.addSource(name: name, urlString: url)
                }
            )
        }
        .sheet(item: $editingSource) { source in
            IndexSourceEditorSheet(
                source: source,
                onSave: { name, url in
                    if let index = viewModel.indexSources.firstIndex(where: { $0.id == source.id }) {
                        viewModel.indexSources[index].name = name
                        viewModel.indexSources[index].urlString = url
                    }
                }
            )
        }
    }
}

struct IndexSourceRow: View {
    let source: IndexSource
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: source.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(source.isEnabled ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(source.name)
                        .fontWeight(.medium)

                    if !source.isValid && !source.urlString.isEmpty {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                            .help("Invalid URL")
                    }
                }

                Text(source.urlString.isEmpty ? "No URL configured" : source.urlString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

struct IndexSourceEditorSheet: View {
    let source: IndexSource?
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var urlString: String = ""

    private var isEditing: Bool {
        source != nil
    }

    private var isValid: Bool {
        !name.isEmpty && !urlString.isEmpty && (URL(string: urlString)?.scheme?.hasPrefix("http") == true || URL(string: urlString)?.scheme == "file")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit Index Source" : "Add Index Source")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            Form {
                TextField("Name", text: $name, prompt: Text("My Team's Builds"))

                TextField("URL", text: $urlString, prompt: Text("https://example.com/sparkley-index.json"))

                if !urlString.isEmpty && !isValid {
                    Label("Please enter a valid HTTP, HTTPS, or file URL", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button(isEditing ? "Save" : "Add") {
                    onSave(name, urlString)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 400, height: 250)
        .onAppear {
            if let source {
                name = source.name
                urlString = source.urlString
            }
        }
    }
}

#Preview {
    GeneralSettingsView(viewModel: SettingsViewModel())
        .frame(width: 450, height: 350)
}
