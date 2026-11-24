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
}
