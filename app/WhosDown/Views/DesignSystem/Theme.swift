import SwiftUI

/// Color tokens (D34, D35). Views use these, never raw colors (1.26 rule 2).
/// Light mode only in V1; V2 adds dark values here without touching screens.
/// Values approximate the Figma hi-fi page "03 — Hi-Fi Full Marks"; 1.26 audits them.
extension Color {
    static let onBrand = Color.white
    static let brand = Color.accentColor
    static let brandSoft = Color(red: 0.89, green: 0.97, blue: 0.91)
    static let surface = Color.white
    static let background = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let textPrimary = Color(red: 0.07, green: 0.09, blue: 0.15)
    static let textSecondary = Color(red: 0.42, green: 0.45, blue: 0.50)
    static let border = Color(red: 0.90, green: 0.91, blue: 0.92)
    static let destructive = Color(red: 0.86, green: 0.15, blue: 0.15)
    static let info = Color(red: 0.15, green: 0.39, blue: 0.92)

    // One color per RSVP status, used everywhere (1.14).
    static let statusPending = Color(red: 0.79, green: 0.54, blue: 0.02)
    static let statusPendingSoft = Color(red: 1.00, green: 0.97, blue: 0.86)
    static let statusApproved = Color.brand
    static let statusApprovedSoft = Color.brandSoft
    static let statusDeclined = Color.destructive
    static let statusDeclinedSoft = Color(red: 1.00, green: 0.93, blue: 0.93)
    static let statusWaitlisted = Color(red: 0.92, green: 0.45, blue: 0.05)
    static let statusWaitlistedSoft = Color(red: 1.00, green: 0.95, blue: 0.89)
}

/// Spacing on the shared 8-point grid (1.26 rule 1). No raw numbers in views.
enum Spacing {
    static let none: CGFloat = 0
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 16
    static let m: CGFloat = 24
    static let l: CGFloat = 32
    static let xl: CGFloat = 48
}

enum Radius {
    static let card: CGFloat = 16
    static let button: CGFloat = 14
    static let chip: CGFloat = 999
}
