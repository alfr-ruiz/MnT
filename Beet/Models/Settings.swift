import Foundation
import UIKit

class Settings: ObservableObject {
    @Published var metronomeSound: MetronomeSound = .click1
    @Published var bpm: Int = 120
    @Published var colorScheme: ColorSchemePreference = .system
    @Published var referenceFrequency: Double = 440.0
    @Published var subdivision: Subdivision = .quarter
    @Published var beatsPerMeasure: Int = 4
    @Published var beatUnit: Int = 4
    
    @Published var autoLockDisabled: Bool {
        didSet {
            UserDefaults.standard.set(autoLockDisabled, forKey: "autoLockDisabled")
            UIApplication.shared.isIdleTimerDisabled = autoLockDisabled
        }
    }
    
    enum MetronomeSound: String, CaseIterable {
        case click1, click2, click3
    }
    
    enum ColorSchemePreference: String, CaseIterable {
        case light, dark, system
    }
    
    enum Subdivision: String, CaseIterable {
        case quarter, eighth, sixteenth, triplet
    }
    
    init() {
        let savedAutoLock = UserDefaults.standard.object(forKey: "autoLockDisabled") as? Bool
        self.autoLockDisabled = savedAutoLock ?? true
        UIApplication.shared.isIdleTimerDisabled = self.autoLockDisabled
    }
} 