import Foundation

class ServerSettings: ObservableObject {
    private static let serverURLKey = "serverURL"
    private static let usernameKey = "portalUsername"
    private static let passwordKey = "portalPassword"
    private static let sshHostKey = "sshHost"
    private static let sshPortKey = "sshPort"
    private static let sshUserKey = "sshUsername"
    private static let sshPasswordKey = "sshPassword"

    @Published var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: Self.serverURLKey) }
    }

    @Published var username: String {
        didSet { KeychainHelper.save(username, for: Self.usernameKey) }
    }

    @Published var password: String {
        didSet { KeychainHelper.save(password, for: Self.passwordKey) }
    }

    @Published var sshHost: String {
        didSet { UserDefaults.standard.set(sshHost, forKey: Self.sshHostKey) }
    }

    @Published var sshPort: String {
        didSet { UserDefaults.standard.set(sshPort, forKey: Self.sshPortKey) }
    }

    @Published var sshUser: String {
        didSet { KeychainHelper.save(sshUser, for: Self.sshUserKey) }
    }

    @Published var sshPassword: String {
        didSet { KeychainHelper.save(sshPassword, for: Self.sshPasswordKey) }
    }

    var hasSSHCredentials: Bool {
        !sshHost.isEmpty && !sshUser.isEmpty && !sshPassword.isEmpty
    }

    var baseURL: URL? {
        var url = serverURL
        // Remove trailing slash
        if url.hasSuffix("/") {
            url = String(url.dropLast())
        }

        let lowercased = url.lowercased()
        let isLocal = lowercased.contains("localhost") || lowercased.contains("127.0.0.1") || lowercased.contains("192.168.")

        // Allow HTTP for localhost and local networks only; force HTTPS for remote
        if lowercased.hasPrefix("http://") {
            if !isLocal {
                url = "https://" + String(url.dropFirst(7))
            }
        } else if !lowercased.hasPrefix("https://") {
            url = "https://" + url
        }
        return URL(string: url)
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

        self.sshHost = UserDefaults.standard.string(forKey: Self.sshHostKey) ?? ""
        self.sshPort = UserDefaults.standard.string(forKey: Self.sshPortKey) ?? "22"
        self.sshUser = KeychainHelper.load(for: Self.sshUserKey) ?? ""
        self.sshPassword = KeychainHelper.load(for: Self.sshPasswordKey) ?? ""
    }
}
