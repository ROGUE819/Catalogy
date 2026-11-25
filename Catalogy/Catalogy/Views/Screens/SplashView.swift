import SwiftUI

/// Branded splash that picks up seamlessly from the static launch screen
/// (same background colour and logo), then animates into the app.
struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            VStack(spacing: Theme.Spacing.m) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(animate ? 1 : 0.85)
                Text("Catalogy")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 12)
                Text("Find it. Love it. Ask us.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .opacity(animate ? 1 : 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Catalogy")
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.35)) { animate = true }
        }
    }
}

#Preview {
    SplashView()
}
