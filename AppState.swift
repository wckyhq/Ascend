import Foundation
import Cocoa
import ServiceManagement

struct IconPreset: Identifiable {
    let id = UUID()
    let label: String
    let standing: String
    let sitting: String
    let pause: String
}

class AppState: ObservableObject {
    @Published var isStanding: Bool = false
    @Published var isRunning: Bool = true
    @Published var countdownText: String = ""

    @Published var standIntervalMinutes: Double {
        didSet { UserDefaults.standard.set(standIntervalMinutes, forKey: "standIntervalMinutes") }
    }
    @Published var sitIntervalMinutes: Double {
        didSet { UserDefaults.standard.set(sitIntervalMinutes, forKey: "sitIntervalMinutes") }
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
    @Published var showCountdownInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showCountdownInMenuBar, forKey: "showCountdownInMenuBar") }
    }
    @Published var standingIcon: String {
        didSet { UserDefaults.standard.set(standingIcon, forKey: "standingIcon") }
    }
    @Published var sittingIcon: String {
        didSet { UserDefaults.standard.set(sittingIcon, forKey: "sittingIcon") }
    }
    @Published var pauseIcon: String {
        didSet { UserDefaults.standard.set(pauseIcon, forKey: "pauseIcon") }
    }
    @Published var launchAtLogin: Bool {
        didSet { setLaunchAtLogin(launchAtLogin) }
    }

    var standInterval: TimeInterval { standIntervalMinutes * 60 }
    var sitInterval: TimeInterval { sitIntervalMinutes * 60 }
    var currentInterval: TimeInterval { isStanding ? standInterval : sitInterval }
    var currentIcon: String { isStanding ? standingIcon : sittingIcon }

    static let availableSounds: [String] = {
        let dirs = [
            "/System/Library/Sounds",
            "/Library/Sounds",
            NSHomeDirectory() + "/Library/Sounds"
        ]
        var names = Set<String>()
        for dir in dirs {
            if let files = try? FileManager.default.contentsOfDirectory(atPath: dir) {
                for file in files {
                    let name = (file as NSString).deletingPathExtension
                    if !name.isEmpty { names.insert(name) }
                }
            }
        }
        return ["None"] + names.sorted()
    }()

    static let iconPresets: [IconPreset] = [
        IconPreset(label: "Person",  standing: "🧍", sitting: "🪑", pause: "🧘"),
        IconPreset(label: "Arrows",  standing: "⬆️", sitting: "⬇️", pause: "⏸️"),
        IconPreset(label: "Energy",  standing: "⚡",  sitting: "💤", pause: "🔋"),
        IconPreset(label: "Nature",  standing: "🌿", sitting: "🍃", pause: "🍂"),
        IconPreset(label: "Minimal", standing: "↑",  sitting: "↓",  pause: "✕"),
        IconPreset(label: "Circles", standing: "🟢", sitting: "🔵", pause: "⚫"),
    ]

    init() {
        let legacy = UserDefaults.standard.double(forKey: "intervalMinutes")
        let fallback = legacy > 0 ? legacy : 30
        let savedStand = UserDefaults.standard.double(forKey: "standIntervalMinutes")
        let savedSit   = UserDefaults.standard.double(forKey: "sitIntervalMinutes")
        self.standIntervalMinutes = savedStand > 0 ? savedStand : fallback
        self.sitIntervalMinutes   = savedSit   > 0 ? savedSit   : fallback

        let legacySound = UserDefaults.standard.string(forKey: "soundName") ?? "Ping"
        self.standSoundName = UserDefaults.standard.string(forKey: "standSoundName") ?? legacySound
        self.sitSoundName   = UserDefaults.standard.string(forKey: "sitSoundName")   ?? legacySound

        self.showVisualAlert = UserDefaults.standard.object(forKey: "showVisualAlert") as? Bool ?? true
        self.showCountdownInMenuBar = UserDefaults.standard.object(forKey: "showCountdownInMenuBar") as? Bool ?? false
        self.standingIcon = UserDefaults.standard.string(forKey: "standingIcon") ?? "↑"
        self.sittingIcon  = UserDefaults.standard.string(forKey: "sittingIcon")  ?? "↓"
        self.pauseIcon    = UserDefaults.standard.string(forKey: "pauseIcon")    ?? "✕"
        if #available(macOS 13.0, *) {
            self.launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            self.launchAtLogin = FileManager.default.fileExists(atPath: AppState.launchAgentPlistURL.path)
        }
    }

    private static var launchAgentPlistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.user.Ascend.plist")
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                DispatchQueue.main.async { self.launchAtLogin = !enabled }
                let alert = NSAlert()
                alert.messageText = "Could not update login item"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        } else {
            let url = AppState.launchAgentPlistURL
            if enabled {
                guard let execPath = Bundle.main.executablePath else { return }
                let plist: [String: Any] = [
                    "Label": "com.user.Ascend",
                    "ProgramArguments": [execPath],
                    "RunAtLoad": true
                ]
                try? FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                (plist as NSDictionary).write(to: url, atomically: true)
            } else {
                try? FileManager.default.removeItem(at: url)
            }
        }
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
