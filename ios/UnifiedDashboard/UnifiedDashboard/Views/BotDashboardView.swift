import SwiftUI
import WebKit

struct BotDashboardView: View {
    @EnvironmentObject var settings: ServerSettings

    // Known bots — matches config.py
    private let bots: [(id: String, name: String, short: String, color: String)] = [
        ("weather", "Weather Bot", "WX", "#4CAF50"),
        ("btc-range", "BTC Range Arb", "BTC", "#f7931a"),
        ("sports-arb", "Sports Arb", "SPT", "#58a6ff"),
    ]

    @State private var selectedBot: String = "weather"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Bot selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(bots, id: \.id) { bot in
                            Button {
                                selectedBot = bot.id
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Fmt.hexColor(bot.color))
                                        .frame(width: 8, height: 8)
                                    Text(bot.short)
                                        .font(.system(.caption, design: .monospaced, weight: .semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedBot == bot.id ? Color.blue.opacity(0.15) : Color.clear)
                                .foregroundStyle(selectedBot == bot.id ? .blue : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            selectedBot == bot.id ? Color.blue.opacity(0.3) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(red: 0.067, green: 0.094, blue: 0.125))

                // WebView for selected bot
                if let base = settings.baseURL {
                    let dashURL = base.appendingPathComponent("/bot/\(selectedBot)/")
                    BotWebView(url: dashURL, authHeader: settings.basicAuthHeader)
                        .id(selectedBot) // Force reload on bot change
                } else {
                    ContentUnavailableView(
                        "Server Not Configured",
                        systemImage: "server.rack",
                        description: Text("Set your server URL in Settings")
                    )
                }
            }
            .background(Color(red: 0.04, green: 0.055, blue: 0.08))
            .navigationTitle("Bot Dashboards")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - WKWebView wrapper

struct BotWebView: UIViewRepresentable {
    let url: URL
    let authHeader: String?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.04, green: 0.055, blue: 0.08, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor

        var request = URLRequest(url: url)
        if let auth = authHeader {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Reloads happen via .id() modifier on parent
    }
}
