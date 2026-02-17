import SwiftUI

struct CapitalView: View {
    @EnvironmentObject var settings: ServerSettings
    @State private var capital: CapitalResponse?
    @State private var transfers: [Transfer] = []
    @State private var error: String?
    @State private var lastUpdated: Date?
    @State private var refreshTask: Task<Void, Never>?

    // Allocate form
    @State private var allocBotId = ""
    @State private var allocLabel = ""
    @State private var allocAmount = ""
    @State private var allocFeedback = ""
    @State private var allocIsError = false

    // Transfer form
    @State private var xferFrom = "unallocated"
    @State private var xferTo = "unallocated"
    @State private var xferAmount = ""
    @State private var xferFeedback = ""
    @State private var xferIsError = false

    @State private var showAllocateSheet = false
    @State private var showTransferSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    balanceHeader
                    accountCards
                    actionButtons
                    allocationsSection
                    transferHistorySection
                }
                .padding()
            }
            .background(Color(red: 0.04, green: 0.055, blue: 0.08))
            .navigationTitle("Capital Management")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await fetchAll() }
            .sheet(isPresented: $showAllocateSheet) { allocateSheet }
            .sheet(isPresented: $showTransferSheet) { transferSheet }
        }
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    // MARK: - Balance header

    private var balanceHeader: some View {
        VStack(spacing: 4) {
            Text("ACCOUNT BALANCE")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let balance = capital?.realBalance {
                Text(Fmt.dollars(balance))
                    .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                    .foregroundStyle(Fmt.pnlColorCents(balance))
            } else {
                Text(Fmt.dollars(capital?.totalAllocated ?? 0) + " allocated")
                    .font(.system(.title2, design: .monospaced, weight: .bold))
            }
            if let unalloc = capital?.unallocated {
                Text("Unallocated: \(Fmt.dollars(unalloc))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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

    // MARK: - Account cards

    private var accountCards: some View {
        ForEach(capital?.accounts ?? []) { account in
            CapitalCardView(account: account)
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showAllocateSheet = true
            } label: {
                Label("Allocate", systemImage: "plus.circle.fill")
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                showTransferSheet = true
            } label: {
                Label("Transfer", systemImage: "arrow.left.arrow.right")
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Allocations table

    private var allocationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ALLOCATIONS")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)

            if let accounts = capital?.accounts, !accounts.isEmpty {
                ForEach(accounts) { a in
                    HStack {
                        Circle()
                            .fill(Fmt.hexColor(a.color))
                            .frame(width: 8, height: 8)
                        Text(a.label)
                            .font(.system(.caption, design: .monospaced, weight: .semibold))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Fmt.dollars(a.allocation))
                                .font(.system(.caption, design: .monospaced))
                            Text(Fmt.signedDollars(a.pnl))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Fmt.pnlColorCents(a.pnl))
                        }
                        Button(role: .destructive) {
                            Task { await removeAllocation(a.id) }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .padding(.vertical, 4)
                    Divider().overlay(Color.white.opacity(0.05))
                }
            } else {
                Text("No allocations yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color(red: 0.067, green: 0.094, blue: 0.125))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Transfer history

    private var transferHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRANSFER HISTORY")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)

            if transfers.isEmpty {
                Text("No transfers yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(transfers) { t in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(displayName(t.from)) -> \(displayName(t.to))")
                                .font(.system(.caption, design: .monospaced, weight: .semibold))
                            Text(Fmt.timestamp(t.ts))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Fmt.dollars(t.amount))
                            .font(.system(.caption, design: .monospaced, weight: .semibold))
                    }
                    .padding(.vertical, 4)
                    Divider().overlay(Color.white.opacity(0.05))
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
    }

    // MARK: - Allocate sheet

    private var allocateSheet: some View {
        NavigationStack {
            Form {
                Section("Bot") {
                    TextField("Bot ID (e.g. btc-range)", text: $allocBotId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Label (e.g. BTC Range)", text: $allocLabel)
                }
                Section("Amount") {
                    TextField("Amount in dollars", text: $allocAmount)
                        .keyboardType(.decimalPad)
                }
                if !allocFeedback.isEmpty {
                    Section {
                        Text(allocFeedback)
                            .foregroundStyle(allocIsError ? .red : .green)
                            .font(.caption)
                    }
                }
                Section {
                    Button("Allocate") {
                        Task { await doAllocate() }
                    }
                    .disabled(allocBotId.isEmpty || allocLabel.isEmpty || allocAmount.isEmpty)
                }
            }
            .navigationTitle("Allocate Capital")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAllocateSheet = false }
                }
            }
        }
    }

    // MARK: - Transfer sheet

    private var transferSheet: some View {
        NavigationStack {
            Form {
                Section("From") {
                    Picker("Source", selection: $xferFrom) {
                        Text("Unallocated").tag("unallocated")
                        ForEach(capital?.accounts ?? []) { a in
                            Text("\(a.label) (\(Fmt.dollars(a.allocation)))").tag(a.id)
                        }
                    }
                }
                Section("To") {
                    Picker("Destination", selection: $xferTo) {
                        Text("Unallocated").tag("unallocated")
                        ForEach(capital?.accounts ?? []) { a in
                            Text("\(a.label) (\(Fmt.dollars(a.allocation)))").tag(a.id)
                        }
                    }
                }
                Section("Amount") {
                    TextField("Amount in dollars", text: $xferAmount)
                        .keyboardType(.decimalPad)
                }
                if !xferFeedback.isEmpty {
                    Section {
                        Text(xferFeedback)
                            .foregroundStyle(xferIsError ? .red : .green)
                            .font(.caption)
                    }
                }
                Section {
                    Button("Transfer") {
                        Task { await doTransfer() }
                    }
                    .disabled(xferFrom == xferTo || xferAmount.isEmpty)
                }
            }
            .navigationTitle("Transfer Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showTransferSheet = false }
                }
            }
        }
    }

    // MARK: - Actions

    private func doAllocate() async {
        guard let amount = Double(allocAmount), amount >= 0 else {
            allocFeedback = "Enter a valid amount"
            allocIsError = true
            return
        }
        let client = APIClient(settings: settings)
        do {
            try await client.allocateCapital(botId: allocBotId, label: allocLabel, amount: amount)
            allocFeedback = "Allocated $\(String(format: "%.2f", amount)) to \(allocLabel)"
            allocIsError = false
            allocAmount = ""
            await fetchAll()
        } catch {
            allocFeedback = error.localizedDescription
            allocIsError = true
        }
    }

    private func doTransfer() async {
        guard let amount = Double(xferAmount), amount > 0 else {
            xferFeedback = "Enter a valid amount"
            xferIsError = true
            return
        }
        let client = APIClient(settings: settings)
        do {
            try await client.transferCapital(from: xferFrom, to: xferTo, amount: amount)
            xferFeedback = "Transfer complete"
            xferIsError = false
            xferAmount = ""
            await fetchAll()
        } catch {
            xferFeedback = error.localizedDescription
            xferIsError = true
        }
    }

    private func removeAllocation(_ botId: String) async {
        let client = APIClient(settings: settings)
        do {
            try await client.removeAllocation(botId: botId)
            await fetchAll()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func displayName(_ id: String) -> String {
        id == "unallocated" ? "Unallocated" : id
    }

    // MARK: - Polling

    private func startPolling() {
        refreshTask = Task {
            while !Task.isCancelled {
                await fetchAll()
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    private func stopPolling() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func fetchAll() async {
        let client = APIClient(settings: settings)
        do {
            async let cap = client.fetchCapital()
            async let xfer = client.fetchTransfers()
            let (capResult, xferResult) = try await (cap, xfer)
            await MainActor.run {
                self.capital = capResult
                self.transfers = xferResult.transfers
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
