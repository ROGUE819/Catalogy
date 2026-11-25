import SwiftUI

/// Composition root for the UI: the only place that chooses the concrete API client.
/// Shows the splash briefly while the home screen starts loading underneath.
struct ContentView: View {
    private let api: CatalogAPI
    private let splashDuration: Duration
    @State private var showingSplash = true

    init(api: CatalogAPI = HTTPCatalogAPI.fromEnvironment(),
         splashDuration: Duration = ProcessInfo.processInfo.arguments.contains("-skipSplash") ? .zero : .seconds(1.2)) {
        self.api = api
        self.splashDuration = splashDuration
    }

    var body: some View {
        ZStack {
            HomeView(api: api)
            if showingSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.08)))
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: splashDuration)
            withAnimation(.easeOut(duration: 0.35)) { showingSplash = false }
        }
    }
}

#Preview {
    ContentView()
}
