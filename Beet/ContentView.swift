import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var bpm: Int = 120
    @State private var isTunerVisible: Bool = false
    @State private var aFrequency: Double = 440.0
    
    var body: some View {
        ZStack {
            if isTunerVisible {
                TunerView(aFrequency: $aFrequency, isTunerVisible: $isTunerVisible)
            } else {
                MetronomeView(bpm: $bpm, isTunerVisible: $isTunerVisible)
            }
        }
        .animation(.easeInOut, value: isTunerVisible)
    }
}

struct MetronomeView: View {
    @Binding var bpm: Int
    @Binding var isTunerVisible: Bool
    @State private var isPlaying: Bool = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    isTunerVisible.toggle()
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title)
                        .padding()
                }
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 250, height: 250)
                Text("\(bpm) BPM")
                    .font(.largeTitle)
                    .bold()
                Circle()
                    .trim(from: 0, to: 0.01)
                    .stroke(Color.blue, lineWidth: 20)
                    .frame(width: 250, height: 250)
                    .rotationEffect(Angle(degrees: Double(bpm) * 3))
                    .gesture(DragGesture()
                                .onChanged { value in
                                    let newBpm = Int(value.translation.width / 2) + bpm
                                    bpm = max(40, min(newBpm, 240))
                                })
            }
            Spacer()
        }
        .onDisappear {
            stopMetronome()
        }
    }
    
    private func stopMetronome() {
        timer?.invalidate()
        timer = nil
    }
}

struct TunerView: View {
    @Binding var aFrequency: Double
    @Binding var isTunerVisible: Bool
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    isTunerVisible.toggle()
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title)
                        .padding()
                }
            }
            Spacer()
            VStack(spacing: 40) {
                HStack {
                    Text("A Frequency: ")
                    TextField("Frequency", value: $aFrequency, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                }
                Button(action: playTone) {
                    Image(systemName: "tuningfork")
                        .font(.largeTitle)
                        .padding()
                }
            }
            Spacer()
        }
    }
    
    private func playTone() {
        guard let url = Bundle.main.url(forResource: "tuning_fork", withExtension: "wav") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing tone: \(error)")
        }
    }
}

@main
struct MetronomeTunerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
