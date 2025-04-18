//
//  MouseImageView.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Maus-Image mit interaktiven Button-Punkten
struct MouseImageView: View {
    /// Aktive Tastenzuordnungen
    var buttonMappings: [Int: String]
    
    /// Verfügbare Aktionen nach Kategorien
    var availableActions: [String: [String]]
    
    /// Callback bei Änderung einer Tastenzuordnung
    var onButtonMappingChanged: ((Int, String) -> Void)?
    
    /// Name des Mausbilds
    var imageName: String = "MouseTop"
    
    var body: some View {
        ZStack {
            // Mausbild
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 300)
            
            // Interaktive Tastenpunkte
            VStack {
                // Links- und Rechtsklick
                HStack(spacing: 80) {
                    buttonMappingView(for: 1)
                        .offset(y: -50)
                    
                    buttonMappingView(for: 2)
                        .offset(y: -50)
                }
                
                // Mausrad-Klick
                buttonMappingView(for: 3)
                    .offset(y: -30)
                
                // Seitentasten
                HStack(spacing: 280) {
                    buttonMappingView(for: 4)
                        .offset(y: 20)
                    
                    buttonMappingView(for: 5)
                        .offset(y: 20)
                }
            }
        }
    }
    
    /// Erstellt eine ButtonMappingView für die angegebene Taste
    private func buttonMappingView(for button: Int) -> some View {
        let action = buttonMappings[button] ?? "Nicht belegt"
        
        return ButtonMappingView(
            button: button,
            action: action,
            availableActions: availableActions,
            onSelect: { newAction in
                onButtonMappingChanged?(button, newAction)
            }
        )
    }
}

/// Vorschau für MouseImageView
struct MouseImageView_Previews: PreviewProvider {
    static var previews: some View {
        MouseImageView(
            buttonMappings: [
                1: "Linksklick",
                2: "Rechtsklick",
                3: "Mittlere Taste",
                4: "Zurück",
                5: "Vorwärts"
            ],
            availableActions: StandardButtonMappings.actionsbyCategory,
            onButtonMappingChanged: { button, action in
                print("Button \(button): \(action)")
            }
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color("BackgroundColor"))
        .preferredColorScheme(.dark)
    }
}
