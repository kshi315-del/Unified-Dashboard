import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var settings: ServerSettings
    @State private var overview: OverviewResponse?
    @State private var error: String?
    @State private var lastUpdated: Date?
    @State private var refreshTask: Task<Void, Never>?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Drag indicator
                Capsule()
                    .fill(Color.textDim.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                if isLoading && overview == nil {
                    LoadingCard()
                } else if let overview {
                    // Hero P&L
                    GlowNumber(
                        label: "Total P&L",
                        value: Fmt.pnl(overview.totalPnl),
                        color: Fmt.pnlColor(overview.totalPnl),
                        subtitle: "USD"
                    )

                    // Bot cards
                    let sortedBots = overview.bots.sorted(by: { $0.key < $1.key })
                    ForEach(sortedBots, id: \.key) { botId, bot in
                        var mutBot = bot
                        mutBot.id = botId
                        BotCardView(botId: botId, bot: mutBot)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }

                if let error {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .foregroundStyle(.portalRed)
                        Text(error)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.portalRed)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.portalRed.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.portalRed.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.3), value: overview?.totalPnl)
        }
        .background(Color.portalBg)
        .refreshable { await fetchOnce() }
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    // MARK: - Polling

    private func startPolling() {
        refreshTask = Task {
            while !Task.isCancelled {
                await fetchOnce()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    private func stopPolling() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func fetchOnce() async {
        let client = APIClient(settings: settings)
        do {
            var response = try await client.fetchOverview()
            var updatedBots: [String: BotStatus] = [:]
            for (key, var bot) in response.bots {
                bot.id = key
                updatedBots[key] = bot
            }
            response = OverviewResponse(bots: updatedBots, totalPnl: response.totalPnl)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.overview = response
                    self.lastUpdated = Date()
                    self.error = nil
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
