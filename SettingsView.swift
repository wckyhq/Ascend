import SwiftUI
import CoreHaptics

// MARK: - State enums

private enum UpdateCheckState {
    case idle, checking, upToDate, failed
    case updateAvailable(String, String)   // (tag, dmgDownloadURL)
}

private enum Tab: CaseIterable, Hashable {
    case general, timers, sounds, icons, updates

    var label: String {
        switch self {
        case .general: return "General"
        case .timers:  return "Timers"
        case .sounds:  return "Sounds"
        case .icons:   return "Icons"
        case .updates: return "Updates"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gear"
        case .timers:  return "timer"
        case .sounds:  return "speaker.wave.2"
        case .icons:   return "square.grid.2x2"
        case .updates: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Main view

struct SettingsView: View {
    @ObservedObject var appState: AppState
    let onDone: () -> Void

    @State private var selectedTab: Tab = .general
    @State private var updateState: UpdateCheckState = .idle
    @State private var showUpdateSheet = false

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            VStack(spacing: 0) {
                ZStack {
                    switch selectedTab {
                    case .general: generalTab.transition(.opacity)
                    case .timers:  timersTab.transition(.opacity)
                    case .sounds:  soundsTab.transition(.opacity)
                    case .icons:   iconsTab.transition(.opacity)
                    case .updates: updatesTab.transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                HStack {
                    Spacer()
                    Button("Done", action: onDone)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: [])
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .frame(width: 560, height: 420)
        .sheet(isPresented: $showUpdateSheet) {
            if case .updateAvailable(let tag, let url) = updateState {
                UpdateDialogView(tag: tag, downloadURL: url, isPresented: $showUpdateSheet)
            }
        }
        .background {
            if #available(macOS 26, *) {
                Rectangle().fill(.regularMaterial).ignoresSafeArea()
            } else {
                Color(NSColor.windowBackgroundColor).ignoresSafeArea()
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Tab.allCases, id: \.self) { tab in
                sidebarItem(tab)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(width: 148)
        .background(Color.primary.opacity(0.04))
    }

    private func sidebarItem(_ tab: Tab) -> some View {
        Button(action: { withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { selectedTab = tab } }) {
            HStack(spacing: 9) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18, alignment: .center)
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                Text(tab.label)
                    .font(.system(size: 13))
                    .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab: General

    private var generalTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                card {
                    cardRow {
                        Toggle("Open at login", isOn: $appState.launchAtLogin)
                        Text("Ascend will start automatically when you log in.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    cardRow(last: true) {
                        Toggle("Show on-screen popup", isOn: $appState.showVisualAlert)
                        Text("A banner appears in the top-right corner when it's time to switch.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                card {
                    cardRow(last: true) {
                        Toggle("Show countdown in menu bar", isOn: $appState.showCountdownInMenuBar)
                        Text("Displays the time until your next reminder next to the menu bar icon.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Tab: Timers

    private var timersTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                card {
                    cardRow {
                        IntervalSliderRow(label: "🧍 Standing", value: $appState.standIntervalMinutes)
                    }
                    cardRow(last: true) {
                        IntervalSliderRow(label: "🪑 Sitting", value: $appState.sitIntervalMinutes)
                    }
                }
                Text("Stand after sitting for \(Int(appState.sitIntervalMinutes)) min · Sit after standing for \(Int(appState.standIntervalMinutes)) min.")
                    .font(.caption).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            .padding(16)
        }
    }

    // MARK: - Tab: Sounds

    private var soundsTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                card {
                    cardRow {
                        SoundPickerRow(label: "Stand Up", selection: $appState.standSoundName)
                    }
                    cardRow(last: true) {
                        SoundPickerRow(label: "Sit Down", selection: $appState.sitSoundName)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Tab: Icons

    private var iconsTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                card {
                    cardRow(last: true) {
                        Text("Presets")
                            .font(.subheadline.weight(.medium))
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                            spacing: 8
                        ) {
                            ForEach(AppState.iconPresets) { preset in
                                PresetButton(
                                    preset: preset,
                                    isSelected: appState.standingIcon == preset.standing &&
                                                appState.sittingIcon  == preset.sitting  &&
                                                appState.pauseIcon    == preset.pause
                                ) {
                                    appState.standingIcon = preset.standing
                                    appState.sittingIcon  = preset.sitting
                                    appState.pauseIcon    = preset.pause
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                card {
                    cardRow(last: true) {
                        Text("Custom")
                            .font(.subheadline.weight(.medium))
                        HStack(spacing: 16) {
                            LabeledIconField(label: "Standing", text: $appState.standingIcon, placeholder: "🧍")
                            LabeledIconField(label: "Sitting",  text: $appState.sittingIcon,  placeholder: "🪑")
                            LabeledIconField(label: "Paused",   text: $appState.pauseIcon,    placeholder: "⏹︎")
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Preview").font(.caption).foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    Text(appState.standingIcon.isEmpty ? "🧍" : appState.standingIcon).font(.title2)
                                    Text("/").foregroundColor(.secondary)
                                    Text(appState.sittingIcon.isEmpty  ? "🪑" : appState.sittingIcon).font(.title2)
                                    Text("/").foregroundColor(.secondary)
                                    Text(appState.pauseIcon.isEmpty    ? "⏹︎" : appState.pauseIcon).font(.title2)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Tab: Updates

    private var updatesTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                card {
                    cardRow(last: true) {
                        HStack(spacing: 10) {
                            Button(action: checkForUpdates) {
                                if case .checking = updateState { Text("Checking…") }
                                else { Text("Check for Updates") }
                            }
                            .disabled({ if case .checking = updateState { return true }; return false }())

                            switch updateState {
                            case .upToDate:
                                Label("Up to date", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green).font(.callout)
                            case .updateAvailable(let tag, _):
                                Label("\(tag) available", systemImage: "arrow.down.circle.fill")
                                    .foregroundColor(.accentColor).font(.callout)
                            case .failed:
                                Label("Check failed", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red).font(.callout)
                            default:
                                EmptyView()
                            }
                        }

                        if case .updateAvailable = updateState {
                            Button("Download & Install…") { showUpdateSheet = true }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 4)
                        }

                        if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            Text("Current version: \(v)")
                                .font(.caption).foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Card helpers

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func cardRow<Content: View>(last: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                content()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)

            if !last {
                Divider().padding(.leading, 14)
            }
        }
    }

    // MARK: - Network

    private func checkForUpdates() {
        updateState = .checking
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.github.com/repos/wckyhq/Ascend/releases/latest")!)
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                let (data, _) = try await URLSession.shared.data(for: request)
                let release  = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let latest   = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
                let current  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3"
                let isNewer  = latest.compare(current, options: .numeric) == .orderedDescending
                let dmgURL   = release.assets.first { $0.name.hasSuffix(".dmg") }?.browserDownloadUrl ?? ""
                await MainActor.run {
                    updateState = isNewer ? .updateAvailable(release.tagName, dmgURL) : .upToDate
                }
            } catch {
                await MainActor.run { updateState = .failed }
            }
        }
    }

}

// MARK: - GitHub release model

private struct GitHubRelease: Decodable {
    let tagName: String
    let assets:  [Asset]

    struct Asset: Decodable {
        let name: String
        let browserDownloadUrl: String
        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

// MARK: - Reusable sub-views

struct PresetButton: View {
    let preset: IconPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    Text(preset.standing)
                    Text(preset.sitting)
                    Text(preset.pause)
                }
                .font(.title3)

                Text(preset.label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SoundPickerRow: View {
    let label: String
    @Binding var selection: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 72, alignment: .leading)
            Picker("", selection: $selection) {
                ForEach(AppState.availableSounds, id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .onChange(of: selection) { AppState.play(selection) }
        }
    }
}

struct IntervalSliderRow: View {
    let label: String
    @Binding var value: Double

    @State private var raw: Double = 30
    @State private var dragging = false

    private var displayMinutes: Int { Int((raw / 5).rounded() * 5) }
    // [5, 10, 15, … 120]
    private static let steps = (1...24).map { $0 * 5 }
    // Estimated thumb half-width for macOS regular slider
    private let thumbPad: CGFloat = 9

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .frame(width: 100, alignment: .leading)
            VStack(spacing: 2) {
                Slider(value: $raw, in: 5...120, onEditingChanged: { editing in
                    dragging = editing
                    if !editing { snap() }
                })
                ticks
            }
            Text("\(displayMinutes) min")
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 52, alignment: .trailing)
        }
        .onAppear { raw = value }
        .onChange(of: value) { if !dragging { raw = value } }
        .onChange(of: displayMinutes) {
            guard dragging else { return }
            HapticEngine.shared.tick()
        }
    }

    private var ticks: some View {
        GeometryReader { geo in
            let trackW = geo.size.width - 2 * thumbPad
            ZStack(alignment: .topLeading) {
                ForEach(Self.steps, id: \.self) { minute in
                    let frac      = CGFloat(minute - 5) / 115.0
                    let x         = thumbPad + frac * trackW
                    let isCurrent = minute == displayMinutes
                    let isMagnet  = minute == 30 && !isCurrent
                    let w: CGFloat = isCurrent ? 2   : isMagnet ? 2   : 1
                    let h: CGFloat = isCurrent ? 9   : isMagnet ? 7   : 4
                    let color: Color = isCurrent
                        ? .accentColor
                        : isMagnet
                            ? .accentColor.opacity(0.45)
                            : .secondary.opacity(0.35)
                    Rectangle()
                        .fill(color)
                        .frame(width: w, height: h)
                        .offset(x: x - w / 2)
                }
            }
        }
        .frame(height: 10)
        .animation(.spring(response: 0.12, dampingFraction: 0.7), value: displayMinutes)
    }

    private func snap() {
        let snapped: Double = abs(raw - 30) <= 7
            ? 30
            : max(5, min(120, (raw / 5).rounded() * 5))
        if snapped == 30 { HapticEngine.shared.snap() }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { raw = snapped }
        value = snapped
    }
}

struct LabeledIconField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 64)
        }
    }
}

// MARK: - Haptic engine

private final class HapticEngine {
    static let shared = HapticEngine()
    private var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.playsHapticsOnly = true
        engine?.isAutoShutdownEnabled = true
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        try? engine?.start()
    }

    /// Light click for each 5-min step
    func tick() {
        if !playCore(intensity: 0.8, sharpness: 0.9) {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        }
    }

    /// Double-tap clunk for the 30-min magnet snap
    func snap() {
        if !playCore(intensity: 1.0, sharpness: 1.0) {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }
        }
    }

    /// Returns true if CoreHaptics played successfully, false if caller should fall back.
    @discardableResult
    private func playCore(intensity: Float, sharpness: Float) -> Bool {
        guard let engine else { return false }
        let params = [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        ]
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: params, relativeTime: 0)
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []) else { return false }
        do {
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            try? engine.start()
            return false
        }
    }
}

// MARK: - Update dialog

struct UpdateDialogView: View {
    let tag: String
    let downloadURL: String
    @Binding var isPresented: Bool

    @StateObject private var dm = DownloadManager()

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 14) {
                if let img = NSImage(named: "Ascend") {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 72, height: 72)
                }
                VStack(spacing: 4) {
                    Text("Ascend \(tag) Available")
                        .font(.title2.bold())
                    Text("You have version \(currentVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            Spacer()

            // Phase content
            VStack(spacing: 12) {
                switch dm.phase {
                case .idle:
                    Button("Download & Install") { dm.start(urlString: downloadURL) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                case .downloading(let p):
                    VStack(spacing: 8) {
                        ProgressView(value: p)
                            .frame(maxWidth: .infinity)
                        Text("Downloading… \(Int(p * 100))%")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                case .done(let url):
                    VStack(spacing: 8) {
                        Label("Download complete", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Button("Install & Relaunch") { dm.installAndRelaunch(dmgURL: url) }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }

                case .failed(let msg):
                    VStack(spacing: 8) {
                        Label(msg, systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                        Button("Retry") { dm.start(urlString: downloadURL) }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Divider()

            Button("Cancel") { isPresented = false }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .padding(.vertical, 12)
        }
        .frame(width: 340, height: 300)
    }
}

// MARK: - Download manager

private final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {

    enum Phase {
        case idle, done(URL), failed(String)
        case downloading(Double)
    }

    @Published var phase: Phase = .idle
    private var session: URLSession!

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func start(urlString: String) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            phase = .failed("Invalid download URL")
            return
        }
        phase = .downloading(0)
        session.downloadTask(with: url).resume()
    }

    func installAndRelaunch(dmgURL: URL) {
        Task {
            do {
                let mountPoint = try await mountDMG(at: dmgURL)
                let src = "\(mountPoint)/Ascend.app"
                let dst = Bundle.main.bundlePath
                let script = """
                sleep 1
                if /usr/bin/ditto "\(src)" "\(dst)" 2>/dev/null; then
                    /usr/bin/open "\(dst)"
                else
                    /usr/bin/open "https://github.com/wckyhq/Ascend/releases/latest"
                fi
                /usr/bin/hdiutil detach "\(mountPoint)" -quiet 2>/dev/null
                """
                let path = NSTemporaryDirectory() + "ascend_update.sh"
                try script.write(toFile: path, atomically: true, encoding: .utf8)
                await MainActor.run {
                    let t = Process()
                    t.executableURL = URL(fileURLWithPath: "/bin/sh")
                    t.arguments = [path]
                    try? t.run()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { NSApp.terminate(nil) }
                }
            } catch {
                await MainActor.run { self.phase = .failed("Install failed: \(error.localizedDescription)") }
            }
        }
    }

    // MARK: URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent("Ascend_update.dmg")
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            DispatchQueue.main.async { self.phase = .done(dest) }
        } catch {
            DispatchQueue.main.async { self.phase = .failed("Could not save download") }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite total: Int64) {
        guard total > 0 else { return }
        let p = Double(totalBytesWritten) / Double(total)
        DispatchQueue.main.async { self.phase = .downloading(p) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        DispatchQueue.main.async { self.phase = .failed(error.localizedDescription) }
    }

    private func mountDMG(at url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            task.arguments = ["attach", url.path, "-nobrowse", "-plist", "-quiet"]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError  = Pipe()
            task.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                   let entities = plist["system-entities"] as? [[String: Any]],
                   let mount = entities.first(where: { $0["mount-point"] != nil })?["mount-point"] as? String {
                    cont.resume(returning: mount)
                } else {
                    cont.resume(throwing: NSError(domain: "Ascend", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Could not mount DMG"]))
                }
            }
            do { try task.run() } catch { cont.resume(throwing: error) }
        }
    }
}
