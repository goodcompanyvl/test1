import SwiftUI
import PurchaseKit

@main
struct PDFlyApp: App {
    
    init() {
        Task {
            await CloudConvertService.shared.configure(apiKey: AppConfig.cloudConvertAPIKey)
        }
    }
    
    var body: some Scene {
        PurchaseKit(
            apiKey: AppConfig.apphudAPIKey,
            theme: .light,
            successConfig: PurchaseSuccessConfig(
                accentColor: Color(hex: "E53935"),
                title: "Welcome to Premium!",
                subtitle: "All features are now unlocked",
                features: [
                    ("infinity", "Unlimited conversions"),
                    ("doc.on.doc.fill", "All formats supported"),
                    ("text.viewfinder", "OCR text recognition"),
                    ("wand.and.stars", "Advanced editing")
                ],
                buttonTitle: "Start Using"
            ),
            splash: {
                SplashView()
            },
            onboarding: { config in
                switch config.onboardingId {
                default: OnboardingB(config: config)
                }
            },
            paywall: { context in
                switch context.onboardingId {
                default: PaywallB(context: context)
                }
            }
        ) {
            ContentView()
        }
    }
}
