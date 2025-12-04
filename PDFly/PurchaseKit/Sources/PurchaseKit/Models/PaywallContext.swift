import Foundation
import ApphudSDK

public struct PaywallContext {
    public let products: [ApphudProduct]
    public let variationName: String
    public let onboardingId: Int
    public let json: [String: Any]?
    public let purchase: (ApphudProduct) async -> Bool
    public let restore: () async -> Bool
    public let dismiss: () -> Void
    
    public func product(withId id: String) -> ApphudProduct? {
        products.first { $0.productId == id }
    }
    
    public func product(containing substring: String) -> ApphudProduct? {
        products.first { $0.productId.contains(substring) }
    }
    
    public init(
        products: [ApphudProduct] = [],
        variationName: String = "",
        onboardingId: Int = 0,
        json: [String: Any]? = nil,
        purchase: @escaping (ApphudProduct) async -> Bool = { _ in false },
        restore: @escaping () async -> Bool = { false },
        dismiss: @escaping () -> Void = {}
    ) {
        self.products = products
        self.variationName = variationName
        self.onboardingId = onboardingId
        self.json = json
        self.purchase = purchase
        self.restore = restore
        self.dismiss = dismiss
    }
}
