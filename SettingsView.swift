import SwiftUI

private enum UpdateCheckState {
    case idle, checking, upToDate, failed
    case updateAvailable(String, String)   // (tag, dmgDownloadURL)
    case downloading
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

struct SettingsView: View {
    @ObservedObject var appState: AppState
    let onDone: () -> Void

    @State private var selectedTab: Tab = .general
    @State private var updateState: UpdateCheckState = .idle

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar tab bar
            if #available(macOS 26, *) {
                tabBarContent
                    .padding(6)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            } else {
                tabBarContent
                    .padding(.horizontal, 4)
            }

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .general: generalTab
                case .timers:  timersTab
                case .sounds:  soundsTab
                case .icons:   iconsTab
                case .updates: updatesTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                Spacer()
                Button("Done", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 420, height: 400)
        .background {
            if #available(macOS 26, *) {
                Rectangle().fill(.regularMaterial).ignoresSafeArea()
            } else {
                Color(NSColor.windowBackgroundColor).ignoresSafeArea()
            }
        }
    }

    private var tabBarContent: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        Text(tab.label)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tab: General

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsRow {
                Toggle("Open at login", isOn: $appState.launchAtLogin)
                    .toggleStyle(.checkbox)
                Text("Ascend will start automatically when you log in.")
                    .font(.footnote).foregroundColor(.secondary)
            }

            Divider().padding(.leading, 20)

            settingsRow {
                Toggle("Show on-screen reminder popup", isOn: $appState.showVisualAlert)
                    .toggleStyle(.checkbox)
                Text("A banner appears in the top-right corner when it's time to switch.")
                    .font(.footnote).foregroundColor(.secondary)
            }

            Divider().padding(.leading, 20)

            settingsRow {
                Toggle("Show countdown in menu bar", isOn: $appState.showCountdownInMenuBar)
                    .toggleStyle(.checkbox)
                Text("Displays the time until your next reminder next to the menu bar icon.")
                    .font(.footnote).foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Tab: Timers

    private var timersTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsRow {
                IntervalSliderRow(label: "🧍 Standing", value: $appState.standIntervalMinutes)
            }
            Divider().padding(.leading, 20)
            settingsRow {
                IntervalSliderRow(label: "🪑 Sitting", value: $appState.sitIntervalMinutes)
            }
            Divider().padding(.leading, 20)
            settingsRow {
                Text("Stand after sitting for \(Int(appState.sitIntervalMinutes)) min · Sit after standing for \(Int(appState.standIntervalMinutes)) min.")
                    .font(.footnote).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Tab: Sounds

    private var soundsTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsRow {
                SoundPickerRow(label: "Stand Up", selection: $appState.standSoundName)
            }
            Divider().padding(.leading, 20)
            settingsRow {
                SoundPickerRow(label: "Sit Down", selection: $appState.sitSoundName)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Tab: Icons

    private var iconsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                settingsRow {
                    Text("Presets").font(.subheadline).foregroundColor(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(AppState.iconPresets) { preset in
                            PresetButton(
                                preset: preset,
                                isSelected: appState.standingIcon == preset.standing &&
                                            appState.sittingIcon  == preset.sitting &&
                                            appState.pauseIcon    == preset.pause
                            ) {
                                appState.standingIcon = preset.standing
                                appState.sittingIcon  = preset.sitting
                                appState.pauseIcon    = preset.pause
                            }
                        }
                    }
                }

                Divider().padding(.leading, 20)

                settingsRow {
                    Text("Custom").font(.subheadline).foregroundColor(.secondary)
                    HStack(spacing: 16) {
                        LabeledIconField(label: "Standing", text: $appState.standingIcon, placeholder: "🧍")
                        LabeledIconField(label: "Sitting",  text: $appState.sittingIcon,  placeholder: "🪑")
                        LabeledIconField(label: "Paused",   text: $appState.pauseIcon,    placeholder: "⏹︎")
                        Spacer()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Preview").font(.footnote).foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Text(appState.standingIcon.isEmpty ? "🧍" : appState.standingIcon).font(.title2)
                                Text("/").foregroundColor(.secondary)
                                Text(appState.sittingIcon.isEmpty  ? "🪑" : appState.sittingIcon).font(.title2)
                                Text("/").foregroundColor(.secondary)
                                Text(appState.pauseIcon.isEmpty    ? "⏹︎" : appState.pauseIcon).font(.title2)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Tab: Updates

    private var updatesTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsRow {
                // Check button row — hidden while downloading
                if case .downloading = updateState {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Downloading update…").foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 10) {
                        Button(action: checkForUpdates) {
                            if case .checking = updateState { Text("Checking…") }
                            else { Text("Check for Updates") }
                        }
                        .disabled({ if case .checking = updateState { return true }; return false }())

                        switch updateState {
                        case .upToDate:
                            Label("You're up to date", systemImage: "checkmark.circle.fill")
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
                }

                // Download & Install button when an update is ready
                if case .updateAvailable(_, let url) = updateState {
                    HStack(spacing: 8) {
                        Button("Download & Install") { downloadAndInstall(from: url) }
                            .buttonStyle(.borderedProminent)
                        Button("View Release Notes") {
                            NSWorkspace.shared.open(URL(string: "https://github.com/wckyhq/Ascend/releases/latest")!)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 2)
                }

                if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Current version: \(v)").font(.footnote).foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func checkForUpdates() {
        updateState = .checking
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.github.com/repos/wckyhq/Ascend/releases/latest")!)
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                let (data, _) = try await URLSession.shared.data(for: request)
                let release  = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let latest   = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
                let current  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2"
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

    private func downloadAndInstall(from urlString: String) {
        guard !urlString.isEmpty, let downloadURL = URL(string: urlString) else {
            NSWorkspace.shared.open(URL(string: "https://github.com/wckyhq/Ascend/releases/latest")!)
            return
        }
        updateState = .downloading
        Task {
            do {
                let (dmgTemp, _) = try await URLSession.shared.download(from: downloadURL)
                let mountPoint  = try await mountDMG(at: dmgTemp)
                let src = "\(mountPoint)/Ascend.app"
                let dst = Bundle.main.bundlePath

                // Script runs after we quit: replaces app and relaunches
                let script = """
                sleep 1
                if /usr/bin/ditto "\(src)" "\(dst)" 2>/dev/null; then
                    /usr/bin/open "\(dst)"
                else
                    /usr/bin/open "https://github.com/wckyhq/Ascend/releases/latest"
                fi
                /usr/bin/hdiutil detach "\(mountPoint)" -quiet 2>/dev/null
                """
                let scriptPath = NSTemporaryDirectory() + "ascend_update.sh"
                try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)

                await MainActor.run {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/bin/sh")
                    task.arguments = [scriptPath]
                    try? task.run()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        NSApp.terminate(nil)
                    }
                }
            } catch {
                await MainActor.run { updateState = .failed }
            }
        }
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
            .padding(.vertical, 7)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
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

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .frame(width: 100, alignment: .leading)
            Slider(value: $value, in: 5...120, step: 5)
            Text("\(Int(value)) min")
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 52, alignment: .trailing)
        }
    }
}

struct LabeledIconField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.footnote).foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 64)
        }
    }
}
