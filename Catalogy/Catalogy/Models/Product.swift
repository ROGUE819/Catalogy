import Foundation

/// Mirrors the backend's product contract (not Fake Store's shape).
struct Product: Codable, Identifiable, Hashable {
    struct Rating: Codable, Hashable {
        let average: Double
        let count: Int
    }

    let id: String
    let title: String
    let description: String
    let price: Decimal
    let currency: String
    let category: Category
    let imageUrl: URL
    let rating: Rating

    var formattedPrice: String {
        price.formatted(.currency(code: currency))
    }
}
