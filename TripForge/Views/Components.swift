import SwiftUI

// A subtle animated-looking aurora background.
struct AuroraBackground: View {
    var body: some View {
        ZStack {
            Brand.ink900
            Brand.aurora.opacity(0.5).blur(radius: 40)
        }
        .ignoresSafeArea()
    }
}

struct BrandLogo: View {
    var showText = true
    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Brand.brandGradient)
                    .frame(width: 34, height: 34)
                    .shadow(color: Brand.teal.opacity(0.5), radius: 10)
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            if showText {
                (Text("Trip").foregroundStyle(.white)
                 + Text("Forge").foregroundStyle(Brand.tealLight))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
        }
    }
}

struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
    }
}

// A selectable pill chip.
struct Chip: View {
    let label: String
    let selected: Bool
    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(selected ? Brand.tealLight : Color(hex: 0xCBD5E1))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(selected ? Brand.teal.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(selected ? Brand.teal.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// Simple flow layout so chips wrap onto multiple lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubview]] = [[]]
        var x: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([]); x = 0
            }
            rows[rows.count - 1].append(sub)
            x += size.width + spacing
        }
        var height: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight + spacing
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            _ = maxWidth
        }
    }
}

// UIKit share sheet bridge (for .ics export).
import UIKit
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
