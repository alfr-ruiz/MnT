import AVFoundation
import UIKit

class AudioEngine: NSObject, ObservableObject {
    private var engine: AVAudioEngine
    private var player: AVAudioPlayerNode
    private var mixer: AVAudioMixerNode
    private var highClickBuffer: AVAudioPCMBuffer?
    private var lowClickBuffer: AVAudioPCMBuffer?
    private var currentBeat: Int = 1
    private var currentBPM: Int = 120
    private var timer: Timer?
    private var currentBeatsPerMeasure: Int = 4
    private var displayLink: CADisplayLink?
    private var nextClickTime: TimeInterval = 0
    @Published var isPlaying: Bool = false
    
    // Add these properties for triangle wave
    private var triangleOscillator: AVAudioSourceNode?
    private var triangleFrequency: Double = 440.0
    private var isTriangleWavePlaying = false
    
    private var resumeWorkItem: DispatchWorkItem?
    
    override init() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        mixer = AVAudioMixerNode()
        
        super.init()
        
        engine.attach(player)
        engine.attach(mixer)
        
        engine.connect(player, to: mixer, format: nil)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        
        setupAudioSession()
        loadSounds()
        
        do {
            try engine.start()
        } catch {
            print("AudioEngine failed to start: \(error)")
        }
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleScreenDidChange),
            name: UIScreen.brightnessDidChangeNotification,
            object: nil
        )
    }
    
    func playMetronomeClick(bpm: Int, beatsPerMeasure: Int, subdivision: Settings.Subdivision) {
        currentBPM = bpm
        currentBeatsPerMeasure = beatsPerMeasure
        
        // Stop any existing playback
        displayLink?.invalidate()
        displayLink = nil
        timer?.invalidate()
        timer = nil
        player.stop()
        
        // Set up timing
        let secondsPerBeat = 60.0 / Double(bpm)
        let subdivisionMultiplier: Double = {
            switch subdivision {
            case .quarter: return 1.0
            case .eighth: return 0.5
            case .sixteenth: return 0.25
            case .triplet: return 1.0 / 3.0
            }
        }()
        
        let interval = secondsPerBeat * subdivisionMultiplier
        
        // Set next click time to exactly now
        nextClickTime = CACurrentMediaTime()
        
        // Play first click immediately
        playClick()
        
        // Set up display link for subsequent clicks
        displayLink = CADisplayLink(target: self, selector: #selector(handleTick))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 120, maximum: 120, preferred: 120)
        displayLink?.add(to: .current, forMode: .common)
        
        isPlaying = true
    }
    
    @objc private func handleTick() {
        let currentTime = CACurrentMediaTime()
        if currentTime >= nextClickTime {
            playClick()
            // Calculate next click time based on exact BPM
            nextClickTime = nextClickTime + (60.0 / Double(currentBPM))
        }
    }
    
    private func playClick() {
        let buffer = currentBeat == 1 ? highClickBuffer : lowClickBuffer
        guard let clickBuffer = buffer else { return }
        
        // Schedule buffer to play immediately
        player.scheduleBuffer(clickBuffer, at: nil, options: .interrupts)
        player.play()
        
        currentBeat += 1
        if currentBeat > currentBeatsPerMeasure {
            currentBeat = 1
        }
    }
    
    func stop() {
        resumeWorkItem?.cancel()
        resumeWorkItem = nil
        displayLink?.invalidate()
        displayLink = nil
        timer?.invalidate()
        timer = nil
        player.stop()
        currentBeat = 1
        isPlaying = false
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, 
                                  mode: .default, 
                                  options: [.mixWithOthers, .duckOthers])
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
            
            try session.setActive(true)
            session.addObserver(self, forKeyPath: "outputVolume", options: .new, context: nil)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    @objc private func handleScreenDidChange() {
        // Do nothing - we want to continue playing regardless of screen state
    }
    
    func updateBackgroundAudioMode(enabled: Bool) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, 
                                  mode: .default, 
                                  options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to update audio session: \(error)")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        let session = AVAudioSession.sharedInstance()
        session.removeObserver(self, forKeyPath: "outputVolume")
    }
    
    private func loadSounds() {
        // Load high click (first beat)
        if let hiUrl = Bundle.main.url(forResource: "hi", withExtension: "wav") {
            do {
                let hiFile = try AVAudioFile(forReading: hiUrl)
                highClickBuffer = AVAudioPCMBuffer(pcmFormat: hiFile.processingFormat,
                                                 frameCapacity: AVAudioFrameCount(hiFile.length))
                try hiFile.read(into: highClickBuffer!)
            } catch {
                print("Failed to load hi click sound: \(error)")
            }
        }
        
        // Load low click (other beats)
        if let loUrl = Bundle.main.url(forResource: "lo", withExtension: "wav") {
            do {
                let loFile = try AVAudioFile(forReading: loUrl)
                lowClickBuffer = AVAudioPCMBuffer(pcmFormat: loFile.processingFormat,
                                                frameCapacity: AVAudioFrameCount(loFile.length))
                try loFile.read(into: lowClickBuffer!)
            } catch {
                print("Failed to load lo click sound: \(error)")
            }
        }
    }
    
    func startTuningFork(frequency: Double) {
        triangleFrequency = frequency
        
        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        var phase: Double = 0.0
        
        triangleOscillator = AVAudioSourceNode { _, _, frameCount, audioBufferList in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let buffer = ablPointer[0]
            let ptr = buffer.mData?.assumingMemoryBound(to: Float.self)
            
            let frequency = self.triangleFrequency
            let phaseIncrement = frequency / sampleRate
            
            for frame in 0..<Int(frameCount) {
                let value = 2.0 * abs(2.0 * phase - 1.0) - 1.0
                ptr?[frame] = Float(value * 0.25)
                
                phase += phaseIncrement
                if phase >= 1.0 {
                    phase -= 1.0
                }
            }
            
            return noErr
        }
        
        if let triangleOscillator = triangleOscillator {
            engine.attach(triangleOscillator)
            engine.connect(triangleOscillator, to: engine.mainMixerNode, format: nil)
            triangleOscillator.volume = 0
            
            // Fade in
            let fadeInDuration: TimeInterval = 0.05
            let steps = 20
            let volumeStep = 0.3 / Double(steps)
            let stepDuration = fadeInDuration / Double(steps)
            
            for i in 0...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                    triangleOscillator.volume = Float(Double(i) * volumeStep)
                }
            }
        }
    }
    
    func stopTuningFork() {
        guard let triangleOscillator = triangleOscillator else { return }
        
        // Fade out
        let fadeOutDuration: TimeInterval = 0.05
        let steps = 20
        let initialVolume = triangleOscillator.volume
        let volumeStep = initialVolume / Float(steps)
        let stepDuration = fadeOutDuration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                triangleOscillator.volume = initialVolume - (volumeStep * Float(i))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) { [weak self] in
            self?.engine.detach(triangleOscillator)
            self?.triangleOscillator = nil
        }
    }
    
    func updateBPMWithPause(_ newBPM: Int, beatsPerMeasure: Int, subdivision: Settings.Subdivision) {
        // Cancel any pending resume
        resumeWorkItem?.cancel()
        
        // Stop current playback if playing
        if isPlaying {
            displayLink?.invalidate()
            displayLink = nil
            timer?.invalidate()
            timer = nil
            player.stop()
            
            // Schedule resume after 0.5 seconds
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.playMetronomeClick(
                    bpm: newBPM,
                    beatsPerMeasure: beatsPerMeasure,
                    subdivision: subdivision
                )
            }
            resumeWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
        
        currentBPM = newBPM
    }
    
    func updateTimeSignature(bpm: Int, beatsPerMeasure: Int, subdivision: Settings.Subdivision) {
        stop()
        playMetronomeClick(bpm: bpm, beatsPerMeasure: beatsPerMeasure, subdivision: subdivision)
    }
    
    func pauseTemporarily() {
        // Cancel any pending resume
        resumeWorkItem?.cancel()
        
        // Stop the metronome
        displayLink?.invalidate()
        displayLink = nil
        timer?.invalidate()
        timer = nil
        player.stop()
        
        // Create new work item for resuming
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.playMetronomeClick(
                bpm: self.currentBPM,
                beatsPerMeasure: self.currentBeatsPerMeasure,
                subdivision: .quarter
            )
        }
        
        // Schedule resume after 0.5 seconds
        resumeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
} 