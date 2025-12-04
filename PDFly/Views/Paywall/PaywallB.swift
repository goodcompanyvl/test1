import SwiftUI
import PurchaseKit
import ApphudSDK

struct PaywallB: View {
    let context: PaywallContext
    @State private var isLoading = false
    @State private var animate = false
    @State private var trialEnabled = false
    
    var productWithTrial: ApphudProduct? {
        context.product(containing: "trial")
    }
    
    var productWithoutTrial: ApphudProduct? {
        context.product(containing: "without")
    }
    
    var selectedProduct: ApphudProduct? {
        trialEnabled ? productWithTrial : productWithoutTrial
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                HStack(spacing: -30) {
                    SmallPhoneWithSuccess()
                    SmallPhoneWithList()
                }
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animate)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("PDF - Converter")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Instant PDF Maker")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color(hex: "E53935"))
                    
                    Text(trialEnabled
                         ? "Upgrade to PRO $5.99/week + 3-day trial"
                         : "Upgrade to PRO $5.99/week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.2), value: trialEnabled)
                }
                
                TrialToggle(isOn: $trialEnabled)
                    .padding(.vertical, 20)
                
                Button {
                    Task {
                        isLoading = true
                        if let product = selectedProduct ?? context.products.first {
                            await context.purchase(product)
                        }
                        isLoading = false
                    }
                } label: {
                    ZStack {
                        Text(trialEnabled ? "Start free trial" : "Continue")
                            .opacity(isLoading ? 0 : 1)
                        if isLoading { ProgressView().tint(.white) }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "E53935"), in: RoundedRectangle(cornerRadius: 16))
                    .animation(.easeInOut(duration: 0.2), value: trialEnabled)
                }
                .disabled(isLoading)
                .padding(.horizontal, 24)
                
                HStack(spacing: 20) {
                    Button("Terms of Service") {}
                    Button("Privacy Policy") {}
                    Button("Restore Purchase") {
                        Task { await context.restore() }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 12)
                
                Button {
                    context.dismiss()
                } label: {
                    Text("Continue without upgrading")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .onAppear { animate = true }
    }
}

private struct TrialToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Capsule()
                        .fill(isOn ? Color(hex: "E53935") : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 30)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        .offset(x: isOn ? 10 : -10)
                }
                
                Text(isOn ? "3 days free trial enabled" : "Enable 3 days free trial")
                    .font(.subheadline)
                    .foregroundStyle(isOn ? Color(hex: "E53935") : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SmallPhoneWithSuccess: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "2C2C2C"))
                .frame(width: 140, height: 280)
            
            VStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.3))
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.green)
                
                Text("Successfully")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                
                Text("ent conversion was performed")
                    .font(.system(size: 6))
                    .foregroundStyle(.white.opacity(0.5))
                
                Text("Open Preview")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "E53935"), in: Capsule())
                
                Text("Cancel")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 15, y: 8)
    }
}

private struct SmallPhoneWithList: View {
    var body: some View {
		ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "F8F8F8"))
                .frame(width: 140, height: 280)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Aug 20, Today")
                    .font(.system(size: 6))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
                
				ForEach(
					[
						"Doc 123",
						"Doc 4",
						"Doc 111",
						"Doc 7.1",
						"Doc 7"
					],
					id: \.self
				) { name in
                    MiniDocRow(name: name)
                }
            }
            .padding(8)
        }
        .shadow(color: .black.opacity(0.1), radius: 15, y: 8)
    }
}

private struct MiniDocRow: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 25) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "E8E8E8"))
                .frame(width: 20, height: 24)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 7, weight: .medium))
                Text("14:20 pm, Scan File")
                    .font(.system(size: 5))
                    .foregroundStyle(.secondary)
            }
            
        }
        .padding(4)
    }
}

private struct RedPageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color(hex: "E53935") : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1)
            }
        }
    }
}

#Preview {
    PaywallB(context: .init())
}
