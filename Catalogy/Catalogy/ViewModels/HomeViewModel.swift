import Foundation

@Observable
final class HomeViewModel {
    private(set) var featured: Loadable<[Product]> = .idle
    private(set) var categories: Loadable<[Category]> = .idle
    private let api: CatalogAPI

    init(api: CatalogAPI) { self.api = api }

    func load() async {
        if featured.value == nil { featured = .loading }
        if categories.value == nil { categories = .loading }
        async let featuredResult = Result { try await api.featuredProducts() }
        async let categoriesResult = Result { try await api.categories() }
        featured = Loadable(await featuredResult)
        categories = Loadable(await categoriesResult)
    }
}
