import SwiftUI
import PurchaseKit

struct OnboardingA: View {
    let config: OnboardingConfig
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "E8F4FD"), Color(hex: "D6EBFA")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    ImportPage()
                        .tag(1)
                    EditPage()
                        .tag(2)
                    ExportPage()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                PageIndicator(currentPage: currentPage, totalPages: 4)
                    .padding(.bottom, 24)
                
                Button {
                    if currentPage < 3 {
                        withAnimation { currentPage += 1 }
                    } else {
                        config.finish()
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "7EB6FF"), Color(hex: "5B9FE8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: .capsule
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct WelcomePage: View {
    @State private var animate = false
    
    private let icons: [(String, Color, CGFloat, CGFloat)] = [
        ("doc.text.fill", Color(hex: "4285F4"), -100, -120),
        ("doc.richtext.fill", Color(hex: "FF6B35"), 100, -100),
        ("photo.fill", Color(hex: "34A853"), -110, 20),
        ("tablecells.fill", Color(hex: "0F9D58"), 110, 0),
        ("lock.fill", Color(hex: "00BCD4"), -80, 120),
        ("arrow.triangle.2.circlepath", Color(hex: "5C6BC0"), 90, 110),
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                ForEach(0..<icons.count, id: \.self) { index in
                    let icon = icons[index]
                    IconBubble(systemName: icon.0, color: icon.1)
                        .offset(
                            x: animate ? icon.2 : icon.2 * 0.3,
                            y: animate ? icon.3 : icon.3 * 0.3
                        )
                        .opacity(animate ? 1 : 0)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6)
                            .delay(Double(index) * 0.1),
                            value: animate
                        )
                }
                
                MainPDFIcon()
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
            }
            .frame(height: 300)
            
            Spacer()
            
            Text("Welcome to use\nPDF Converter")
                .font(.system(size: 28, weight: .semibold))
                .multilineTextAlignment(.center)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
            
            Spacer()
        }
        .onAppear { animate = true }
    }
}

private struct ImportPage: View {
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                PhoneMockup {
                    ImportScreenContent()
                }
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
                
                VStack(spacing: 16) {
                    FloatingButton(icon: "icloud.fill", label: "iCloud", color: Color(hex: "5AC8FA"))
                        .offset(x: 100, y: -80)
                    FloatingButton(icon: "photo.fill", label: "Gallery", color: Color(hex: "5AC8FA"))
                        .offset(x: 110, y: 0)
                    FloatingButton(icon: "camera.fill", label: "Camera", color: Color(hex: "5AC8FA"))
                        .offset(x: 100, y: 80)
                    FloatingButton(icon: "square.grid.2x2.fill", label: "Other Apps", color: Color(hex: "5AC8FA"))
                        .offset(x: 90, y: 160)
                }
                .opacity(animate ? 1 : 0)
                .offset(x: animate ? 0 : 50)
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: animate)
            
            Spacer()
            
            Text("Import or Scan")
                .font(.system(size: 28, weight: .semibold))
                .opacity(animate ? 1 : 0)
                .animation(.easeOut.delay(0.4), value: animate)
            
            Spacer()
        }
        .onAppear { animate = true }
    }
}

private struct EditPage: View {
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                PhoneMockup {
                    EditScreenContent()
                }
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
                .rotation3DEffect(.degrees(animate ? 0 : 15), axis: (x: 0, y: 1, z: 0))
                
                SettingsCard()
                    .offset(x: 60, y: 40)
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 1 : 0)
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: animate)
            
            Spacer()
            
            Text("Edit & Settings")
                .font(.system(size: 28, weight: .semibold))
                .opacity(animate ? 1 : 0)
                .animation(.easeOut.delay(0.4), value: animate)
            
            Spacer()
        }
        .onAppear { animate = true }
    }
}

private struct ExportPage: View {
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                PhoneMockup {
                    ExportScreenContent()
                }
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
                
                ShareButtons()
                    .offset(x: 100)
                    .opacity(animate ? 1 : 0)
                    .offset(x: animate ? 0 : 30)
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: animate)
            
            Spacer()
            
            Text("Export & Share")
                .font(.system(size: 28, weight: .semibold))
                .opacity(animate ? 1 : 0)
                .animation(.easeOut.delay(0.4), value: animate)
            
            Spacer()
        }
        .onAppear { animate = true }
    }
}

private struct IconBubble: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 24))
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(color, in: .circle)
            .shadow(color: color.opacity(0.4), radius: 8, y: 4)
    }
}

private struct MainPDFIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            
            VStack(spacing: 4) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: "EA4335"))
                Text("PDF")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "EA4335"))
            }
        }
    }
}

private struct PhoneMockup<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(.black)
                .frame(width: 180, height: 360)
            
            RoundedRectangle(cornerRadius: 28)
                .fill(.white)
                .frame(width: 168, height: 348)
            
            content
                .frame(width: 160, height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }
}

private struct FloatingButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color, in: .circle)
                .shadow(color: color.opacity(0.4), radius: 6, y: 3)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct ImportScreenContent: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "xmark")
                    .font(.caption2)
                Spacer()
                Text("Select")
                    .font(.caption2.bold())
                Spacer()
                Text("Next")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "5AC8FA"), in: .capsule)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                ForEach(0..<9) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(4)
            
            Spacer()
        }
        .background(Color(hex: "F5F5F5"))
    }
}

private struct EditScreenContent: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay {
                    VStack {
                        Text("CPR")
                            .font(.system(size: 12, weight: .bold))
                        Text("Method")
                            .font(.system(size: 8))
                    }
                }
            
            Spacer()
        }
        .background(.white)
    }
}

private struct SettingsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Set Password")
                    .font(.system(size: 10))
                Spacer()
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 20, height: 10)
            }
            
            HStack {
                Text("Margins")
                    .font(.system(size: 10))
                Spacer()
                Text("None")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Quality")
                    .font(.system(size: 10))
                Spacer()
                Text("100%")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 120)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

private struct ExportScreenContent: View {
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<3) { _ in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 50)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(height: 8)
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 6)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding(8)
            }
            Spacer()
        }
        .padding(.top, 20)
        .background(.white)
    }
}

private struct ShareButtons: View {
    var body: some View {
        VStack(spacing: 12) {
            ShareIcon(icon: "mic.fill", color: .gray)
            ShareIcon(icon: "antenna.radiowaves.left.and.right", color: Color(hex: "5AC8FA"))
            ShareIcon(icon: "envelope.fill", color: Color(hex: "34C759"))
            ShareIcon(icon: "message.fill", color: Color(hex: "5AC8FA"))
        }
    }
}

private struct ShareIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(color, in: .circle)
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
    }
}

private struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color(hex: "5B9FE8") : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


