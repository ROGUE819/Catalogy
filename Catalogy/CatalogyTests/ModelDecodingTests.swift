import XCTest
@testable import Catalogy

final class ModelDecodingTests: XCTestCase {

    func testDecodesBackendProductContract() throws {
        let json = """
        {"id":"1","title":"Backpack","description":"d","price":9180.83,"currency":"INR",
         "category":{"id":"mens-clothing","name":"Men's Clothing"},
         "imageUrl":"http://127.0.0.1:3000/api/products/1/image","rating":{"average":3.9,"count":120}}
        """
        let product = try JSONDecoder().decode(Product.self, from: Data(json.utf8))
        XCTAssertEqual(product.category.id, "mens-clothing")
        XCTAssertEqual(product.category.symbolName, "tshirt")
        XCTAssertEqual(product.price, Decimal(string: "9180.83"))
    }

    func testApiBaseUrlCanBeOverridden() {
        // Smoke test: the factory accepts an environment override without crashing.
        _ = HTTPCatalogAPI.fromEnvironment(["API_BASE_URL": "http://192.168.1.10:3000/api"])
    }
}
