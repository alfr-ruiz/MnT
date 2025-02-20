import SwiftUI
import AVFoundation

struct TunerView: View {
    @Binding var aFrequency: Double
    @Binding var isTunerVisible: Bool
    @ObservedObject var audioEngine: AudioEngine
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar area
            HStack {
                Spacer()
                Button(action: {
                    if isPlaying {
                        audioEngine.stopTuningFork()
                    }
                    isTunerVisible = false
                }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .frame(width: 60, height: 44)
                .padding(.trailing, 8)
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Main content
            VStack(spacing: 60) {
                // Frequency input
                VStack(spacing: 12) {
                    Text("Reference Pitch")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        TextField("Frequency", value: $aFrequency, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 34, weight: .medium))
                        
                        Text("Hz")
                            .font(.system(size: 34, weight: .medium))
                    }
                    .frame(height: 50)
                }
                .padding(.horizontal, 20)
                
                // Tuning fork button
                Button(action: {
                    isPlaying.toggle()
                    if isPlaying {
                        audioEngine.startTuningFork(frequency: aFrequency)
                    } else {
                        audioEngine.stopTuningFork()
                    }
                }) {
                    Image(systemName: "tuningfork")
                        .font(.system(size: 60))
                        .foregroundColor(isPlaying ? .accentColor : .primary)
                        .frame(width: 160, height: 160)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    TunerView(aFrequency: .constant(440.0), isTunerVisible: .constant(true), audioEngine: AudioEngine())
} 