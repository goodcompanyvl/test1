import SwiftUI
import PurchaseKit
import ApphudSDK

struct PaywallC: View {
    let context: PaywallContext
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.orange.opacity(0.1).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Text("Paywall C")
                    .font(.largeTitle.bold())
                
                Text("Variation: \(context.variationName)")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    Task {
                        isLoading = true
                        if let product = context.products.first {
                            _ = await context.purchase(product)
                        }
                        isLoading = false
                    }
                } label: {
                    ZStack {
                        Text("Continue")
                            .opacity(isLoading ? 0 : 1)
                        if isLoading { ProgressView().tint(.white) }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange, in: .capsule)
                }
                .padding(.horizontal, 32)
                
                HStack(spacing: 24) {
                    Button("Terms") {}
                    Button("Privacy") {}
                    Button("Restore") {
                        Task { _ = await context.restore() }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Button {
                    context.dismiss()
                } label: {
                    Text("Continue without upgrading")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .padding(.bottom, 24)
            }
        }
    }
}
