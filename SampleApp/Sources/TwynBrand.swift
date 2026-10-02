import SwiftUI

/// Twyn Brand DNA tokens (v1.3).
enum TwynBrand {
    static let signal  = Color(hex: 0x77CDCF)
    static let accent  = Color(hex: 0xA75FE3)
    static let ink     = Color(hex: 0x0A2431)
    static let paper   = Color(hex: 0xE9F3F0)
    static let success = Color(hex: 0x2E9B58)
    static let warning = Color(hex: 0xEDB335)
    static let error   = Color(hex: 0xD2284A)
    static let border  = Color(hex: 0x0A2431).opacity(0.12)
    static let inkSoft = Color(hex: 0x0A2431).opacity(0.60)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

/// Pill button in the brand style (Signal background, Ink text).
struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(TwynBrand.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(TwynBrand.signal)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
