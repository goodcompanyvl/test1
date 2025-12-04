import Foundation

public struct OnboardingConfig {
    public let onboardingId: Int
    public let variationName: String
    public let json: [String: Any]?
    public let finish: () -> Void
    
    public init(onboardingId: Int, variationName: String, json: [String: Any]?, finish: @escaping () -> Void) {
        self.onboardingId = onboardingId
        self.variationName = variationName
        self.json = json
        self.finish = finish
    }
}

