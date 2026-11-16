import SwiftUI
import UIKit

// MARK: - Slate & Blue Design System
public enum SlateTheme {
    // Backgrounds
    public static let background = Color(hex: "0B0F19")      // Deep slate night
    public static let surface = Color(hex: "131C2E")         // Card / container
    public static let surfaceRaised = Color(hex: "1A263D")   // Elevated card / bubble
    public static let surfaceInput = Color(hex: "162033")    // Input box background
    
    // Accents
    public static let accent = Color(hex: "3B82F6")          // Electric Slate Blue
    public static let accentHover = Color(hex: "60A5FA")     // Lighter blue
    public static let accentDark = Color(hex: "1D4ED8")      // Deep blue
    public static let indigoAccent = Color(hex: "6366F1")    // Secondary indigo
    public static let cyanAccent = Color(hex: "06B6D4")      // Study / formula cyan
    
    // Borders & Dividers
    public static let border = Color(hex: "233047")          // Subtle slate border
    public static let borderFocus = Color(hex: "3B82F6").opacity(0.6)
    
    // Text
    public static let textPrimary = Color(hex: "F8FAFC")    // Crisp white-slate
    public static let textSecondary = Color(hex: "94A3B8")  // Muted slate
    public static let textTertiary = Color(hex: "64748B")   // Darker muted
    public static let textAccent = Color(hex: "93C5FD")     // Highlighted text
    
    // Status
    public static let success = Color(hex: "10B981")
    public static let warning = Color(hex: "F59E0B")
    public static let error = Color(hex: "EF4444")
    
    // Gradients
    public static let userBubbleGradient = LinearGradient(
        colors: [Color(hex: "2563EB"), Color(hex: "1D4ED8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let headerGradient = LinearGradient(
        colors: [Color(hex: "1E293B"), Color(hex: "0F172A")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let geminiStarGradient = LinearGradient(
        colors: [Color(hex: "60A5FA"), Color(hex: "818CF8"), Color(hex: "38BDF8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptic Feedback Helper
enum Haptics {
    static func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
