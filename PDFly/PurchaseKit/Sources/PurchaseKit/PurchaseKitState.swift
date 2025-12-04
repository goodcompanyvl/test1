import SwiftUI
import ApphudSDK
import StoreKit

@MainActor
public final class PurchaseKitSubscription: ObservableObject {
    public static let shared = PurchaseKitSubscription()
    
    @Published public private(set) var isPremium: Bool = false
    
    private init() {
        refresh()
    }
    
    public func refresh() {
        let oldValue = isPremium
        isPremium = Apphud.hasPremiumAccess()
        pkLog("🔄 Refresh premium: \(oldValue) → \(isPremium)")
    }
}

func pkLog(_ message: String) {
    #if DEBUG
    print("[PurchaseKit] \(message)")
    #endif
}

public enum AppTheme {
    case light
    case dark
    case system
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

public struct PurchaseSuccessConfig {
    public let accentColor: Color
    public let title: String
    public let subtitle: String
    public let features: [(icon: String, text: String)]
    public let buttonTitle: String
    
    public init(
        accentColor: Color = .green,
        title: String = "Welcome to Premium!",
        subtitle: String = "All features are now unlocked",
        features: [(icon: String, text: String)] = [
            ("infinity", "Unlimited access"),
            ("star.fill", "Premium features"),
            ("bolt.fill", "Priority support")
        ],
        buttonTitle: String = "Start Using"
    ) {
        self.accentColor = accentColor
        self.title = title
        self.subtitle = subtitle
        self.features = features
        self.buttonTitle = buttonTitle
    }
}

@MainActor
final class PurchaseKitState: ObservableObject {
    static let shared = PurchaseKitState()
    
    var apiKey: String = ""
    var placementId: String? = nil
    var successConfig: PurchaseSuccessConfig = PurchaseSuccessConfig()
    var theme: AppTheme = .system
    
    @Published var showPaywallRequested = false
    @Published var showPurchaseSuccess = false
    @Published var isOnboardingCompleted: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingCompleted, forKey: "PurchaseKit_OnboardingCompleted")
        }
    }
    
    private(set) var currentPaywall: ApphudPaywall?
    private(set) var onboardingId: Int = 0
    private(set) var variationName: String = ""
    private(set) var customJSON: [String: Any]?
    private(set) var products: [ApphudProduct] = []
    
    private init() {
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "PurchaseKit_OnboardingCompleted")
    }
    
    func start() async {
        pkLog("🚀 Starting PurchaseKit...")
        #if DEBUG
        Apphud.enableDebugLogs()
        #endif
        Apphud.start(apiKey: apiKey)
        await fetchPaywall()
        PurchaseKitSubscription.shared.refresh()
        pkLog("✅ PurchaseKit started, isPremium: \(PurchaseKitSubscription.shared.isPremium)")
    }
    
    func fetchPaywall() async {
        pkLog("📥 Fetching placements...")
        await withCheckedContinuation { continuation in
            Apphud.fetchPlacements { placements, error in
                Task { @MainActor in
                    if let error = error {
                        pkLog("❌ Fetch error: \(error.localizedDescription)")
                    }
                    pkLog("📦 Placements received: \(placements.count)")
                    self.processPlacementsResult(placements)
                    continuation.resume()
                }
            }
        }
    }
    
    private func processPlacementsResult(_ placements: [ApphudPlacement]) {
        let placement: ApphudPlacement?
        
        if let id = placementId {
            placement = placements.first(where: { $0.identifier == id }) ?? placements.first
            pkLog("🎯 Looking for placement: \(id)")
        } else {
            placement = placements.first
            pkLog("🎯 Using first available placement")
        }
        
        if let placement = placement, let paywall = placement.paywall {
            pkLog("✅ Found placement: \(placement.identifier)")
            processPaywall(paywall)
        } else {
            pkLog("⚠️ No paywall found in placements")
        }
    }
    
    private func processPaywall(_ paywall: ApphudPaywall) {
        currentPaywall = paywall
        variationName = paywall.variationName ?? ""
        customJSON = paywall.json
        products = paywall.products
        
        pkLog("💰 Paywall loaded: \(paywall.identifier ?? "unknown")")
        pkLog("📝 Variation: \(variationName)")
        pkLog("🛍️ Products: \(products.map { $0.productId })")
        
        if let json = customJSON, let id = json["onboarding_id"] as? Int {
            onboardingId = id
            pkLog("📱 Onboarding ID: \(id)")
        }
    }
    
    func paywallShown() {
        guard let paywall = currentPaywall else { return }
        pkLog("👀 Paywall shown: \(paywall.identifier ?? "unknown")")
        Apphud.paywallShown(paywall)
    }
    
    func paywallClosed() {
        guard let paywall = currentPaywall else { return }
        pkLog("🚪 Paywall closed")
        Apphud.paywallClosed(paywall)
    }
    
    func purchase(_ product: ApphudProduct) async -> Bool {
        pkLog("🛒 Starting purchase: \(product.productId)")
        let result = await Apphud.purchase(product)
        pkLog("💳 Purchase result - success: \(result.success), error: \(result.error?.localizedDescription ?? "none")")
        if result.success {
            pkLog("✅ Purchase successful!")
            PurchaseKitSubscription.shared.refresh()
            showPurchaseSuccess = true
        } else {
            pkLog("❌ Purchase failed")
        }
        return result.success
    }
    
    func requestReview() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
    
    func restore() async -> Bool {
        pkLog("🔄 Restoring purchases...")
        await Apphud.restorePurchases()
        let hasPremium = Apphud.hasPremiumAccess()
        pkLog("🔄 Restore complete, hasPremium: \(hasPremium)")
        PurchaseKitSubscription.shared.refresh()
        if hasPremium {
            showPurchaseSuccess = true
        }
        return hasPremium
    }
    
    func dismissSuccessAndContinue() {
        showPurchaseSuccess = false
        requestReview()
    }
    
    func completeOnboarding() {
        isOnboardingCompleted = true
    }
    
    func resetOnboarding() {
        isOnboardingCompleted = false
    }
}
