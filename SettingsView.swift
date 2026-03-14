import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2.bold())

            Divider()

            launchSection
            intervalSection
            soundSection
            alertSection
            iconSection

            Divider()

            HStack {
                Spacer()
                Button("Done", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(20)
        .frame(width: 360)
    }


    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Reminder Interval", systemImage: "timer")
                .font(.headline)

            HStack(spacing: 10) {
                Slider(value: $appState.intervalMinutes, in: 5...120, step: 5)
                Text("\(Int(appState.intervalMinutes)) min")
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                    .frame(width: 52, alignment: .trailing)
            }

            Text("Alternates between standing and sitting every \(Int(appState.intervalMinutes)) minutes.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }


    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Alert Sounds", systemImage: "speaker.wave.2")
                .font(.headline)

            SoundPickerRow(label: "Stand Up", selection: $appState.standSoundName)
            SoundPickerRow(label: "Sit Down", selection: $appState.sitSoundName)
        }
    }


    private var alertSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Visual Alert", systemImage: "bell.badge")
                .font(.headline)

            Toggle("Show on-screen reminder popup", isOn: $appState.showVisualAlert)
                .toggleStyle(.switch)

            Text("A banner appears in the top-right corner when it's time to switch. When off, a system notification is sent instead.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }


    private var launchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("System", systemImage: "power")
                .font(.headline)

            Toggle("Open at login", isOn: $appState.launchAtLogin)
                .toggleStyle(.switch)

            Text("Ascend will start automatically when you log in.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }


    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Menu Bar Icons", systemImage: "square.grid.2x2")
                .font(.headline)

            Text("Presets")
                .font(.subheadline)
                .foregroundColor(.secondary)

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

            Text("Custom")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            HStack(spacing: 16) {
                LabeledIconField(label: "Standing", text: $appState.standingIcon, placeholder: "🧍")
                LabeledIconField(label: "Sitting",  text: $appState.sittingIcon,  placeholder: "🪑")

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text(appState.standingIcon.isEmpty ? "🧍" : appState.standingIcon)
                            .font(.title2)
                        Text("/")
                            .foregroundColor(.secondary)
                        Text(appState.sittingIcon.isEmpty ? "🪑" : appState.sittingIcon)
                            .font(.title2)
                    }
                }
            }
        }
    }
}


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
                ForEach(AppState.availableSounds, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .onChange(of: selection) {
                AppState.play(selection)
            }
        }
    }
}

struct LabeledIconField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 64)
        }
    }
}
