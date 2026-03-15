import SwiftUI

struct AlertOverlayView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        if #available(macOS 26, *) {
            alertContent
                .glassEffect(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            alertContent
                .background(Color(NSColor.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 0.5)
                )
        }
    }

    private var alertContent: some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 300)
    }
}
