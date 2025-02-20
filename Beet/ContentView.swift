import SwiftUI

struct ContentView: View {
    @StateObject private var settings = Settings()
    @State private var isTunerVisible = false
    @State private var showingSettings = false
    @StateObject private var audioEngine = AudioEngine()
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            if isTunerVisible {
                TunerView(
                    aFrequency: .init(
                        get: { settings.referenceFrequency },
                        set: { settings.referenceFrequency = $0 }
                    ),
                    isTunerVisible: $isTunerVisible,
                    audioEngine: audioEngine
                )
            } else {
                MetronomeView(
                    settings: settings,
                    audioEngine: audioEngine,
                    isPlaying: $isPlaying,
                    isTunerVisible: $isTunerVisible,
                    showingSettings: $showingSettings
                )
            }
        }
        .animation(.easeInOut, value: isTunerVisible)
        .preferredColorScheme(settings.colorScheme == .system ? nil :
            settings.colorScheme == .dark ? .dark : .light)
    }
}

struct MetronomeView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var audioEngine: AudioEngine
    @Binding var isPlaying: Bool
    @Binding var isTunerVisible: Bool
    @Binding var showingSettings: Bool
    @State private var isEditingBPM = false
    @State private var showingTimeSignaturePicker = false
    @State private var showingSubdivisionPicker = false
    @State private var bpmText: String = ""
    @State private var tunerEnabled = false
    @State private var bpmTimer: Timer?
    @State private var bpmChangeInterval: TimeInterval = 0.1
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: {
                    isTunerVisible.toggle()
                }) {
                    Image(systemName: "tuningfork")
                        .font(.title)
                }
                .padding(.leading, 20)
                
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title)
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 8)
            
            TunerMeterView(isEnabled: $tunerEnabled)
                .frame(height: 160)
                .padding(.top, 20)
                .padding(.horizontal)
            
            Spacer()
            
            // Time Signature and Subdivision
            HStack(spacing: 50) {
                Button(action: {
                    showingTimeSignaturePicker = true
                }) {
                    Text("\(settings.beatsPerMeasure)/\(settings.beatUnit)")
                        .font(.title2)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Button(action: {
                    showingSubdivisionPicker = true
                }) {
                    Image(systemName: "music.note.list")
                        .font(.title2)
                        .padding(14)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 20)
            
            // BPM Controls
            VStack(spacing: 20) {
                // Up Arrow with long press
                Button(action: {}) {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color(white: 0.7))
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .shadow(color: .gray.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                }
                .buttonStyle(PressableButtonStyle())
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.3)
                        .onEnded { _ in
                            // Start continuous increase
                            bpmTimer = Timer.scheduledTimer(withTimeInterval: bpmChangeInterval, repeats: true) { _ in
                                let newBPM = min(240, settings.bpm + 1)
                                settings.bpm = newBPM
                                if isPlaying {
                                    audioEngine.updateBPMWithPause(
                                        newBPM,
                                        beatsPerMeasure: settings.beatsPerMeasure,
                                        subdivision: settings.subdivision
                                    )
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in
                            // Stop continuous increase
                            bpmTimer?.invalidate()
                            bpmTimer = nil
                        }
                )
                .onTapGesture {
                    let newBPM = min(240, settings.bpm + 1)
                    settings.bpm = newBPM
                    if isPlaying {
                        audioEngine.updateBPMWithPause(
                            newBPM,
                            beatsPerMeasure: settings.beatsPerMeasure,
                            subdivision: settings.subdivision
                        )
                    }
                }
                
                // BPM Display - now display only
                Text("\(settings.bpm)")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(height: 66)
                
                // Down Arrow with long press
                Button(action: {}) {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color(white: 0.7))
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .shadow(color: .gray.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                }
                .buttonStyle(PressableButtonStyle())
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.3)
                        .onEnded { _ in
                            // Start continuous decrease
                            bpmTimer = Timer.scheduledTimer(withTimeInterval: bpmChangeInterval, repeats: true) { _ in
                                let newBPM = max(40, settings.bpm - 1)
                                settings.bpm = newBPM
                                if isPlaying {
                                    audioEngine.updateBPMWithPause(
                                        newBPM,
                                        beatsPerMeasure: settings.beatsPerMeasure,
                                        subdivision: settings.subdivision
                                    )
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in
                            // Stop continuous decrease
                            bpmTimer?.invalidate()
                            bpmTimer = nil
                        }
                )
                .onTapGesture {
                    let newBPM = max(40, settings.bpm - 1)
                    settings.bpm = newBPM
                    if isPlaying {
                        audioEngine.updateBPMWithPause(
                            newBPM,
                            beatsPerMeasure: settings.beatsPerMeasure,
                            subdivision: settings.subdivision
                        )
                    }
                }
            }
            .padding(.vertical, 16)
            
            // Play/Pause and Tap Tempo
            HStack(spacing: 50) {
                Button(action: {
                    isPlaying.toggle()
                    if isPlaying {
                        audioEngine.playMetronomeClick(
                            bpm: settings.bpm,
                            beatsPerMeasure: settings.beatsPerMeasure,
                            subdivision: settings.subdivision
                        )
                    } else {
                        audioEngine.stop()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PressableButtonStyle())
                
                TapTempoButton(
                    bpm: $settings.bpm,
                    isPlaying: isPlaying,
                    audioEngine: audioEngine,
                    settings: settings
                )
            }
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $showingSettings) {
            SettingsView(isShowing: $showingSettings, settings: settings)
        }
        .sheet(isPresented: $showingTimeSignaturePicker) {
            TimeSignaturePickerView(
                isShowing: $showingTimeSignaturePicker,
                numerator: $settings.beatsPerMeasure,
                denominator: $settings.beatUnit,
                onTimeSignatureChange: { num, den in
                    if isPlaying {
                        audioEngine.updateTimeSignature(
                            bpm: settings.bpm,
                            beatsPerMeasure: num,
                            subdivision: settings.subdivision
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $showingSubdivisionPicker) {
            SubdivisionPickerView(
                isShowing: $showingSubdivisionPicker,
                subdivision: $settings.subdivision,
                onSubdivisionChange: { newSubdivision in
                    if isPlaying {
                        audioEngine.updateTimeSignature(
                            bpm: settings.bpm,
                            beatsPerMeasure: settings.beatsPerMeasure,
                            subdivision: newSubdivision
                        )
                    }
                }
            )
        }
    }
}
