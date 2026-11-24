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

    func testPhoneAndMessageValidation() {
        let vm = makeViewModel()
        vm.name = "Ada"
        vm.email = "ada@example.com"
        vm.phone = "+91 (98) 765-43210"
        XCTAssertNil(vm.phoneError)
        vm.phone = "call me"
        XCTAssertNotNil(vm.phoneError)
        XCTAssertFalse(vm.canSubmit)
        vm.phone = ""
        vm.message = String(repeating: "x", count: EnquiryViewModel.maxMessageLength + 1)
        XCTAssertNotNil(vm.messageError)
        XCTAssertFalse(vm.canSubmit)
    }

    func testWhitespaceOnlyOptionalFieldsAreSentAsNil() async {
        let api = StubCatalogAPI()
        let vm = makeViewModel(api: api)
        vm.name = "Ada"
        vm.email = " ada@example.com "
        vm.phone = "   "
        vm.message = "\n  \n"
        await vm.submit()
        XCTAssertEqual(api.submittedEnquiries.first?.phone, nil)
        XCTAssertEqual(api.submittedEnquiries.first?.message, nil)
        XCTAssertEqual(api.submittedEnquiries.first?.email, "ada@example.com")
    }

    func testCannotSubmitTwiceAfterSuccess() async {
        let api = StubCatalogAPI()
        let vm = makeViewModel(api: api)
        vm.name = "Ada"
        vm.email = "ada@example.com"
        await vm.submit()
        await vm.submit()
        XCTAssertEqual(api.submittedEnquiries.count, 1)
    }

    func testEmailEdgeCases() {
        XCTAssertFalse(EnquiryViewModel.isValidEmail(""))
        XCTAssertFalse(EnquiryViewModel.isValidEmail("a@b"))
        XCTAssertFalse(EnquiryViewModel.isValidEmail("a b@c.com"))
        XCTAssertTrue(EnquiryViewModel.isValidEmail("  first.last+tag@shop.co.in "))
    }
}
