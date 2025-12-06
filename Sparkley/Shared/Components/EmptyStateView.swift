import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let description: String
    var action: (() -> Void)?
    var actionLabel: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let action, let actionLabel {
                Button(actionLabel) {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "app.badge",
        title: "No Apps",
        description: "Configure an index URL in Settings to see available apps.",
        action: {},
        actionLabel: "Open Settings"
    )
}
