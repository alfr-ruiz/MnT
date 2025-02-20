import SwiftUI

struct TunerMeterView: View {
    @Binding var isEnabled: Bool
    @State private var needleRotation: Double = 0
    @State private var pressScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("A4")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundColor(.primary)
                Text("0 cents")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(isEnabled ? .secondary : .gray)
            }
            .padding(.bottom, 12)
            
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .rotation(.degrees(180))
                    .stroke(
                        isEnabled ? 
                            Color.accentColor.opacity(0.15) : 
                            Color.gray.opacity(0.1),
                        lineWidth: 6
                    )
                    .frame(height: 160)
                
                ForEach(-50..<51, id: \.self) { tick in
                    if tick % 10 == 0 {
                        Rectangle()
                            .fill(isEnabled ? Color.secondary.opacity(0.3) : Color.gray.opacity(0.2))
                            .frame(width: 2, height: tick % 20 == 0 ? 12 : 8)
                            .offset(y: -72)
                            .rotationEffect(.degrees(Double(tick) * 0.9))
                    }
                }
                
                Rectangle()
                    .fill(isEnabled ? Color.accentColor.opacity(0.5) : Color.gray.opacity(0.3))
                    .frame(width: 3, height: 20)
                    .offset(y: 0)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.9),
                                Color.red.opacity(0.7)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 80)
                    .offset(y: -40)
                    .rotationEffect(.degrees(needleRotation), anchor: .bottom)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    .opacity(isEnabled ? 1 : 0.3)
            }
            .frame(height: 160)
        }
        .padding(.horizontal)
        .scaleEffect(pressScale)
        .contentShape(Rectangle())
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isEnabled.toggle()
                pressScale = 0.97
            }
            withAnimation(.spring().delay(0.1)) {
                pressScale = 1.0
            }
        }
        .padding(.top, 60)
    }
}