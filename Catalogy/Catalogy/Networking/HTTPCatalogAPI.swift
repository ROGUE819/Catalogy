import Foundation

/// `CatalogAPI` implementation that talks to the Catalogy backend over HTTP/JSON.
final class HTTPCatalogAPI: CatalogAPI {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// The base URL can be overridden with the `API_BASE_URL` environment variable (Xcode scheme).
    /// 127.0.0.1 is exempt from App Transport Security, so plain HTTP works on the Simulator.
    static func fromEnvironment(_ env: [String: String] = ProcessInfo.processInfo.environment) -> HTTPCatalogAPI {
        let url = env["API_BASE_URL"].flatMap(URL.init(string:)) ?? URL(string: "http://127.0.0.1:3000/api")!
        return HTTPCatalogAPI(baseURL: url)
    }

    func featuredProducts() async throws -> [Product] {
        try await get(ProductsEnvelope.self, path: "products/featured").products
    }

    func categories() async throws -> [Category] {
        try await get(CategoriesEnvelope.self, path: "categories").categories
    }

    func categoryPage(id: String) async throws -> CategoryPage {
        try await get(CategoryPage.self, path: "categories/\(Self.pathSegment(id))/products")
    }

    func search(_ term: String) async throws -> [Product] {
        try await get(ProductsEnvelope.self, path: "products", query: [URLQueryItem(name: "search", value: term)]).products
    }

    func product(id: String) async throws -> Product {
        try await get(ProductEnvelope.self, path: "products/\(Self.pathSegment(id))").product
    }

    /// Percent-encodes an id so it can't change the path (e.g. "../" or "?").
    static func pathSegment(_ id: String) -> String {
        id.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-_"))) ?? id
    }

    func submitEnquiry(_ enquiry: EnquiryRequest) async throws -> EnquiryConfirmation {
        var request = URLRequest(url: baseURL.appending(path: "enquiries"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(enquiry)
        return try await send(request, as: EnquiryConfirmation.self)
    }

    // MARK: - Response envelopes

    private struct ProductsEnvelope: Decodable { let products: [Product] }
    private struct ProductEnvelope: Decodable { let product: Product }
    private struct CategoriesEnvelope: Decodable { let categories: [Category] }
    private struct ErrorBody: Decodable {
        let error: String
        let fields: [APIError.FieldError]?
    }

    // MARK: - Plumbing

    private func get<T: Decodable>(_ type: T.Type, path: String, query: [URLQueryItem] = []) async throws -> T {
        var url = baseURL.appending(path: path)
        if !query.isEmpty { url.append(queryItems: query) }
        return try await send(URLRequest(url: url), as: type)
    }

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        var request = request
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            switch error.code {
            case .cancelled: throw CancellationError()
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed: throw APIError.offline
            case .timedOut: throw APIError.timeout
            default: throw APIError.network
            }
        } catch {
            throw APIError.network
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let body = try? decoder.decode(ErrorBody.self, from: data)
            switch status {
            case 404: throw APIError.notFound
            case 429: throw APIError.rateLimited
            case 400 where body?.fields != nil: throw APIError.validation(body?.fields ?? [])
            default: throw APIError.server(body?.error ?? "Unexpected server error (\(status)).")
            }
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
