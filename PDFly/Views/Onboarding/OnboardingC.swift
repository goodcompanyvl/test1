import SwiftUI
import PurchaseKit

struct OnboardingC: View {
    let config: OnboardingConfig
    
    var body: some View {
        ZStack {
            Color.orange.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Text("Onboarding C")
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
                        .foregroundStyle(.orange)
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




