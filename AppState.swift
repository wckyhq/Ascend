import Foundation
import Cocoa

struct IconPreset: Identifiable {
    let id = UUID()
    let label: String
    let standing: String
    let sitting: String
}

class AppState: ObservableObject {
    @Published var isStanding: Bool = false
    @Published var isRunning: Bool = true
    @Published var countdownText: String = ""

    // Settings (persisted via UserDefaults)
    @Published var intervalMinutes: Double {
        didSet { UserDefaults.standard.set(intervalMinutes, forKey: "intervalMinutes") }
    }
    @Published var standSoundName: String {
        didSet { UserDefaults.standard.set(standSoundName, forKey: "standSoundName") }
    }
    @Published var sitSoundName: String {
        didSet { UserDefaults.standard.set(sitSoundName, forKey: "sitSoundName") }
    }
    @Published var showVisualAlert: Bool {
        didSet { UserDefaults.standard.set(showVisualAlert, forKey: "showVisualAlert") }
    }
    @Published var standingIcon: String {
        didSet { UserDefaults.standard.set(standingIcon, forKey: "standingIcon") }
    }
    @Published var sittingIcon: String {
        didSet { UserDefaults.standard.set(sittingIcon, forKey: "sittingIcon") }
    }

    var interval: TimeInterval { intervalMinutes * 60 }
    var currentIcon: String { isStanding ? standingIcon : sittingIcon }

    static let availableSounds: [String] = [
        "None", "Basso", "Blow", "Bottle", "Frog",
        "Funk", "Glass", "Hero", "Morse", "Ping",
        "Pop", "Purr", "Sosumi", "Submarine", "Tink"
    ]

    static let iconPresets: [IconPreset] = [
        IconPreset(label: "Person",   standing: "🧍", sitting: "🪑"),
        IconPreset(label: "Arrows",   standing: "⬆️", sitting: "⬇️"),
        IconPreset(label: "Energy",   standing: "⚡",  sitting: "💤"),
        IconPreset(label: "Nature",   standing: "🌿", sitting: "🍃"),
        IconPreset(label: "Minimal",  standing: "▲",  sitting: "▼"),
        IconPreset(label: "Circles",  standing: "🟢", sitting: "🔵"),
    ]

    init() {
        let saved = UserDefaults.standard.double(forKey: "intervalMinutes")
        self.intervalMinutes = saved > 0 ? saved : 30

        // Migrate from single soundName if present
        let legacy = UserDefaults.standard.string(forKey: "soundName") ?? "Ping"
        self.standSoundName = UserDefaults.standard.string(forKey: "standSoundName") ?? legacy
        self.sitSoundName   = UserDefaults.standard.string(forKey: "sitSoundName")   ?? legacy

        self.showVisualAlert = UserDefaults.standard.object(forKey: "showVisualAlert") as? Bool ?? true
        self.standingIcon = UserDefaults.standard.string(forKey: "standingIcon") ?? "🧍"
        self.sittingIcon  = UserDefaults.standard.string(forKey: "sittingIcon")  ?? "🪑"
    }

    func playSound(forStanding: Bool) {
        let name = forStanding ? standSoundName : sitSoundName
        AppState.play(name)
    }

    static func play(_ name: String) {
        guard name != "None" else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    func updateCountdown(nextDate: Date?) {
        guard let next = nextDate, isRunning else { countdownText = ""; return }
        let remaining = next.timeIntervalSinceNow
        if remaining <= 0 {
            countdownText = "Any moment…"
        } else {
            let m = Int(remaining) / 60
            let s = Int(remaining) % 60
            countdownText = String(format: "%02d:%02d", m, s)
        }
    }
}
