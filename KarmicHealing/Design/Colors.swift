import SwiftUI

enum AppColors {
    // Основні кольори
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let accent = Color("Accent")
    
    // Фонові кольори
    static let background = Color("Background")
    static let surface = Color("Surface")
    
    // Текстові кольори
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    
    // Статусні кольори
    static let success = Color("Success")
    static let error = Color("Error")
    static let warning = Color("Warning")
    static let info = Color("Info")
    
    // Градієнти
    static let primaryGradient = LinearGradient(
        colors: [Color("Primary"), Color("PrimaryLight")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color("Accent"), Color("AccentLight")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
} 