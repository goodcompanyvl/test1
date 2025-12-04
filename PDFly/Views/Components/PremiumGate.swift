import SwiftUI
import PurchaseKit

func checkPremiumAccess() -> Bool {
    PurchaseKitSubscription.shared.isPremium
}

struct LockBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(6)
            .background(Color(hex: "E53935"), in: Circle())
            .offset(x: 8, y: -8)
    }
}

enum PremiumFeature {
    case convertToPDF
    case convertFromPDF
    case urlToPDF
    case ocr
    case merge
    case edit
}

struct PremiumButton<Content: View>: View {
    let feature: PremiumFeature
    let action: () -> Void
    let content: () -> Content
    @ObservedObject private var subscription = PurchaseKitSubscription.shared
    
    private var hasPremium: Bool {
        subscription.isPremium
    }
    
    var body: some View {
        Button {
            if hasPremium {
                action()
            } else {
                PurchaseKitAPI.showPaywall()
            }
        } label: {
            content()
                .overlay(alignment: .topTrailing) {
                    if !hasPremium {
                        LockBadge()
                    }
                }
        }
    }
}

#Preview {
    PremiumButton(feature: .convertFromPDF, action: {}) {
        Text("Convert from PDF")
            .padding()
            .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
    }
}

