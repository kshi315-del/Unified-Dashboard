import Foundation

// MARK: - /api/overview response

struct OverviewResponse: Codable {
    let bots: [String: BotStatus]
    let totalPnl: Double

    enum CodingKeys: String, CodingKey {
        case bots
        case totalPnl = "total_pnl"
    }
}

struct BotStatus: Codable, Identifiable {
    var id: String = ""

    let name: String
    let short: String
    let color: String
    let healthy: Bool
    let mode: String
    let pnl: Double
    let error: String?

    // Optional fields (bot-specific)
    let winRate: Double?
    let completed: Int?
    let wins: Int?
    let openPositions: Int?
    let dailyTrades: Int?
    let running: Bool?
    let realizedPnl: Double?

    enum CodingKeys: String, CodingKey {
        case name, short, color, healthy, mode, pnl, error
        case winRate = "win_rate"
        case completed, wins
        case openPositions = "open_positions"
        case dailyTrades = "daily_trades"
        case running
        case realizedPnl = "realized_pnl"
    }
}
