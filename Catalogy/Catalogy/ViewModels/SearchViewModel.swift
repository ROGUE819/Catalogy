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

    private var trimmedTerm: String { term.trimmingCharacters(in: .whitespaces) }

    /// Runs on an explicit action (the search button), per the acceptance criteria.
    func search() async {
        let query = trimmedTerm
        guard !query.isEmpty else { return }
        lastSearchedTerm = query
        results = .loading
        do { results = .loaded(try await api.search(query)) } catch { results = .from(error) }
    }

    func clear() {
        term = ""
        lastSearchedTerm = ""
        results = .idle
    }
}
