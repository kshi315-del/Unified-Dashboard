import SwiftUI

struct BotCardView: View {
    let botId: String
    let bot: BotStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: name + health badge
            HStack {
                Text(bot.name)
                    .font(.system(.headline, design: .monospaced, weight: .semibold))
                Spacer()
                healthBadge
            }

            if let error = bot.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    statItem(label: "P&L", value: Fmt.pnl(bot.pnl), color: Fmt.pnlColor(bot.pnl))
                    statItem(label: "MODE", value: bot.mode)

                    if let wr = bot.winRate {
                        statItem(label: "WIN RATE", value: "\(String(format: "%.1f", wr))%")
                    }
                    if let trades = bot.completed {
                        let winsStr = bot.wins.map { " (\($0)W)" } ?? ""
                        statItem(label: "TRADES", value: "\(trades)\(winsStr)")
                    }
                    if let open = bot.openPositions {
                        statItem(label: "OPEN", value: "\(open)")
                    }
                    if let daily = bot.dailyTrades {
                        statItem(label: "DAILY TRADES", value: "\(daily)")
                    }
                    if let running = bot.running {
                        statItem(label: "RUNNING", value: running ? "Yes" : "No",
                                 color: running ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.067, green: 0.094, blue: 0.125))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            Fmt.hexColor(bot.color)
                .frame(width: 3)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 12, bottomLeadingRadius: 12
                ))
        }
    }

    private var healthBadge: some View {
        let isError = bot.error != nil
        let label = isError ? "UNREACHABLE" : (bot.healthy ? "HEALTHY" : "UNHEALTHY")
        let bg: Color = isError ? .gray.opacity(0.2) : (bot.healthy ? .green.opacity(0.15) : .red.opacity(0.15))
        let fg: Color = isError ? .secondary : (bot.healthy ? .green : .red)

        return Text(label)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func statItem(label: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
