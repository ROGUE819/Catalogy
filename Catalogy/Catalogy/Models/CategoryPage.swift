import Foundation

struct CategoryPage: Codable, Equatable {
    let category: Category
    let topRated: [Product]
    let others: [Product]
}
