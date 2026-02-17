import Foundation

class ServerSettings: ObservableObject {
    private static let serverURLKey = "serverURL"
    private static let usernameKey = "portalUsername"
    private static let passwordKey = "portalPassword"

    @Published var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: Self.serverURLKey) }
    }

    @Published var username: String {
        didSet { KeychainHelper.save(username, for: Self.usernameKey) }
    }

    @Published var password: String {
        didSet { KeychainHelper.save(password, for: Self.passwordKey) }
    }

    var baseURL: URL? {
        URL(string: serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL)
    }

    var isConfigured: Bool {
        baseURL != nil
    }

    var basicAuthHeader: String? {
        guard !username.isEmpty, !password.isEmpty else { return nil }
        let cred = "\(username):\(password)"
        guard let data = cred.data(using: .utf8) else { return nil }
        return "Basic \(data.base64EncodedString())"
    }

    init() {
        self.serverURL = UserDefaults.standard.string(forKey: Self.serverURLKey) ?? ""

        // Migrate from UserDefaults to Keychain if needed
        if let legacyUser = UserDefaults.standard.string(forKey: Self.usernameKey), !legacyUser.isEmpty {
            KeychainHelper.save(legacyUser, for: Self.usernameKey)
            UserDefaults.standard.removeObject(forKey: Self.usernameKey)
        }
        if let legacyPass = UserDefaults.standard.string(forKey: Self.passwordKey), !legacyPass.isEmpty {
            KeychainHelper.save(legacyPass, for: Self.passwordKey)
            UserDefaults.standard.removeObject(forKey: Self.passwordKey)
        }

        self.username = KeychainHelper.load(for: Self.usernameKey) ?? ""
        self.password = KeychainHelper.load(for: Self.passwordKey) ?? ""
    }
}
