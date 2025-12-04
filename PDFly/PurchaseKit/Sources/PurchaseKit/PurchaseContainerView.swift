import SwiftUI
import ApphudSDK

struct PurchaseContainerView<Splash: View, Onboarding: View, Paywall: View, Content: View>: View {
    @StateObject private var state = PurchaseKitState.shared
    @State private var phase: PurchasePhase = .loading
    
    let splash: () -> Splash
    let onboarding: (OnboardingConfig) -> Onboarding
    let paywall: (PaywallContext) -> Paywall
    let content: () -> Content
    
    var body: some View {
        ZStack {
            switch phase {
            case .loading:
                splash()
                
            case .onboarding:
                onboarding(makeOnboardingConfig())
                
            case .paywall:
                ZStack {
                    if !state.showPurchaseSuccess {
                        paywall(makePaywallContext())
                            .onAppear { state.paywallShown() }
                            .transition(.opacity)
                    }
                    
                    if state.showPurchaseSuccess {
                        successOverlay
                    }
                }
                
            case .app:
                content()
                    .fullScreenCover(isPresented: $state.showPaywallRequested) {
                        ZStack {
                            if !state.showPurchaseSuccess {
                                paywall(makePaywallContext())
                                    .onAppear { state.paywallShown() }
                                    .transition(.opacity)
                            }
                            
                            if state.showPurchaseSuccess {
                                successOverlay
                            }
                        }
                    }
            }
        }
        .task {
            await startFlow()
        }
        .onChange(of: state.showPurchaseSuccess) { newValue in
            if !newValue {
                state.paywallClosed()
                phase = .app
                state.showPaywallRequested = false
            }
        }
        .preferredColorScheme(state.theme.colorScheme)
    }
    
    private var successOverlay: some View {
        let config = state.successConfig
        return PurchaseSuccessView(
            isPresented: Binding(
                get: { state.showPurchaseSuccess },
                set: { newValue in
                    if !newValue {
                        state.dismissSuccessAndContinue()
                    }
                }
            ),
            accentColor: config.accentColor,
            title: config.title,
            subtitle: config.subtitle,
            features: config.features,
            buttonTitle: config.buttonTitle
        )
    }
    
    private func startFlow() async {
        let timeoutSeconds: UInt64 = 15
        
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                return false
            }
            
            group.addTask {
                await self.state.start()
                return true
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
                print("[PurchaseKit] ⏰ Timeout reached (\(timeoutSeconds)s), proceeding to app")
                return true
            }
            
            var startCompleted = false
            for await isCompletion in group {
                if isCompletion {
                    startCompleted = true
                    group.cancelAll()
                    break
                }
            }
            
            if !startCompleted {
                await group.waitForAll()
            }
        }
        
        if Apphud.hasPremiumAccess() {
            phase = .app
            return
        }
        
        if state.isOnboardingCompleted {
            phase = .app
        } else {
            phase = .onboarding
        }
    }
    
    private func makeOnboardingConfig() -> OnboardingConfig {
        OnboardingConfig(
            onboardingId: state.onboardingId,
            variationName: state.variationName,
            json: state.customJSON,
            finish: {
                phase = .paywall
            }
        )
    }
    
    private func makePaywallContext() -> PaywallContext {
        PaywallContext(
            products: state.products,
            variationName: state.variationName,
            onboardingId: state.onboardingId,
            json: state.customJSON,
            purchase: { product in
                let success = await state.purchase(product)
                if success {
                    state.completeOnboarding()
                }
                return success
            },
            restore: {
                let success = await state.restore()
                if success {
                    state.completeOnboarding()
                }
                return success
            },
            dismiss: {
                state.completeOnboarding()
                phase = .app
                state.showPaywallRequested = false
            }
        )
    }
}
