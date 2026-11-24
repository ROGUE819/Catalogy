import Foundation

enum APIError: LocalizedError, Equatable {
    case network
    case offline
    case timeout
    case rateLimited
    case notFound
    case validation([FieldError])
    case server(String)
    case decoding

    struct FieldError: Codable, Equatable {
        let field: String
        let message: String
    }

    var errorDescription: String? {
        switch self {
        case .network: "Can't reach the server. Check that the backend is running and try again."
        case .offline: "You appear to be offline. Check your connection and try again."
        case .timeout: "The server took too long to respond. Please try again."
        case .rateLimited: "Too many requests. Please wait a moment and try again."
        case .notFound: "We couldn't find what you were looking for."
        case .validation(let fields): fields.map(\.message).joined(separator: "\n")
        case .server(let message): message
        case .decoding: "Something went wrong reading the server response."
        }
    }
}
