import Foundation

enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Server URL not configured"
        case .invalidURL: return "Invalid URL"
        case .httpError(let code): return "HTTP \(code)"
        case .decodingError(let err): return "Decode error: \(err.localizedDescription)"
        case .networkError(let err): return err.localizedDescription
        }
    }
}

class APIClient {
    private let settings: ServerSettings
    private let session: URLSession
    private let decoder: JSONDecoder

    init(settings: ServerSettings) {
        self.settings = settings
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    // MARK: - Overview

    func fetchOverview() async throws -> OverviewResponse {
        return try await get("/api/overview")
    }

    // MARK: - Capital

    func fetchCapital() async throws -> CapitalResponse {
        return try await get("/api/capital")
    }

    func fetchTransfers(limit: Int = 20) async throws -> TransfersResponse {
        return try await get("/api/capital/transfers?limit=\(limit)")
    }

    func allocateCapital(botId: String, label: String, amount: Double) async throws {
        let body = AllocateRequest(botId: botId, label: label, amount: amount)
        let _: [String: Bool] = try await post("/api/capital/allocate", body: body)
    }

    func transferCapital(from: String, to: String, amount: Double) async throws {
        let body = TransferRequest(from: from, to: to, amount: amount)
        let _: [String: Bool] = try await post("/api/capital/transfer", body: body)
    }

    func removeAllocation(botId: String) async throws {
        let _: [String: Bool] = try await delete("/api/capital/\(botId)")
    }

    // MARK: - HTTP helpers

    private func makeRequest(_ path: String, method: String = "GET") throws -> URLRequest {
        guard let base = settings.baseURL else { throw APIError.notConfigured }
        guard let url = URL(string: path, relativeTo: base) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        if let auth = settings.basicAuthHeader {
            req.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let req = try makeRequest(path)
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }
            guard (200...299).contains(http.statusCode) else { throw APIError.httpError(http.statusCode) }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var req = try makeRequest(path, method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }
            guard (200...299).contains(http.statusCode) else { throw APIError.httpError(http.statusCode) }
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func delete<T: Decodable>(_ path: String) async throws -> T {
        let req = try makeRequest(path, method: "DELETE")
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }
            guard (200...299).contains(http.statusCode) else { throw APIError.httpError(http.statusCode) }
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
