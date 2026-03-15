import SwiftUI

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    let isFirstLaunch: Bool
    let onComplete: () -> Void

    @State private var step = 0
    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            pageContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.2), value: step)

            Divider()

            footer
        }
        .frame(width: 460, height: 480)
        .background {
            if #available(macOS 26, *) {
                Rectangle().fill(.regularMaterial).ignoresSafeArea()
            } else {
                Color(NSColor.windowBackgroundColor).ignoresSafeArea()
            }
        }
    }

    // MARK: - Page routing

    @ViewBuilder
    private var pageContent: some View {
        switch step {
        case 0: welcomePage
        case 1: timersPage
        case 2: iconsPage
        case 3: prefsPage
        default: allSetPage
        }
    }

    // MARK: - Footer nav

    private var footer: some View {
        HStack {
            if step > 0 {
                Button("Back") { withAnimation(.easeInOut(duration: 0.2)) { step -= 1 } }
                    .buttonStyle(.bordered)
                    .frame(width: 72)
            } else {
                Spacer().frame(width: 72)
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Circle()
                        .fill(i == step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            Spacer()

            Button(step < totalSteps - 1 ? "Next" : "Get Started") {
                if step < totalSteps - 1 {
                    withAnimation(.easeInOut(duration: 0.2)) { step += 1 }
                } else {
                    onComplete()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(width: 100)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Page: Welcome

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 88, height: 88)
                .shadow(radius: 8, y: 4)

            VStack(spacing: 8) {
                Text(isFirstLaunch ? "Welcome to Ascend" : "What's New in Ascend")
                    .font(.largeTitle.bold())
                Text(isFirstLaunch
                     ? "Your posture reminder for a healthier workday."
                     : "Updated to v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "").")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Text("Ascend reminds you to alternate between sitting and standing throughout your day. Let's get you set up.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 48)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Page: Timers

    private var timersPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader(icon: "timer", title: "Set Your Timers",
                       subtitle: "How long you stay in each position before Ascend reminds you to switch.")
            Divider()

            onboardingRow {
                IntervalSliderRow(label: "🧍 Standing", value: $appState.standIntervalMinutes)
            }
            Divider().padding(.leading, 20)
            onboardingRow {
                IntervalSliderRow(label: "🪑 Sitting", value: $appState.sitIntervalMinutes)
            }
            Divider().padding(.leading, 20)
            onboardingRow {
                Text("You'll be reminded after sitting \(Int(appState.sitIntervalMinutes)) min and standing \(Int(appState.standIntervalMinutes)) min.")
                    .font(.footnote).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Page: Icons

    private var iconsPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader(icon: "square.grid.2x2", title: "Choose Your Icons",
                       subtitle: "Pick the icons shown in your menu bar.")
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    onboardingRow {
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

                    onboardingRow {
                        HStack(spacing: 16) {
                            LabeledIconField(label: "Standing", text: $appState.standingIcon, placeholder: "🧍")
                            LabeledIconField(label: "Sitting",  text: $appState.sittingIcon,  placeholder: "🪑")
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Preview").font(.footnote).foregroundColor(.secondary)
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
        }
    }

    // MARK: - Page: Preferences

    private var prefsPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader(icon: "gear", title: "Preferences",
                       subtitle: "Customise how Ascend works for you. You can change these later in Settings.")
            Divider()

            onboardingRow {
                Toggle("Open at login", isOn: $appState.launchAtLogin)
                    .toggleStyle(.checkbox)
                Text("Ascend will start automatically when you log in.")
                    .font(.footnote).foregroundColor(.secondary)
            }
            Divider().padding(.leading, 20)
            onboardingRow {
                Toggle("Show on-screen reminder popup", isOn: $appState.showVisualAlert)
                    .toggleStyle(.checkbox)
                Text("A banner appears in the top-right corner when it's time to switch.")
                    .font(.footnote).foregroundColor(.secondary)
            }
            Divider().padding(.leading, 20)
            onboardingRow {
                Toggle("Show countdown in menu bar", isOn: $appState.showCountdownInMenuBar)
                    .toggleStyle(.checkbox)
                Text("Displays the time until your next reminder next to the icon.")
                    .font(.footnote).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Page: All Set

    private var allSetPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("You're All Set!")
                    .font(.largeTitle.bold())
                Text("Sit \(Int(appState.sitIntervalMinutes)) min · Stand \(Int(appState.standIntervalMinutes)) min")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Text("Ascend will remind you to switch positions throughout your day.\nYou can adjust everything from the menu bar icon.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 48)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func pageHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.footnote).foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func onboardingRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) { content() }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
