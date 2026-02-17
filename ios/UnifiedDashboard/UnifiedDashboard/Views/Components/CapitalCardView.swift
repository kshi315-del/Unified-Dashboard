import SwiftUI

struct CapitalCardView: View {
    let account: CapitalAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(account.label)
                    .font(.system(.headline, design: .monospaced, weight: .semibold))
                Spacer()
                Text(account.id)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(Fmt.dollars(account.effective))
                .font(.system(.title2, design: .monospaced, weight: .bold))

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ALLOCATION")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(Fmt.dollars(account.allocation))
                        .font(.system(.body, design: .monospaced, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("P&L")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(Fmt.signedDollars(account.pnl))
                        .font(.system(.body, design: .monospaced, weight: .semibold))
                        .foregroundStyle(Fmt.pnlColorCents(account.pnl))
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
            Fmt.hexColor(account.color)
                .frame(width: 3)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 12, bottomLeadingRadius: 12
                ))
        }
    }
}
