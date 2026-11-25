import XCTest
@testable import Catalogy

final class FormattingAndErrorTests: XCTestCase {

    func testRupeePricesUseSymbolAndIndianGrouping() {
        let formatted = Product.formatPrice(Decimal(string: "123456.5")!, currency: "INR")
        XCTAssertTrue(formatted.hasPrefix("₹"), formatted)
        XCTAssertTrue(formatted.contains("1,23,456.50"), formatted)
    }

    func testFixtureProductFormatsInRupees() {
        XCTAssertTrue(Product.fixture(id: "1", title: "Ring").formattedPrice.contains("₹"))
    }

    func testErrorsHaveUserFacingMessages() {
        let cases: [APIError] = [.network, .offline, .timeout, .rateLimited, .notFound, .decoding, .server("Boom")]
        for error in cases {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "\(error)")
        }
        XCTAssertEqual(APIError.validation([.init(field: "email", message: "Bad email")]).errorDescription, "Bad email")
    }

    func testIdsArePercentEncodedInPaths() {
        XCTAssertEqual(HTTPCatalogAPI.pathSegment("mens-clothing"), "mens-clothing")
        XCTAssertFalse(HTTPCatalogAPI.pathSegment("../admin").contains("/"))
        XCTAssertFalse(HTTPCatalogAPI.pathSegment("1?x=2").contains("?"))
    }
}
