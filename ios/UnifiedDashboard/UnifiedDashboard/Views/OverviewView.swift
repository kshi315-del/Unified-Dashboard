import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var settings: ServerSettings
    @State private var overview: OverviewResponse?
    @State private var error: String?
    @State private var lastUpdated: Date?
    @State private var refreshTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Total P&L header
                    totalPnlCard

                    // Bot cards
                    if let overview {
                        let sortedBots = overview.bots.sorted(by: { $0.key < $1.key })
                        ForEach(sortedBots, id: \.key) { botId, bot in
                            var mutBot = bot
                            mutBot.id = botId
                            BotCardView(botId: botId, bot: mutBot)
                        }
                    }

                    if let error {
                        errorBanner(error)
                    }
                }
                .padding()
            }
            .background(Color(red: 0.04, green: 0.055, blue: 0.08))
            .navigationTitle("Portfolio Overview")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await fetchOnce() }
        }
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    // MARK: - Subviews

    private var totalPnlCard: some View {
        VStack(spacing: 4) {
            Text("TOTAL P&L")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Fmt.pnl(overview?.totalPnl ?? 0))
                .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                .foregroundStyle(Fmt.pnlColor(overview?.totalPnl ?? 0))
            if let lastUpdated {
                Text("Updated \(lastUpdated, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(red: 0.067, green: 0.094, blue: 0.125))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(msg)
                .font(.caption)
                .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            // Inject bot IDs into the structs
            var updatedBots: [String: BotStatus] = [:]
            for (key, var bot) in response.bots {
                bot.id = key
                updatedBots[key] = bot
            }
            response = OverviewResponse(bots: updatedBots, totalPnl: response.totalPnl)
            await MainActor.run {
                self.overview = response
                self.lastUpdated = Date()
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
}
