import SwiftUI

/// Renders a `Loadable` with consistent loading and error UI.
struct LoadableView<Value, Content: View, Placeholder: View>: View {
    let state: Loadable<Value>
    let retry: () async -> Void
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            placeholder()
        case .failed(let message):
            ErrorStateView(message: message, retry: retry)
        case .loaded(let value):
            content(value)
        }
    }
}

extension LoadableView where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(state: Loadable<Value>, retry: @escaping () async -> Void, @ViewBuilder content: @escaping (Value) -> Content) {
        self.init(state: state, retry: retry, placeholder: { ProgressView() }, content: content)
    }
}
