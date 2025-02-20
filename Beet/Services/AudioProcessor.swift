import AVFoundation
import Accelerate

class AudioProcessor: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private let sampleRate: Double = 44100.0
    private let bufferSize: AVAudioFrameCount = 4096
    
    @Published var currentFrequency: Float = 440.0
    @Published var closestNote: String = "A4"
    @Published var centsOff: Float = 0.0
    @Published var isInTune: Bool = false
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        let format = inputNode?.inputFormat(forBus: 0)
        
        inputNode?.installTap(onBus: 0, 
                            bufferSize: bufferSize,
                            format: format) { [weak self] buffer, time in
            self?.processMicrophoneData(buffer: buffer)
        }
    }
    
    func startProcessing() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                                      mode: .measurement,
                                                                      options: [.mixWithOthers])
                        try AVAudioSession.sharedInstance().setActive(true)
                        try self?.audioEngine?.start()
                    } catch {
                        print("Failed to start audio engine: \(error.localizedDescription)")
                    }
                } else {
                    print("Microphone access denied")
                }
            }
        }
    }
    
    func stopProcessing() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        setupAudioEngine()
    }
    
    private func processMicrophoneData(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = buffer.frameLength
        
        // Convert buffer to array
        var data = Array(UnsafeBufferPointer(start: channelData, count: Int(frames)))
        
        // Apply Hanning window
        vDSP_hann_window(&data, vDSP_Length(frames), Int32(vDSP_HANN_NORM))
        
        // Set up FFT
        let log2n = vDSP_Length(log2(Double(frames)))
        let fft_weights = vDSP_create_fftsetup(log2n, Int32(FFT_RADIX2))!
        
        var realp = [Float](repeating: 0, count: Int(frames/2))
        var imagp = [Float](repeating: 0, count: Int(frames/2))
        var complex = DSPSplitComplex(realp: &realp, imagp: &imagp)
        
        // Pack samples into split complex vector
        data.withUnsafeBytes { ptr in
            vDSP_ctoz(ptr.bindMemory(to: DSPComplex.self).baseAddress!, 2, &complex, 1, vDSP_Length(frames/2))
        }
        
        // Perform FFT
        vDSP_fft_zrip(fft_weights, &complex, 1, log2n, Int32(FFT_FORWARD))
        
        // Calculate magnitude spectrum
        var magnitudes = [Float](repeating: 0, count: Int(frames/2))
        vDSP_zvmags(&complex, 1, &magnitudes, 1, vDSP_Length(frames/2))
        
        // Clean up FFT setup
        vDSP_destroy_fftsetup(fft_weights)
        
        // Find peak frequency
        var maxMagnitude: Float = 0
        var maxIndex: vDSP_Length = 0
        vDSP_maxvi(magnitudes, 1, &maxMagnitude, &maxIndex, vDSP_Length(frames/2))
        
        let frequency = Float(maxIndex) * Float(sampleRate) / Float(frames)
        
        // Update values on main thread
        DispatchQueue.main.async { [weak self] in
            self?.updateWithFrequency(frequency)
        }
    }
    
    private func updateWithFrequency(_ frequency: Float) {
        guard frequency > 20 && frequency < 4000 else { return }
        
        currentFrequency = frequency
        
        // Find closest note
        let noteNumber = 12 * log2(frequency/440) + 69
        let closestNoteNumber = round(noteNumber)
        let closestNoteFrequency = 440 * pow(2, (closestNoteNumber - 69) / 12)
        
        // Calculate cents off
        centsOff = 1200 * log2(frequency/closestNoteFrequency)
        isInTune = abs(centsOff) < 5 // Consider "in tune" within 5 cents
        
        // Update note name
        closestNote = noteNumberToNoteName(Int(closestNoteNumber))
    }
    
    private func noteNumberToNoteName(_ noteNumber: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (noteNumber / 12) - 1
        let noteIndex = noteNumber % 12
        return "\(noteNames[noteIndex])\(octave)"
    }
} 