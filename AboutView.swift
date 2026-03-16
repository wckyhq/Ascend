import SwiftUI

// ── ABOUT ────────────────────────────────────────────────────
private let kAuthorName   = "Built by George"
private let kAuthorBio    = "Fully Open-Source"
private let kGitHubURL    = "https://github.com/wckyhq/Ascend"
// ─────────────────────────────────────────────────────────────────────────────

struct AboutView: View {
    let onClose: () -> Void

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                if let icon = NSImage(named: "Ascend") {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .padding(.top, 20)
                } else {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 52))
                        .padding(.top, 24)
                }

                Text("Ascend")
                    .font(.title3.bold())

                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(kAuthorName)
                            .font(.headline)
                        Text(kAuthorBio)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Button(action: openGitHub) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text("View on GitHub")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .padding(16)

            Divider()

            HStack {
                Spacer()
                Button("Close", action: onClose)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea())
    }

    private func openGitHub() {
        if let url = URL(string: kGitHubURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
