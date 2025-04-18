//
//  ViewExtensions.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Erweiterungen für SwiftUI Views
extension View {
    /// Bedingte View-Modifikation
    /// - Parameters:
    ///   - condition: Bedingung für die Anwendung des Modifikators
    ///   - transform: Zu anzuwendender View-Modifikator
    /// - Returns: Modifizierte oder unveränderte View
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Fügt einen Rahmen mit bedingter Sichtbarkeit hinzu
    /// - Parameters:
    ///   - color: Rahmenfarbe
    ///   - width: Rahmenbreite
    ///   - cornerRadius: Eckenabrundung
    ///   - showBorder: Ob der Rahmen angezeigt werden soll
    /// - Returns: View mit optionalem Rahmen
    func conditionalBorder(
        color: Color = .blue,
        width: CGFloat = 1,
        cornerRadius: CGFloat = 8,
        _ showBorder: Bool = true
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
                .opacity(showBorder ? 1 : 0)
        )
    }
    
    /// Fügt einen Schatten mit Konfigurationsmöglichkeiten hinzu
    /// - Parameters:
    ///   - color: Schattenfarbe
    ///   - radius: Schattengröße
    ///   - x: Horizontale Verschiebung
    ///   - y: Vertikale Verschiebung
    /// - Returns: View mit Schatten
    func customShadow(
        color: Color = .black.opacity(0.2),
        radius: CGFloat = 4,
        x: CGFloat = 0,
        y: CGFloat = 2
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    
    /// Zentriert die View in einem Rahmen
    /// - Parameters:
    ///   - width: Breite des Rahmens
    ///   - height: Höhe des Rahmens
    /// - Returns: Zentrierte View
    func centered(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                self
                Spacer()
            }
            Spacer()
        }
        .frame(width: width, height: height)
    }
    
    /// Wendet einen Übergangseffekt an
    /// - Parameter style: Übergangsart
    /// - Returns: View mit Übergangseffekt
    func transition(_ style: AnyTransition = .opacity) -> some View {
        self.transition(style)
    }
}
