import XCTest

/// End-to-end happy path. Requires the backend running on 127.0.0.1:3000.
final class CatalogyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testBrowseSearchAndEnquire() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-skipSplash"]
        app.launch()

        // Home shows featured products
        XCTAssertTrue(app.staticTexts["Top rated"].waitForExistence(timeout: 15))

        // Search
        let field = app.textFields["searchField"]
        field.tap()
        field.typeText("backpack")
        app.buttons["searchButton"].tap()

        let tile = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'productTile_'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()

        // Product detail -> enquiry
        app.buttons["enquireButton"].tap()
        let name = app.textFields["nameField"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("UI Test")
        let email = app.textFields["emailField"]
        email.tap()
        email.typeText("ui@example.com")
        app.buttons["submitEnquiryButton"].tap()

        XCTAssertTrue(app.staticTexts["Thank you!"].waitForExistence(timeout: 10))
    }
}
