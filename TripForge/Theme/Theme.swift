import SwiftUI

enum Brand {
    static let teal = Color(hex: 0x0F766E)
    static let tealLight = Color(hex: 0x33BBAB)
    static let orange = Color(hex: 0xF97316)
    static let sky = Color(hex: 0x38BDF8)

    static let ink900 = Color(hex: 0x0D141B)
    static let ink850 = Color(hex: 0x111A23)
    static let ink800 = Color(hex: 0x16212C)
    static let ink700 = Color(hex: 0x1E2C39)

    static let tealGradient = LinearGradient(
        colors: [teal, tealLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let brandGradient = LinearGradient(
        colors: [teal, orange], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let aurora = LinearGradient(
        colors: [teal.opacity(0.35), sky.opacity(0.18), orange.opacity(0.28)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Reusable view modifiers / styles

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Brand.ink850.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardBackground()) }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Brand.tealGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Brand.teal.opacity(0.45), radius: 14, y: 4)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color(hex: 0xE2E8F0))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
