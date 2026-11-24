import Foundation

@Observable
final class SearchViewModel {
    var term = ""
    private(set) var results: Loadable<[Product]> = .idle
    private(set) var lastSearchedTerm = ""
    private let api: CatalogAPI

    init(api: CatalogAPI) { self.api = api }

    var canSearch: Bool { !trimmedTerm.isEmpty }
    var isShowingResults: Bool { !lastSearchedTerm.isEmpty }

    /// Matches the backend's limit so we never send a request it will reject.
    static let maxTermLength = 100

    private var trimmedTerm: String {
        String(term.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxTermLength))
    }

    /// Runs on an explicit action (the search button), per the acceptance criteria.
    func search() async {
        let query = trimmedTerm
        guard !query.isEmpty else { return }
        lastSearchedTerm = query
        results = .loading
        let outcome: Loadable<[Product]>
        do { outcome = .loaded(try await api.search(query)) } catch { outcome = .from(error) }
        // A slow earlier search must not overwrite a newer one (or a clear()).
        guard lastSearchedTerm == query else { return }
        results = outcome
    }

    func clear() {
        term = ""
        lastSearchedTerm = ""
        results = .idle
    }
}
