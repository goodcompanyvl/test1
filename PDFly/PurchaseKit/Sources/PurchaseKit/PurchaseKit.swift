import SwiftUI
import ApphudSDK

public struct PurchaseKit<Splash: View, Onboarding: View, Paywall: View, Content: View>: Scene {
    private let apiKey: String
    private let placementId: String?
    private let theme: AppTheme
    private let successConfig: PurchaseSuccessConfig
    private let splash: () -> Splash
    private let onboarding: (OnboardingConfig) -> Onboarding
    private let paywall: (PaywallContext) -> Paywall
    private let content: () -> Content
    
    @MainActor
    public init(
        apiKey: String,
        placementId: String? = nil,
        theme: AppTheme = .system,
        successConfig: PurchaseSuccessConfig = PurchaseSuccessConfig(),
        @ViewBuilder splash: @escaping () -> Splash,
        @ViewBuilder onboarding: @escaping (OnboardingConfig) -> Onboarding,
        @ViewBuilder paywall: @escaping (PaywallContext) -> Paywall,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.apiKey = apiKey
        self.placementId = placementId
        self.theme = theme
        self.successConfig = successConfig
        self.splash = splash
        self.onboarding = onboarding
        self.paywall = paywall
        self.content = content
        
        PurchaseKitState.shared.apiKey = apiKey
        PurchaseKitState.shared.placementId = placementId
        PurchaseKitState.shared.theme = theme
        PurchaseKitState.shared.successConfig = successConfig
    }
    
    public var body: some Scene {
        WindowGroup {
            PurchaseContainerView(
                splash: splash,
                onboarding: onboarding,
                paywall: paywall,
                content: content
            )
        }
    }
}

@MainActor
public enum PurchaseKitAPI {
    
    public static var hasPremiumAccess: Bool {
        Apphud.hasPremiumAccess()
        }
    
    public static func showPaywall() {
        PurchaseKitState.shared.showPaywallRequested = true
    }
    
    public static func restorePurchases() async -> Bool {
        await Apphud.restorePurchases()
        return Apphud.hasPremiumAccess()
    }
    
    public static func requestReview() {
        PurchaseKitState.shared.requestReview()
    }
}
