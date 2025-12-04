import SwiftUI
import PurchaseKit

struct OnboardingD: View {
    let config: OnboardingConfig
    
    var body: some View {
        ZStack {
            Color.purple.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Text("Onboarding D")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Variation: \(config.variationName)")
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button {
                    config.finish()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white, in: .capsule)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}





