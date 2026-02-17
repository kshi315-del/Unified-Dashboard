import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: ServerSettings
    var isInitialSetup: Bool

    @State private var testResult: String?
    @State private var testSuccess = false
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isInitialSetup {
                        VStack(spacing: 8) {
                            Image(systemName: "server.rack")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                            Text("Connect to your Portal")
                                .font(.headline)
                            Text("Enter the URL of your Unified Dashboard server to get started.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                }

                Section("Server") {
                    TextField("Server URL (e.g. http://192.168.1.100:8080)", text: $settings.serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }

                Section("Authentication (optional)") {
                    TextField("Username", text: $settings.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $settings.password)
                }

                Section {
                    Button {
                        Task { await testConnection() }
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Text(isTesting ? "Testing..." : "Test Connection")
                        }
                    }
                    .disabled(!settings.isConfigured || isTesting)

                    if let result = testResult {
                        HStack {
                            Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(testSuccess ? .green : .red)
                            Text(result)
                                .font(.caption)
                                .foregroundStyle(testSuccess ? .green : .red)
                        }
                    }
                }

                if !isInitialSetup {
                    Section("About") {
                        HStack {
                            Text("App")
                            Spacer()
                            Text("Unified Dashboard iOS")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Server URL")
                            Spacer()
                            Text(settings.serverURL.isEmpty ? "Not set" : settings.serverURL)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .navigationTitle(isInitialSetup ? "Setup" : "Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil
        let client = APIClient(settings: settings)
        do {
            let overview = try await client.fetchOverview()
            let botCount = overview.bots.count
            await MainActor.run {
                testResult = "Connected — \(botCount) bot\(botCount == 1 ? "" : "s") found"
                testSuccess = true
                isTesting = false
            }
        } catch {
            await MainActor.run {
                testResult = error.localizedDescription
                testSuccess = false
                isTesting = false
            }
        }
    }
}
