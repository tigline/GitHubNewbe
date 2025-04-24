//
//  APIClient.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(statusCode: Int, message: String)
    case rateLimitExceeded
    case unauthorized
}

@Observable class APIClient {
    static let shared = APIClient()
    
    private var baseURL: URL
    private var token: String?
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(baseURL: URL = URL(string: "https://api.github.com")!,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func setToken(_ token: String) {
        self.token = token
    }
    
    func clearToken() {
        self.token = nil
    }
    
    func request<T: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        // 1. 构建URL
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }
        
        if let queryItems = queryItems {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        // 2. 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // 3. 添加认证Token（如果有）
        if let token = token {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 4. 添加请求体（如果有）
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        }
        
        // 5. 发送请求
        let (data, response) = try await session.data(for: request)
        
        // 6. 检查响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // 7. 处理HTTP状态码
        switch httpResponse.statusCode {
        case 200..<300:
            // 成功，继续处理
            break
        case 401:
            throw APIError.unauthorized
        case 403:
            if httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0" {
                throw APIError.rateLimitExceeded
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Forbidden")
        default:
            throw APIError.serverError(
                statusCode: httpResponse.statusCode,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }
        
        // 8. 解码响应数据
        do {
            return try await Task.detached { [decoder] in
                try decoder.decode(T.self, from: data)
            }.value
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

