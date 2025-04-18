//
//  ToggleSwitch.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Benutzerdefinierter Schalter (Toggle)
struct ToggleSwitch: View {
    /// Binding für den Status des Schalters
    @Binding var isOn: Bool
    
    /// Titel des Schalters
    var title: String
    
    /// Beschreibung des Schalters (optional)
    var description: String?
    
    /// Symbol vor dem Titel (optional)
    var icon: String?
    
    /// Farbe des Schalters im aktiven Zustand
    var activeColor: Color = .blue
    
    /// Callback bei Änderung des Status
    var onChange: ((Bool) -> Void)?
    
    /// Animationsdauer für den Übergang
    private let animationDuration: Double = 0.2
    
    /// Track-Breite
    private let trackWidth: CGFloat = 50
    
    /// Track-Höhe
    private let trackHeight: CGFloat = 28
    
    /// Durchmesser des Knopfes
    private let thumbDiameter: CGFloat = 22
    
    var body: some View {
        HStack {
            // Icon und Titel
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(isOn ? activeColor : .secondary)
                    }
                    
                    Text(title)
                        .font(.headline)
                }
                
                // Beschreibung (wenn vorhanden)
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Benutzerdefinierter Schalter
            ZStack {
                // Track (Hintergrund)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(isOn ? activeColor : Color("ControlBackground"))
                    .frame(width: trackWidth, height: trackHeight)
                    .animation(.easeOut(duration: animationDuration), value: isOn)
                
                // Thumb (Knopf)
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .offset(x: isOn ? (trackWidth / 2 - thumbDiameter / 2) : -(trackWidth / 2 - thumbDiameter / 2))
                    .animation(.spring(response: animationDuration, dampingFraction: 0.7), value: isOn)
            }
            .frame(width: trackWidth, height: trackHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                // Status umschalten
                isOn.toggle()
                
                // Callback auslösen
                onChange?(isOn)
            }
        }
    }
}

/// Konfiguration für großen ToggleSwitch mit Header
struct ToggleSwitchConfig {
    var title: String
    var isOn: Binding<Bool>
    var icon: String?
    var description: String?
    var activeColor: Color = .blue
    var onChange: ((Bool) -> Void)?
}

/// Abschnitt mit mehreren ToggleSwitch-Elementen
struct ToggleSwitchSection: View {
    /// Titel des Abschnitts
    var sectionTitle: String?
    
    /// Konfigurationen für die Schalter
    var toggles: [ToggleSwitchConfig]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Abschnittsüberschrift (wenn vorhanden)
            if let title = sectionTitle {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)
            }
            
            // Schalter
            ForEach(0..<toggles.count, id: \.self) { index in
                let config = toggles[index]
                
                ToggleSwitch(
                    isOn: config.isOn,
                    title: config.title,
                    description: config.description,
                    icon: config.icon,
                    activeColor: config.activeColor,
                    onChange: config.onChange
                )
                
                if index < toggles.count - 1 {
                    Divider()
                        .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color("SectionBackground"))
        .cornerRadius(Constants.UI.mediumCornerRadius)
    }
}

/// Vorschau für den ToggleSwitch
struct ToggleSwitch_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Einfacher Toggle
            ToggleSwitch(
                isOn: .constant(true),
                title: "Motion Sync",
                onChange: { isOn in
                    print("Motion Sync: \(isOn)")
                }
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Simple Toggle")
            
            // Toggle mit Icon und Beschreibung
            ToggleSwitch(
                isOn: .constant(false),
                title: "Angle Snap",
                description: "Glättet die Mausbewegung für präziseres Zielen",
                icon: "wand.and.stars",
                onChange: { isOn in
                    print("Angle Snap: \(isOn)")
                }
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Toggle with Icon and Description")
            
            // Abschnitt mit mehreren Toggles
            ToggleSwitchSection(
                sectionTitle: "Performance-Optionen",
                toggles: [
                    ToggleSwitchConfig(
                        title: "Motion Sync",
                        isOn: .constant(true),
                        icon: "move.3d",
                        description: "Synchronisiert die Sensorbewegung für reduzierte Latenz",
                        onChange: { isOn in
                            print("Motion Sync: \(isOn)")
                        }
                    ),
                    ToggleSwitchConfig(
                        title: "Ripple Control",
                        isOn: .constant(false),
                        icon: "wave.3.right",
                        description: "Verhindert ungewollte Mausbewegungen"
                    ),
                    ToggleSwitchConfig(
                        title: "Angle Snap",
                        isOn: .constant(true),
                        icon: "wand.and.stars",
                        description: "Glättet die Mausbewegung für präziseres Zielen",
                        activeColor: .green
                    )
                ]
            )
            .padding()
            .frame(width: 400)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Toggle Section")
        }
        .padding()
        .background(Color("BackgroundColor"))
        .preferredColorScheme(.dark)
    }
}
