import Foundation

/// Abstraction the UI depends on, so view models can be tested with a stub
/// and the transport can change without touching screens.
protocol CatalogAPI {
    func featuredProducts() async throws -> [Product]
    func categories() async throws -> [Category]
    func categoryPage(id: String) async throws -> CategoryPage
    func search(_ term: String) async throws -> [Product]
    func product(id: String) async throws -> Product
    func submitEnquiry(_ enquiry: EnquiryRequest) async throws -> EnquiryConfirmation
}
