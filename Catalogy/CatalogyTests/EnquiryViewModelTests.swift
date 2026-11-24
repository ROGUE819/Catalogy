import XCTest
@testable import Catalogy

@MainActor
final class EnquiryViewModelTests: XCTestCase {

    private func makeViewModel(api: StubCatalogAPI = StubCatalogAPI()) -> EnquiryViewModel {
        EnquiryViewModel(product: .fixture(id: "1", title: "Ring"), api: api)
    }

    func testValidation() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.canSubmit)
        XCTAssertNotNil(vm.nameError)
        vm.name = "Ada"
        vm.email = "not-an-email"
        XCTAssertNotNil(vm.emailError)
        XCTAssertFalse(vm.canSubmit)
        vm.email = "ada@example.com"
        XCTAssertTrue(vm.canSubmit)
    }

    func testSubmitSendsTrimmedDetailsAndShowsThankYou() async {
        let api = StubCatalogAPI()
        let vm = makeViewModel(api: api)
        vm.name = " Ada "
        vm.email = "ada@example.com"
        await vm.submit()
        XCTAssertEqual(vm.status, .submitted("Thank you!"))
        XCTAssertEqual(api.submittedEnquiries, [
            EnquiryRequest(productId: "1", name: "Ada", email: "ada@example.com", phone: nil, message: nil),
        ])
    }

    func testInvalidFormIsNotSubmitted() async {
        let api = StubCatalogAPI()
        let vm = makeViewModel(api: api)
        await vm.submit()
        XCTAssertTrue(api.submittedEnquiries.isEmpty)
        XCTAssertEqual(vm.status, .editing)
    }

    func testFailureIsShownAndRetryable() async {
        let api = StubCatalogAPI()
        api.error = APIError.server("Email down")
        let vm = makeViewModel(api: api)
        vm.name = "Ada"
        vm.email = "ada@example.com"
        await vm.submit()
        XCTAssertEqual(vm.status, .failed("Email down"))
        XCTAssertTrue(vm.canSubmit)
    }
}
