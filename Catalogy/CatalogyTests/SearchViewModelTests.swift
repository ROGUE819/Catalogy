import XCTest
@testable import Catalogy

@MainActor
final class SearchViewModelTests: XCTestCase {

    func testSearchTrimsTermAndOnlyShowsMatches() async {
        let api = StubCatalogAPI()
        let vm = SearchViewModel(api: api)
        vm.term = "  gold "
        await vm.search()
        XCTAssertEqual(api.searchedTerms, ["gold"])
        XCTAssertEqual(vm.results.value?.map(\.id), ["1"])
        XCTAssertTrue(vm.isShowingResults)
    }

    func testSearchIgnoresBlankTerm() async {
        let api = StubCatalogAPI()
        let vm = SearchViewModel(api: api)
        vm.term = "   "
        XCTAssertFalse(vm.canSearch)
        await vm.search()
        XCTAssertTrue(api.searchedTerms.isEmpty)
    }

    func testClearResetsState() async {
        let vm = SearchViewModel(api: StubCatalogAPI())
        vm.term = "gold"
        await vm.search()
        vm.clear()
        XCTAssertEqual(vm.term, "")
        XCTAssertFalse(vm.isShowingResults)
    }

    func testFailureIsSurfacedAsMessage() async {
        let api = StubCatalogAPI()
        api.error = APIError.offline
        let vm = SearchViewModel(api: api)
        vm.term = "gold"
        await vm.search()
        guard case .failed(let message) = vm.results else { return XCTFail("expected failure") }
        XCTAssertTrue(message.contains("offline"))
    }

    func testOverlongTermIsTruncatedToBackendLimit() async {
        let api = StubCatalogAPI()
        let vm = SearchViewModel(api: api)
        vm.term = String(repeating: "a", count: 500)
        await vm.search()
        XCTAssertEqual(api.searchedTerms.first?.count, SearchViewModel.maxTermLength)
    }

    func testNoMatchesYieldsEmptyLoadedResult() async {
        let vm = SearchViewModel(api: StubCatalogAPI())
        vm.term = "zzz"
        await vm.search()
        XCTAssertEqual(vm.results.value?.isEmpty, true)
    }
}
