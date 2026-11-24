import SwiftUI

/// Composition root for the UI: the only place that chooses the concrete API client.
struct ContentView: View {
    private let api: CatalogAPI

    init(api: CatalogAPI = HTTPCatalogAPI.fromEnvironment()) {
        self.api = api
    }

    var body: some View {
        HomeView(api: api)
    }
}

#Preview {
    ContentView()
}
