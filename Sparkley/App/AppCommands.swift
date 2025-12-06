import SwiftUI

struct AppCommands: Commands {
    let refreshAction: () async -> Void

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Refresh") {
                Task {
                    await refreshAction()
                }
            }
            .keyboardShortcut("r", modifiers: .command)
        }

        CommandGroup(replacing: .help) {
            Link("Sparkley Help", destination: URL(string: "https://github.com/sparkley/sparkley")!)
        }
    }
}
