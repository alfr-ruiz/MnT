import SwiftUI

struct TapTempoButton: View {
    @Binding var bpm: Int
    let isPlaying: Bool
    let audioEngine: AudioEngine
    let settings: Settings
    
    @State private var lastTapTime: Date?
    @State private var tapCount: Int = 0
    @State private var tapIntervals: [TimeInterval] = []
    
    var body: some View {
        Button(action: handleTap) {
            VStack {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 30))
                Text("Tap")
                    .font(.caption)
            }
            .foregroundColor(.accentColor)
            .padding()
            .background(Color.gray.opacity(0.2))
            .clipShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    private func handleTap() {
        let currentTime = Date()
        
        if let lastTime = lastTapTime {
            let interval = currentTime.timeIntervalSince(lastTime)
            
            if interval > 2.0 {
                tapIntervals.removeAll()
                tapCount = 0
            } else {
                tapIntervals.append(interval)
                if tapIntervals.count > 4 {
                    tapIntervals.removeFirst()
                }
            }
        }
        
        lastTapTime = currentTime
        tapCount += 1
        
        if tapIntervals.count >= 2 {
            let averageInterval = tapIntervals.reduce(0, +) / Double(tapIntervals.count)
            let newBPM = Int(round(60.0 / averageInterval))
            if newBPM >= 40 && newBPM <= 240 {
                bpm = newBPM
                if isPlaying {
                    audioEngine.updateBPMWithPause(
                        newBPM,
                        beatsPerMeasure: settings.beatsPerMeasure,
                        subdivision: settings.subdivision
                    )
                }
            }
        }
    }
} 