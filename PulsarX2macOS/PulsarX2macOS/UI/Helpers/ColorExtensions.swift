//
//  ColorExtensions.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Erweiterungen für SwiftUI-Farben
extension Color {
    /// Erstellt eine halbtransparente Variante der Farbe
    /// - Parameter opacity: Transparenzwert (0.0 - 1.0)
    /// - Returns: Halbtransparente Farbvariante
    func withOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
    
    /// Konvertiert eine Hex-Farbcode-Zeichenkette zu einer SwiftUI-Farbe
    /// - Parameter hex: Hex-Farbcode als Zeichenkette (z.B. "#FF0000" oder "FF0000")
    /// - Returns: Entsprechende SwiftUI-Farbe
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (kurzes Format)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
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
    
    /// Erzeugt eine hellere Variante der Farbe
    /// - Parameter amount: Aufhellungsstärke (0.0 - 1.0)
    /// - Returns: Aufgehellte Farbvariante
    func lighter(by amount: CGFloat = 0.2) -> Color {
        return Color(NSColor(self).highlight(withLevel: amount) ?? NSColor(self))
    }
    
    /// Erzeugt eine dunklere Variante der Farbe
    /// - Parameter amount: Abdunklungsstärke (0.0 - 1.0)
    /// - Returns: Abgedunkelte Farbvariante
    func darker(by amount: CGFloat = 0.2) -> Color {
        return Color(NSColor(self).shadow(withLevel: amount) ?? NSColor(self))
    }
}
