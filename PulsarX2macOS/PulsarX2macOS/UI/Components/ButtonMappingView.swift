//
//  ButtonMappingView.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Komponente für die Anzeige und Zuordnung von Maustasten
struct ButtonMappingView: View {
    /// Tastennummer
    var button: Int
    
    /// Aktuelle Aktion der Taste
    var action: String
    
    /// Verfügbare Aktionen nach Kategorien
    var availableActions: [String: [String]]
    
    /// Callback bei Auswahl einer neuen Aktion
    var onSelect: ((String) -> Void)?
    
    /// Hintergrundfarbe des Punkts
    var dotColor: Color = .blue
    
    /// Position des Punkts (0=links, 0.5=mitte, 1=rechts)
    var horizontalAlignment: CGFloat = 0.5
    
    /// Position des Punkts (0=oben, 0.5=mitte, 1=unten)
    var verticalAlignment: CGFloat = 0.5
    
    /// Ist die Komponente interaktiv
    var isInteractive: Bool = true
    
    /// Ist das Kontextmenü aktuell geöffnet
    @State private var isMenuOpen: Bool = false
    
    /// Hover-Status
    @State private var isHovered: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Maustastenpunkt mit Popover-Menü
            ZStack {
                // Hintergrundkreis (größer und transparenter bei Hover oder geöffnetem Menü)
                Circle()
                    .fill(dotColor.opacity(isHovered || isMenuOpen ? 0.3 : 0.1))
                    .frame(width: isHovered || isMenuOpen ? 30 : 22, height: isHovered || isMenuOpen ? 30 : 22)
                
                // Hauptkreis
                Circle()
                    .fill(dotColor)
                    .frame(width: 16, height: 16)
            }
            .overlay(
                // Nummer der Taste
                Text("\(button)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            )
            // Interaktivität hinzufügen, wenn aktiviert
            .if(isInteractive) { view in
                view
                    .onHover { hovering in
                        isHovered = hovering
                    }
                    .onTapGesture {
                        showButtonMappingMenu()
                    }
                    .help("Taste \(button): \(action)")
            }
            
            // Aktionsname
            Text(actionLabel())
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(4)
                .fixedSize()
        }
    }
    
    /// Liefert eine gekürzte Version des Aktionsnamens
    private func actionLabel() -> String {
        if action.count > 15 {
            return String(action.prefix(12)) + "..."
        }
        return action
    }
    
    /// Zeigt das Menü zur Tastenzuordnung an
    private func showButtonMappingMenu() {
        isMenuOpen = true
        
        // NSMenu für die Tastenzuordnung erstellen
        let menu = NSMenu(title: "Tastenzuordnung")
        
        // Menügruppen aus den verfügbaren Aktionen erstellen
        for (group, actions) in availableActions.sorted(by: { $0.key < $1.key }) {
            // Gruppen-Header
            let headerItem = NSMenuItem(title: group, action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            menu.addItem(headerItem)
            
            // Aktionen
            for actionName in actions {
                let item = NSMenuItem(title: actionName, action: #selector(AppDelegate.handleButtonAssignment(_:)), keyEquivalent: "")
                item.target = NSApplication.shared.delegate as? AppDelegate
                item.representedObject = ["button": button, "action": actionName]
                menu.addItem(item)
            }
            
            // Trennlinie, außer bei der letzten Gruppe
            if group != availableActions.keys.sorted().last {
                menu.addItem(NSMenuItem.separator())
            }
        }
        
        // Position für das Menü bestimmen (mittels NSEvent)
        if let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: NSApplication.shared.mainWindow?.contentView ?? NSView())
            
            // Nach dem Schließen des Menüs den Status zurücksetzen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isMenuOpen = false
            }
        }
    }
}

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
            // Diese Positionen müssen an die tatsächliche Bildgröße angepasst werden
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

/// Button-Mapping mit Standard- und erweiterten Aktionen
struct StandardButtonMappings {
    /// Standardaktionen nach Kategorien
    static var actionsbyCategory: [String: [String]] {
        return [
            "Maustasten": ["Linksklick", "Rechtsklick", "Mittlere Taste", "Zurück", "Vorwärts"],
            "DPI": ["DPI Hoch", "DPI Runter", "DPI Zyklus"],
            "Scrollen": ["Scrollrad Hoch", "Scrollrad Runter"],
            "Tastatur": ["Strg", "Shift", "Alt", "Befehlstaste", "Doppelklick"],
            "Sonstiges": ["Deaktiviert"]
        ]
    }
    
    /// Standardaktionen für alle Tasten
    static var defaultMappings: [Int: String] {
        return [
            1: "Linksklick",
            2: "Rechtsklick",
            3: "Mittlere Taste",
            4: "Zurück",
            5: "Vorwärts"
        ]
    }
}

/// Erweiterung für bedingte Modifikatoren in SwiftUI
extension View {
    /// Wendet einen Modifikator bedingt an
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// Vorschau für die ButtonMappingView und MouseImageView
struct ButtonMappingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Einzelne Button-Mapping-Ansicht
            ButtonMappingView(
                button: 1,
                action: "Linksklick",
                availableActions: StandardButtonMappings.actionsbyCategory,
                onSelect: { action in
                    print("Button 1: \(action)")
                }
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Button Mapping")
            
            // Komplette Mausansicht mit Button-Mapping
            MouseImageView(
                buttonMappings: StandardButtonMappings.defaultMappings,
                availableActions: StandardButtonMappings.actionsbyCategory,
                onButtonMappingChanged: { button, action in
                    print("Button \(button): \(action)")
                }
            )
            .frame(height: 400)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Mouse with Button Mappings")
        }
        .padding()
        .background(Color("BackgroundColor"))
        .preferredColorScheme(.dark)
    }
}
