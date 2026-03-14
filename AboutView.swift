import SwiftUI

// ── ABOUT ────────────────────────────────────────────────────
private let kAuthorName   = "Built by George"
private let kAuthorBio    = "Fully Open-Source"
private let kGitHubURL    = "https://github.com/wckyhq/Ascend"
private let kAppVersion   = "1.0"
// ─────────────────────────────────────────────────────────────────────────────

struct AboutView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("❤️")
                    .font(.system(size: 52))
                    .padding(.top, 24)

                Text("Ascend")
                    .font(.title3.bold())

                Text("Version \(kAppVersion)")
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
    }

    private func openGitHub() {
        if let url = URL(string: kGitHubURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
