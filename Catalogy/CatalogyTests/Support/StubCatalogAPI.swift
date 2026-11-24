import Foundation
@testable import Catalogy

/// In-memory `CatalogAPI` so view-model tests don't hit the network.
final class StubCatalogAPI: CatalogAPI {
    var products: [Product] = [.fixture(id: "1", title: "Gold ring"), .fixture(id: "2", title: "SSD drive")]
    var error: Error?
    private(set) var searchedTerms: [String] = []
    private(set) var submittedEnquiries: [EnquiryRequest] = []

    private func result<T>(_ value: T) throws -> T {
        if let error { throw error }
        return value
    }

    func featuredProducts() async throws -> [Product] { try result(products) }

    func categories() async throws -> [Catalogy.Category] {
        try result([.init(id: "jewelery", name: "Jewelery")])
    }

    func categoryPage(id: String) async throws -> CategoryPage {
        try result(CategoryPage(
            category: .init(id: id, name: id),
            topRated: Array(products.prefix(1)),
            others: Array(products.dropFirst())
        ))
    }

    func search(_ term: String) async throws -> [Product] {
        searchedTerms.append(term)
        return try result(products.filter { $0.title.localizedCaseInsensitiveContains(term) })
    }

    func product(id: String) async throws -> Product {
        guard let product = products.first(where: { $0.id == id }) else { throw APIError.notFound }
        return try result(product)
    }

    func submitEnquiry(_ enquiry: EnquiryRequest) async throws -> EnquiryConfirmation {
        submittedEnquiries.append(enquiry)
        return try result(EnquiryConfirmation(id: "e1", message: "Thank you!"))
    }
}
