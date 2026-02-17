import SwiftUI

enum Fmt {
    // MARK: - Cached formatters

    private static let dollarFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        f.decimalSeparator = "."
        return f
    }()

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoStandard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f
    }()

    // MARK: - Dollar formatting

    private static func fmtDollar(_ value: Double) -> String {
        dollarFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    /// Format cents as "$1,234.56"
    static func dollars(_ cents: Int) -> String {
        let value = Double(abs(cents)) / 100.0
        return "$\(fmtDollar(value))"
    }

    /// Format cents as "+$12.34" or "-$5.00"
    static func signedDollars(_ cents: Int) -> String {
        let sign = cents >= 0 ? "+" : "-"
        let value = Double(abs(cents)) / 100.0
        return "\(sign)$\(fmtDollar(value))"
    }

    /// Format a dollar amount (already in dollars, not cents)
    static func pnl(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)$\(fmtDollar(abs(value)))"
    }

    // MARK: - Colors

    /// Color for P&L value
    static func pnlColor(_ value: Double) -> Color {
        if value > 0 { return .portalGreen }
        if value < 0 { return .portalRed }
        return .textDim
    }

    /// Color for P&L in cents
    static func pnlColorCents(_ cents: Int) -> Color {
        if cents > 0 { return .portalGreen }
        if cents < 0 { return .portalRed }
        return .textDim
    }

    /// Parse hex color string to SwiftUI Color
    static func hexColor(_ hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6,
              let val = UInt64(cleaned, radix: 16) else {
            return .gray
        }
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    // MARK: - Dates

    /// Parse ISO timestamp to readable string
    static func timestamp(_ iso: String) -> String {
        if let date = isoFractional.date(from: iso) {
            return displayFormatter.string(from: date)
        }
        if let date = isoStandard.date(from: iso) {
            return displayFormatter.string(from: date)
        }
        return iso
    }

    /// Relative time string ("just now", "5s ago", "2m ago")
    static func relativeTime(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 5 { return "just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }
}
