import SwiftUI

struct FormatIconView: View {
    let formatName: String
    let color: Color
    var size: CGFloat = 60
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.133)
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            
            VStack(spacing: 2) {
                Text(formatName)
                    .font(.system(size: size * 0.167, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color, in: RoundedRectangle(cornerRadius: 4))
                
				HStack(spacing: 0) {
					Text("PDF")
						.font(.system(size: size * 0.15, weight: .bold))

					Image(systemName: "arrow.turn.down.left")
						.font(.system(size: size * 0.2, weight: .medium))
						.foregroundStyle(color)
				}
            }
        }
    }
}

#Preview("Formats Grid") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        FormatIconView(formatName: "DOCX", color: Color(hex: "E53935"))
        FormatIconView(formatName: "PDF", color: Color(hex: "E53935"))
        FormatIconView(formatName: "PNG", color: Color(hex: "FF5252"))
        FormatIconView(formatName: "JPG", color: Color(hex: "F44336"))
        FormatIconView(formatName: "TXT", color: Color(hex: "E57373"))
        FormatIconView(formatName: "XLSX", color: Color(hex: "4CAF50"))
    }
    .padding()
}

#Preview("Sizes") {
    HStack(spacing: 20) {
        FormatIconView(formatName: "PDF", color: Color(hex: "E53935"), size: 40)
        FormatIconView(formatName: "PDF", color: Color(hex: "E53935"), size: 60)
        FormatIconView(formatName: "PDF", color: Color(hex: "E53935"), size: 90)
    }
    .padding()
}



