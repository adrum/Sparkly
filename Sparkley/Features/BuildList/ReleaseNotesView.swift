import SwiftUI
import WebKit

struct ReleaseNotesView: View {
    let html: String?
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Release Notes")
                .font(.headline)

            if let html, !html.isEmpty {
                ReleaseNotesWebView(html: wrapHTML(html))
                    .frame(minHeight: 100, maxHeight: 300)
            } else {
                Text("No release notes available.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }

    private func wrapHTML(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 13px;
                    line-height: 1.5;
                    color: #333;
                    margin: 0;
                    padding: 8px;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #ddd; }
                }
                h1, h2, h3 { margin: 0.5em 0; }
                h2 { font-size: 14px; }
                ul, ol { padding-left: 20px; margin: 0.5em 0; }
                li { margin: 0.25em 0; }
                a { color: #007AFF; }
                p { margin: 0.5em 0; }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }
}

struct ReleaseNotesWebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.isElementFullscreenEnabled = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    ReleaseNotesView(
        html: """
        <h2>What's New</h2>
        <ul>
            <li>Added dark mode support</li>
            <li>Fixed crash on launch</li>
            <li>Performance improvements</li>
        </ul>
        """,
        title: "Version 1.2.3"
    )
    .padding()
    .frame(width: 400)
}
