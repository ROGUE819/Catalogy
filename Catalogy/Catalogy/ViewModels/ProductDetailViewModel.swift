import Foundation

@Observable
final class ProductDetailViewModel {
    private(set) var product: Product
    private let api: CatalogAPI

    init(product: Product, api: CatalogAPI) {
        self.product = product
        self.api = api
    }

    /// Refreshes from the backend so the page reflects the source of truth.
    /// Failures are ignored because we already have the product from the list.
    func refresh() async {
        if let latest = try? await api.product(id: product.id) { product = latest }
    }
}
