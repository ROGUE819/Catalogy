import Foundation

@Observable
final class CategoryViewModel {
    private(set) var state: Loadable<CategoryPage> = .idle
    let category: Category
    private let api: CatalogAPI

    init(category: Category, api: CatalogAPI) {
        self.category = category
        self.api = api
    }

    func load() async {
        if state.value == nil { state = .loading }
        do { state = .loaded(try await api.categoryPage(id: category.id)) } catch { state = .from(error) }
    }
}
