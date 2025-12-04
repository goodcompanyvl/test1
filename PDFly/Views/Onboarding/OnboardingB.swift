import SwiftUI
import PurchaseKit

struct OnboardingB: View {
    let config: OnboardingConfig
    @State private var currentPage = 0
    @State private var showTiles = false
    
    private let pages: [(image: String, title: String, subtitle: String, description: String)] = [
        ("1", "Instant PDF Maker", "PDF - Converter", "Effortlessly change files into PDFs\nEnjoy fast and simple file conversion"),
        ("2", "Docs to PDF Fast", "PDF - Converter", "Convert images and docs to PDFs fast\nExperience smooth and easy conversion"),
        ("3", "Quick PDF Creation", "PDF - Converter", "Fast conversion of files to PDF format\nConvert, save, and share files easily")
    ]
    
    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    GeometryReader { geo in
                        if index == 2 {
                            VStack(spacing: 0) {
                                FeatureTilesGrid(showTiles: showTiles)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 40)
                                
                                Image(pages[index].image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geo.size.width * 0.85)
									.offset(y: -30)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        } else {
                            Image(pages[index].image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geo.size.width * 0.85)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                .padding(.top, 60)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            VStack(spacing: 0) {
                Spacer()
                
                BottomPanel(
                    subtitle: pages[currentPage].subtitle,
                    title: pages[currentPage].title,
                    description: pages[currentPage].description,
                    currentPage: currentPage,
                    onContinue: {
                        if currentPage < 2 {
                            withAnimation { currentPage += 1 }
                        } else {
                            config.finish()
                        }
                    }
                )
            }
        }
        .onChange(of: currentPage) { newValue in
            if newValue == 2 {
                showTiles = false
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    showTiles = true
                }
            }
        }
    }
}

private struct FeatureTilesGrid: View {
    let showTiles: Bool
    
    private let features: [(icon: String, title: String)] = [
        ("link", "URL to PDF"),
        ("text.alignleft", "Text to PDF"),
        ("doc.on.doc", "Merge PDF"),
        ("signature", "Add Signature")
    ]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                FeatureTile(icon: feature.icon, title: feature.title)
                    .opacity(showTiles ? 1 : 0)
                    .offset(y: showTiles ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: showTiles)
            }
        }
    }
}

private struct FeatureTile: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "E53935"))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E53935"), lineWidth: 1.5)
        )
    }
}

private struct BottomPanel: View {
    let subtitle: String
    let title: String
    let description: String
    let currentPage: Int
    let onContinue: () -> Void
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                WavyEdge(phase: phase)
                    .fill(Color.white)
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text(subtitle)
                        .font(.system(size: 26, weight: .bold))
                    
                    Text(title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(hex: "E53935"))
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    RedPageIndicator(currentPage: currentPage, totalPages: 3)
                        .padding(.top, 8)
                    
                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "E53935"), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
                .background(Color.white)
            }
            
            WavyLine(phase: phase)
                .stroke(Color(hex: "E53935"), lineWidth: 2.5)
                .frame(height: 30)
                .shadow(color: Color(hex: "E53935").opacity(0.9), radius: 8)
                .shadow(color: Color(hex: "E53935").opacity(0.6), radius: 16)
                .shadow(color: Color(hex: "E53935").opacity(0.3), radius: 24)
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
        .onChange(of: currentPage) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                phase += .pi * 2
            }
        }
    }
}

private struct WavyEdge: Shape {
    var phase: CGFloat = 0
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.5))
        
        let wavelength = width / 3
        let amplitude: CGFloat = 6
        
        var x: CGFloat = 0
        while x <= width {
            let y = (height * 0.5) + sin((x / wavelength * .pi * 2) + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}

private struct WavyLine: Shape {
    var phase: CGFloat = 0
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        let wavelength = width / 3
        let amplitude: CGFloat = 6
        
        path.move(to: CGPoint(x: 0, y: (height * 0.5) + sin(phase) * amplitude))
        
        var x: CGFloat = 0
        while x <= width {
            let y = (height * 0.5) + sin((x / wavelength * .pi * 2) + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }
        
        return path
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
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }
}

#Preview {
		OnboardingB(
		config: .init(
			onboardingId: 1,
			variationName: "",
			json: [:],
			finish: {}
		)
	)
}

#Preview("Bottom Panel Only") {
    VStack {
        Spacer()
        BottomPanel(
            subtitle: "PDF - Converter",
            title: "Instant PDF Maker",
            description: "Effortlessly change files into PDFs\nEnjoy fast and simple file conversion",
            currentPage: 0,
            onContinue: {}
        )
    }
    .background(Color.gray)
}
