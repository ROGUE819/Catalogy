import Foundation

/// Common async state for screens.
enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }

    init(_ result: Result<Value, Error>) {
        switch result {
        case .success(let value): self = .loaded(value)
        case .failure(let error): self = .from(error)
        }
    }

    static func from(_ error: Error) -> Loadable {
        .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
    }
}
