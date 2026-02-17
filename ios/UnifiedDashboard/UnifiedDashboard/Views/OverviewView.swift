import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var settings: ServerSettings
    @State private var overview: OverviewResponse?
    @State private var error: String?
    @State private var lastUpdated: Date?
    @State private var refreshTask: Task<Void, Never>?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if isLoading && overview == nil {
                        LoadingCard()
                    } else if let overview {
                        // Hero P&L
                        GlowNumber(
                            label: "TOTAL P&L",
                            value: Fmt.pnl(overview.totalPnl),
                            color: Fmt.pnlColor(overview.totalPnl),
                            subtitle: lastUpdated.map { "Updated \(Fmt.relativeTime($0))" }
                        )

                        // Bot count summary
                        let healthy = overview.bots.values.filter { $0.healthy && $0.error == nil }.count
                        let total = overview.bots.count
                        HStack(spacing: 16) {
                            HStack(spacing: 5) {
                                Circle().fill(.portalGreen).frame(width: 6, height: 6)
                                Text("\(healthy) healthy")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.textDim)
                            }
                            if healthy < total {
                                HStack(spacing: 5) {
                                    Circle().fill(.portalRed).frame(width: 6, height: 6)
                                    Text("\(total - healthy) issues")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(.textDim)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 4)

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
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable { await fetchOnce() }
        }
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
