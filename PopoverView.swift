import SwiftUI

struct PopoverView: View {
    @ObservedObject var appState: AppState
    let onToggle:    () -> Void
    let onRemindNow: () -> Void
    let onSettings:  () -> Void
    let onAbout:     () -> Void
    let onQuit:      () -> Void

    var body: some View {
        VStack(spacing: 0) {
            statusSection
            Divider()
            actionSection
            Divider()
            footerSection
        }
        .frame(width: 260)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.5)
        )
    }


    private var statusSection: some View {
        VStack(spacing: 6) {
            Text(appState.isRunning ? appState.currentIcon : "⏸")
                .font(.system(size: 52))
                .padding(.top, 2)

            Text(statusLabel)
                .font(.title3.bold())

            Group {
                if appState.isRunning && !appState.countdownText.isEmpty {
                    Label("Next in \(appState.countdownText)", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !appState.isRunning {
                    Text("Reminders paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(" ")
                        .font(.caption)
                }
            }
            .frame(height: 16)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var statusLabel: String {
        guard appState.isRunning else { return "Paused" }
        return appState.isStanding ? "Standing" : "Sitting"
    }


    private var actionSection: some View {
        VStack(spacing: 8) {
            Button(action: onRemindNow) {
                Text(appState.isStanding ? "Sit Down Now" : "Stand Up Now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: onToggle) {
                Text(appState.isRunning ? "Pause Reminders" : "Resume Reminders")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(14)
    }


    private var footerSection: some View {
        HStack {
            Button(action: onSettings) {
                Label("Settings", systemImage: "gear")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Button(action: onAbout) {
                Label("About", systemImage: "info.circle")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Spacer()

            Button(action: onQuit) {
                Label("Quit", systemImage: "power")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
