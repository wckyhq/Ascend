import SwiftUI

private enum UpdateCheckState {
    case idle, checking, upToDate, failed
    case updateAvailable(String)
}

private enum Tab: Hashable {
    case general, timers, sounds, icons, updates
}

struct SettingsView: View {
    @ObservedObject var appState: AppState
    let onDone: () -> Void

    @State private var selectedTab: Tab = .general
    @State private var updateState: UpdateCheckState = .idle

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                generalTab
                    .tabItem { Label("General", systemImage: "gear") }
                    .tag(Tab.general)

                timersTab
                    .tabItem { Label("Timers", systemImage: "timer") }
                    .tag(Tab.timers)

                soundsTab
                    .tabItem { Label("Sounds", systemImage: "speaker.wave.2") }
                    .tag(Tab.sounds)

                iconsTab
                    .tabItem { Label("Icons", systemImage: "square.grid.2x2") }
                    .tag(Tab.icons)

                updatesTab
                    .tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }
                    .tag(Tab.updates)
            }

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
        .frame(width: 400, height: 420)
    }

    // MARK: - Tab: General

    private var generalTab: some View {
        VStack(spacing: 10) {
            card {
                VStack(alignment: .leading, spacing: 8) {
                    Label("System", systemImage: "power").font(.headline)
                    Toggle("Open at login", isOn: $appState.launchAtLogin)
                        .toggleStyle(.switch)
                    Text("Ascend will start automatically when you log in.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            card {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Display", systemImage: "bell.badge").font(.headline)

                    Toggle("Show on-screen reminder popup", isOn: $appState.showVisualAlert)
                        .toggleStyle(.switch)
                    Text("A banner appears in the top-right corner when it's time to switch.")
                        .font(.caption).foregroundColor(.secondary)

                    Divider()

                    Toggle("Show countdown in menu bar", isOn: $appState.showCountdownInMenuBar)
                        .toggleStyle(.switch)
                    Text("Displays the time until your next reminder next to the menu bar icon.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
    }

    // MARK: - Tab: Timers

    private var timersTab: some View {
        VStack(spacing: 10) {
            card {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Reminder Intervals", systemImage: "timer").font(.headline)
                    IntervalSliderRow(label: "🧍 Standing", value: $appState.standIntervalMinutes)
                    IntervalSliderRow(label: "🪑 Sitting",  value: $appState.sitIntervalMinutes)
                    Text("Stand after sitting for \(Int(appState.sitIntervalMinutes)) min · Sit after standing for \(Int(appState.standIntervalMinutes)) min.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(14)
    }

    // MARK: - Tab: Sounds

    private var soundsTab: some View {
        VStack(spacing: 10) {
            card {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Alert Sounds", systemImage: "speaker.wave.2").font(.headline)
                    SoundPickerRow(label: "Stand Up", selection: $appState.standSoundName)
                    SoundPickerRow(label: "Sit Down", selection: $appState.sitSoundName)
                }
            }
            Spacer()
        }
        .padding(14)
    }

    // MARK: - Tab: Icons

    private var iconsTab: some View {
        ScrollView {
            VStack(spacing: 10) {
                card {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Menu Bar Icons", systemImage: "square.grid.2x2").font(.headline)

                        Text("Presets").font(.subheadline).foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(AppState.iconPresets) { preset in
                                PresetButton(
                                    preset: preset,
                                    isSelected: appState.standingIcon == preset.standing &&
                                                appState.sittingIcon  == preset.sitting
                                ) {
                                    appState.standingIcon = preset.standing
                                    appState.sittingIcon  = preset.sitting
                                }
                            }
                        }

                        Divider()

                        Text("Custom").font(.subheadline).foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            LabeledIconField(label: "Standing", text: $appState.standingIcon, placeholder: "🧍")
                            LabeledIconField(label: "Sitting",  text: $appState.sittingIcon,  placeholder: "🪑")
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Preview").font(.caption).foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    Text(appState.standingIcon.isEmpty ? "🧍" : appState.standingIcon).font(.title2)
                                    Text("/").foregroundColor(.secondary)
                                    Text(appState.sittingIcon.isEmpty  ? "🪑" : appState.sittingIcon).font(.title2)
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }

    // MARK: - Tab: Updates

    private var updatesTab: some View {
        VStack(spacing: 10) {
            card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath").font(.headline)

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
                        case .updateAvailable(let tag):
                            Link("\(tag) available — Download",
                                 destination: URL(string: "https://github.com/wckyhq/Ascend/releases/latest")!)
                                .font(.callout)
                        case .failed:
                            Label("Check failed", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red).font(.callout)
                        default:
                            EmptyView()
                        }
                    }

                    if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("Current version: \(v)").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(14)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
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
                let current  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1"
                let isNewer  = latest.compare(current, options: .numeric) == .orderedDescending
                await MainActor.run { updateState = isNewer ? .updateAvailable(release.tagName) : .upToDate }
            } catch {
                await MainActor.run { updateState = .failed }
            }
        }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    enum CodingKeys: String, CodingKey { case tagName = "tag_name" }
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
                .foregroundColor(.secondary)
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
                .foregroundColor(.secondary)
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
            Text(label).font(.caption).foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 64)
        }
    }
}
