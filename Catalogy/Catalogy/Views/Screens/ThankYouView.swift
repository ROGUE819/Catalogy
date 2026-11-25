import SwiftUI

struct ThankYouView: View {
    let message: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: true)
            VStack(spacing: Theme.Spacing.s) {
                Text("Thank you!").font(.title.weight(.bold))
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button(action: onDone) {
                Text("Continue browsing").font(.headline).frame(maxWidth: .infinity).frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: Theme.Radius.m))
        }
        .padding(Theme.Spacing.l)
        .accessibilityIdentifier("thankYouMessage")
    }
}
