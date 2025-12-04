import SwiftUI
import StoreKit
import PurchaseKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showClearHistoryAlert = false
    @ObservedObject private var subscription = PurchaseKitSubscription.shared
    
    var previewPremiumOverride: Bool?
    
    private var hasPremium: Bool {
        previewPremiumOverride ?? subscription.isPremium
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if hasPremium {
                        premiumActiveCard
                    } else {
                        subscriptionCard
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section("Support") {
                    SettingsRow(icon: "envelope.fill", title: "Contact Support", color: .blue) {
                        openEmail()
                    }
                    
                    SettingsRow(icon: "star.fill", title: "Rate App", color: .yellow) {
                        requestReview()
                    }
                    
                    SettingsRow(icon: "square.and.arrow.up.fill", title: "Share App", color: .green) {
                        shareApp()
                    }
                }
                
                Section("Legal") {
                    SettingsRow(icon: "doc.text.fill", title: "Privacy Policy", color: .gray) {
                        openURL("https://yourapp.com/privacy")
                    }
                    
                    SettingsRow(icon: "doc.text.fill", title: "Terms of Use", color: .gray) {
                        openURL("https://yourapp.com/terms")
                    }
                }
                
                Section("Data") {
                    SettingsRow(icon: "trash.fill", title: "Clear History", color: .red) {
                        showClearHistoryAlert = true
                    }
                }
                
                Section {
                    VStack(spacing: 4) {
                        Text("PDF Converter")
                            .font(.subheadline.weight(.medium))
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert("Clear History", isPresented: $showClearHistoryAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    HistoryManager.shared.clearHistory()
                }
            } message: {
                Text("Are you sure you want to clear all conversion history? This action cannot be undone.")
            }
        }
    }
    
    private var subscriptionCard: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                PurchaseKitAPI.showPaywall()
            }
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.yellow)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Go Premium")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("Unlock all features")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                VStack(spacing: 0) {
                    PremiumFeatureLine(text: "Unlimited conversions", isFirst: true, isLast: false)
                    PremiumFeatureLine(text: "All formats available", isFirst: false, isLast: false)
                    PremiumFeatureLine(text: "No ads", isFirst: false, isLast: false)
                    PremiumFeatureLine(text: "Priority support", isFirst: false, isLast: true)
                }
                .padding(.leading, 4)
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [Color(hex: "4A9EF7"), Color(hex: "6366F1")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundStyle(.white)
        }
    }
    
    private var premiumActiveCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 36))
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Premium Active")
                    .font(.title3.weight(.bold))
                
                Text("All features unlocked")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "4CAF50"), Color(hex: "2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .foregroundStyle(.white)
        .padding(.vertical, 8)
    }
    
    private func openEmail() {
        if let url = URL(string: "mailto:support@yourapp.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func shareApp() {
        let url = URL(string: "https://apps.apple.com/app/idYOURAPPID")!
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(color, in: RoundedRectangle(cornerRadius: 6))
                
                Text(title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
        .foregroundStyle(.white.opacity(0.9))
    }
}

private struct PremiumFeatureLine: View {
    let text: String
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

#Preview("Free User") {
    SettingsView(previewPremiumOverride: false)
}

#Preview("Premium User") {
    SettingsView(previewPremiumOverride: true)
}

