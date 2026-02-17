import Foundation

class ServerSettings: ObservableObject {
    private static let serverURLKey = "serverURL"
    private static let usernameKey = "portalUsername"
    private static let passwordKey = "portalPassword"

    @Published var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: Self.serverURLKey) }
    }

    @Published var username: String {
        didSet { UserDefaults.standard.set(username, forKey: Self.usernameKey) }
    }

    @Published var password: String {
        didSet { UserDefaults.standard.set(password, forKey: Self.passwordKey) }
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
        self.username = UserDefaults.standard.string(forKey: Self.usernameKey) ?? ""
        self.password = UserDefaults.standard.string(forKey: Self.passwordKey) ?? ""
    }
}
