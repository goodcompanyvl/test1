import SwiftUI

struct SplashView: View {
    @State private var scale1 = 0.5
    @State private var scale2 = 0.3
    @State private var scale3 = 0.1
    @State private var opacity1 = 0.0
    @State private var opacity2 = 0.0
    @State private var opacity3 = 0.0
    @State private var iconScale = 0.0
    @State private var ringRotation = 0.0
    
    private let mainRed = Color(red: 229/255, green: 57/255, blue: 53/255)
    
    var body: some View {
        ZStack {
            Color(red: 245/255, green: 245/255, blue: 245/255).ignoresSafeArea()
            
            Circle()
                .stroke(mainRed.opacity(0.1), lineWidth: 2)
                .frame(width: 280, height: 280)
                .scaleEffect(scale1)
                .opacity(opacity1)
            
            Circle()
                .stroke(mainRed.opacity(0.2), lineWidth: 3)
                .frame(width: 200, height: 200)
                .scaleEffect(scale2)
                .opacity(opacity2)
            
            Circle()
                .stroke(mainRed.opacity(0.3), lineWidth: 4)
                .frame(width: 120, height: 120)
                .scaleEffect(scale3)
                .opacity(opacity3)
            
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        AngularGradient(
                            colors: [mainRed, mainRed.opacity(0.5), mainRed.opacity(0)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(ringRotation))
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(
                        AngularGradient(
                            colors: [mainRed.opacity(0.8), mainRed.opacity(0.3), mainRed.opacity(0)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-ringRotation * 1.5))
            }
            
            Image(systemName: "doc.fill")
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(mainRed)
                .scaleEffect(iconScale)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                iconScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                scale3 = 1.0
                opacity3 = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                scale2 = 1.0
                opacity2 = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                scale1 = 1.0
                opacity1 = 1.0
            }
            
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
    }
}
