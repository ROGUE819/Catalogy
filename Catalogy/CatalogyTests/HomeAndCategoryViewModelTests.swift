import XCTest
@testable import Catalogy

@MainActor
final class HomeAndCategoryViewModelTests: XCTestCase {

    func testHomeLoadsFeaturedAndCategories() async {
        let vm = HomeViewModel(api: StubCatalogAPI())
        await vm.load()
        XCTAssertEqual(vm.featured.value?.count, 2)
        XCTAssertEqual(vm.categories.value?.first?.id, "jewelery")
    }

    func testHomeSurfacesErrors() async {
        let api = StubCatalogAPI()
        api.error = APIError.network
        let vm = HomeViewModel(api: api)
        await vm.load()
        guard case .failed(let message) = vm.featured else { return XCTFail("expected failure") }
        XCTAssertEqual(message, APIError.network.errorDescription)
    }

    func testCategoryPageSplitsTopRatedAndOthers() async {
        let vm = CategoryViewModel(category: .init(id: "jewelery", name: "Jewelery"), api: StubCatalogAPI())
        await vm.load()
        XCTAssertEqual(vm.state.value?.topRated.map(\.id), ["1"])
        XCTAssertEqual(vm.state.value?.others.map(\.id), ["2"])
    }
}
