import SwiftUI

struct CapitalCardView: View {
    let account: CapitalAccount
    var onRemove: (() -> Void)? = nil

    private var accentColor: Color { Fmt.hexColor(account.color) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.label)
                        .font(.system(.subheadline, design: .monospaced, weight: .bold))
                        .foregroundStyle(.textPrimary)
                    Text(account.id)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(accentColor.opacity(0.7))
                }
                Spacer()
                if let onRemove {
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.textDim.opacity(0.4))
                    }
                }
            }

            // Effective balance (hero)
            Text(Fmt.dollars(account.effective))
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.textPrimary)

            // Allocation + P&L inline
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    Circle()
                        .stroke(Color.textDim.opacity(0.3), lineWidth: 1)
                        .frame(width: 6, height: 6)
                    Text("Alloc \(Fmt.dollars(account.allocation))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.textDim)
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(Fmt.pnlColorCents(account.pnl).opacity(0.8))
                        .frame(width: 6, height: 6)
                    Text(Fmt.signedDollars(account.pnl))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Fmt.pnlColorCents(account.pnl))
                }
            }

            // P&L progress bar
            GeometryReader { geo in
                let pnlFraction = account.allocation > 0
                    ? max(-1, min(1, Double(account.pnl) / Double(account.allocation)))
                    : 0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.cardBorder)
                        .frame(height: 3)
                    Capsule()
                        .fill(Fmt.pnlColorCents(account.pnl).opacity(0.6))
                        .frame(width: max(4, geo.size.width * abs(pnlFraction)), height: 3)
                }
            }
            .frame(height: 3)
        }
        .cardStyle(accent: accentColor)
    }
}
