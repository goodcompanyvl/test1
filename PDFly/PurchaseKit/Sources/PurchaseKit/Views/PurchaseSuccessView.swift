import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let swayAmount: CGFloat
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var animate = false
    
    let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .cyan
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.6)
                        .rotationEffect(.degrees(animate ? piece.rotation + 720 : piece.rotation))
                        .position(
                            x: piece.x + (animate ? piece.swayAmount : 0),
                            y: animate ? geometry.size.height + 100 : piece.y
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeIn(duration: piece.duration).delay(piece.delay),
                            value: animate
                        )
                }
            }
            .onAppear {
                createPieces(in: geometry.size)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animate = true
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createPieces(in size: CGSize) {
        pieces = (0..<120).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -200...(-20)),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.8),
                duration: Double.random(in: 2.5...4.0),
                swayAmount: CGFloat.random(in: -40...40)
            )
        }
    }
}

public struct PurchaseSuccessView: View {
    @Binding var isPresented: Bool
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var iconScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    
    let accentColor: Color
    let title: String
    let subtitle: String
    let features: [(icon: String, text: String)]
    let buttonTitle: String
    
    public init(
        isPresented: Binding<Bool>,
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
        self._isPresented = isPresented
        self.accentColor = accentColor
        self.title = title
        self.subtitle = subtitle
        self.features = features
        self.buttonTitle = buttonTitle
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(iconScale)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(checkmarkOpacity)
                }
                
                VStack(spacing: 12) {
                    Text(title)
                        .font(.title.weight(.bold))
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(features.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            Image(systemName: features[index].icon)
                                .font(.system(size: 18))
                                .foregroundStyle(accentColor)
                                .frame(width: 28)
                            
                            Text(features[index].text)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.vertical, 20)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Button {
                    dismissWithAnimation()
                } label: {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentColor, in: RoundedRectangle(cornerRadius: 14))
                }
                .opacity(showContent ? 1 : 0)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.regularMaterial)
            )
            .padding(.horizontal, 24)
            .scaleEffect(showContent ? 1 : 0.8)
            
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            iconScale = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                checkmarkOpacity = 1
            }
            showConfetti = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.2)) {
            showContent = false
            iconScale = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

#Preview("Success View") {
    PurchaseSuccessView(isPresented: .constant(true))
}

#Preview("Confetti Only") {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView()
    }
}

#Preview("Success with Red Accent") {
    PurchaseSuccessView(
        isPresented: .constant(true),
        accentColor: .red,
        title: "Welcome to Premium!",
        subtitle: "All features are now unlocked",
        features: [
            ("infinity", "Unlimited conversions"),
            ("doc.on.doc.fill", "All formats supported"),
            ("text.viewfinder", "OCR text recognition")
        ],
        buttonTitle: "Start Using"
    )
}
