import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)

                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))

                    case .failure:
                        placeholderIcon

                    @unknown default:
                        placeholderIcon
                    }
                }
            } else {
                placeholderIcon
            }
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "app.fill")
            .font(.system(size: size * 0.6))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}

#Preview {
    HStack {
        AsyncImageView(url: nil, size: 32)
        AsyncImageView(url: URL(string: "https://example.com/icon.png"), size: 32)
    }
    .padding()
}
