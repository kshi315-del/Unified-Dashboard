import SwiftUI

enum Fmt {
    /// Format cents as "$1,234.56"
    static func dollars(_ cents: Int) -> String {
        let value = Double(abs(cents)) / 100.0
        return "$\(String(format: "%.2f", value))"
    }

    /// Format cents as "+$12.34" or "-$5.00"
    static func signedDollars(_ cents: Int) -> String {
        let sign = cents >= 0 ? "+" : "-"
        let value = Double(abs(cents)) / 100.0
        return "\(sign)$\(String(format: "%.2f", value))"
    }

    /// Format a dollar amount (already in dollars, not cents)
    static func pnl(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", abs(value)))"
    }

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

    /// Parse ISO timestamp to readable string
    static func timestamp(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) {
            let display = DateFormatter()
            display.dateStyle = .short
            display.timeStyle = .medium
            return display.string(from: date)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: iso) {
            let display = DateFormatter()
            display.dateStyle = .short
            display.timeStyle = .medium
            return display.string(from: date)
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
