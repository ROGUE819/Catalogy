import Foundation
@testable import Catalogy

extension Product {
    static func fixture(id: String, title: String) -> Product {
        Product(
            id: id, title: title, description: "desc", price: 9.99, currency: "USD",
            category: .init(id: "jewelery", name: "Jewelery"),
            imageUrl: URL(string: "https://example.com/\(id).png")!,
            rating: .init(average: 4.2, count: 10)
        )
    }
}
