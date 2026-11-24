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
        Self.formatPrice(price, currency: currency)
    }

    /// Formats in the currency's home locale so ₹ uses Indian digit grouping
    /// (₹1,00,000.00), regardless of the device's region.
    static func formatPrice(_ price: Decimal, currency: String) -> String {
        let locale = currency.uppercased() == "INR" ? Locale(identifier: "en_IN") : Locale.current
        return price.formatted(.currency(code: currency).locale(locale))
    }
}
