//
//  CustomizeView.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Ansicht zur Anpassung der Maustasten und DPI-Einstellungen
struct CustomizeView: View {
    @EnvironmentObject private var usbManager: USBDeviceManager
    @StateObject private var profileManager = ProfileManager.shared
    
    // DPI-Stufen
    @State private var numberOfStages: Int = 6
    @State private var selectedStage: Int = 1
    @State private var dpiValue: Double = 1600
    
    // Initialisierung der State-Variablen aus dem aktiven Profil
    private func initializeFromProfile() {
        let profile = profileManager.activeProfile
        
        // Anzahl der DPI-Stufen
        numberOfStages = profile.dpiStages.count
        
        // Aktive DPI-Stufe
        selectedStage = profile.activeDpiStage
        
        // DPI-Wert der aktuellen Stufe
        if let dpi = profile.dpiStages[selectedStage] {
            dpiValue = Double(dpi)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // DPI-Einstellungen
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("DPI SWITCHER")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("ANZAHL DER STUFEN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Stufenanzahl-Picker
                        Menu {
                            ForEach(1...6, id: \.self) { number in
                                Button("\(number)") {
                                    numberOfStages = number
                                    updateStageCount(number)
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(numberOfStages)")
                                    .frame(width: 30, alignment: .center)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("ControlBackground"))
                            .cornerRadius(4)
                        }
                        .frame(width: 80)
                    }
                    
                    // DPI-Stufen
                    HStack(spacing: 12) {
                        ForEach(1...numberOfStages, id: \.self) { stage in
                            dpiStageButton(stage: stage)
                        }
                    }
                    
                    // DPI-Wert und Slider
                    VStack(spacing: 12) {
                        // Aktueller DPI-Wert
                        HStack {
                            Text("\(Int(dpiValue))")
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                                .frame(width: 80)
                            
                            Spacer()
                        }
                        .padding(.leading)
                        
                        // DPI-Slider
                        HStack {
                            Text("50")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $dpiValue, in: 50...Double(Settings.maxDPI), step: 10) { editing in
                                if !editing {
                                    updateDPI()
                                }
                            }
                            .accentColor(stageColor(stage: selectedStage))
                            
                            Text("\(Settings.maxDPI)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color("SectionBackground"))
                .cornerRadius(8)
                
                // Polling-Rate und Lift-Off-Distanz
                VStack(alignment: .leading, spacing: 16) {
                    // Polling-Rate
                    VStack(alignment: .leading, spacing: 8) {
                        Text("POLLING RATE")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            ForEach([125, 250, 500, 1000], id: \.self) { rate in
                                pollingRateButton(rate: rate)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Lift-Off-Distanz
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lift Off Distance")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            ForEach(Settings.liftOffDistances, id: \.self) { distance in
                                liftOffDistanceButton(distance: distance)
                            }
                        }
                    }
                }
                .padding()
                .background(Color("SectionBackground"))
                .cornerRadius(8)
                
                // Tastenzuordnung
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tastenzuordnung")
                        .font(.headline)
                    
                    // Mausbild mit interaktiven Tasten
                    ZStack {
                        // Mausbild
                        Image("MouseTop")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 300)
                        
                        // Interaktive Tastenpunkte
                        VStack {
                            // Links- und Rechtsklick
                            HStack(spacing: 80) {
                                buttonAssignmentPoint(button: 1)
                                    .offset(y: -50)
                                
                                buttonAssignmentPoint(button: 2)
                                    .offset(y: -50)
                            }
                            
                            // Mausrad
                            buttonAssignmentPoint(button: 3)
                                .offset(y: -30)
                            
                            // Seitentasten
                            HStack(spacing: 280) {
                                buttonAssignmentPoint(button: 4)
                                    .offset(y: 20)
                                
                                buttonAssignmentPoint(button: 5)
                                    .offset(y: 20)
                            }
                        }
                    }
                }
                .padding()
                .background(Color("SectionBackground"))
                .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            initializeFromProfile()
        }
    }
    
    /// Aktualisiert die Anzahl der DPI-Stufen
    private func updateStageCount(_ count: Int) {
        var profile = profileManager.activeProfile
        
        // Bestehende Stufen beibehalten und fehlende hinzufügen
        for stage in 1...count {
            if profile.dpiStages[stage] == nil {
                // Standardwert für neue Stufe setzen
                let defaultValue = stage <= Settings.defaultDPIStages.count
                    ? Settings.defaultDPIStages[stage - 1]
                    : 800 * Int(pow(2.0, Double(stage - 1)))
                
                profile.dpiStages[stage] = defaultValue
            }
        }
        
        // Überzählige Stufen entfernen
        for stage in count+1...6 {
            profile.dpiStages.removeValue(forKey: stage)
        }
        
        // Sicherstellen, dass die aktive Stufe gültig ist
        if profile.activeDpiStage > count {
            profile.activeDpiStage = count
        }
        
        // Profil aktualisieren
        profileManager.activeProfile = profile
        
        // State aktualisieren
        if selectedStage > count {
            selectedStage = count
        }
        if let dpi = profile.dpiStages[selectedStage] {
            dpiValue = Double(dpi)
        }
    }
    
    /// Aktualisiert den DPI-Wert für die aktuelle Stufe
    private func updateDPI() {
        usbManager.setDPI(dpi: Int(dpiValue), stage: selectedStage)
    }
    
    /// Liefert die Farbe für eine DPI-Stufe
    private func stageColor(stage: Int) -> Color {
        switch stage {
        case 1: return .blue
        case 2: return .blue
        case 3: return .green
        case 4: return .yellow
        case 5: return .orange
        case 6: return .pink
        default: return .gray
        }
    }
    
    /// Button für eine DPI-Stufe
    private func dpiStageButton(stage: Int) -> some View {
        let profile = profileManager.activeProfile
        let dpi = profile.dpiStages[stage] ?? Settings.defaultDPIStages.first!
        
        return VStack(spacing: 4) {
            // Farbiger Indikator
            Triangle()
                .fill(stageColor(stage: stage))
                .frame(width: 12, height: 8)
            
            // Button
            Button(action: {
                selectedStage = stage
                dpiValue = Double(dpi)
                profileManager.setActiveDPIStage(stage: stage)
            }) {
                VStack {
                    Text("DPI STAGE \(stage)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("\(dpi)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                }
                .frame(width: 100, height: 60)
                .background(selectedStage == stage ? Color.blue : Color("ControlBackground"))
                .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    /// Button für eine Polling-Rate
    private func pollingRateButton(rate: Int) -> some View {
        let isSelected = profileManager.activeProfile.pollingRate == rate
        
        return Button(action: {
            usbManager.setPollingRate(rate: rate)
        }) {
            Text("\(rate)")
                .font(.headline)
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 60, height: 40)
                .background(isSelected ? Color.blue : Color("ControlBackground"))
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Button für eine Lift-Off-Distanz
    private func liftOffDistanceButton(distance: Double) -> some View {
        let isSelected = abs(profileManager.activeProfile.liftOffDistance - distance) < 0.01
        let text = distance == 1.0 ? "1mm" : (distance < 1.0 ? "0.7mm" : "2mm")
        
        return Button(action: {
            usbManager.setLiftOffDistance(distance: distance)
        }) {
            Text(text)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 60, height: 40)
                .background(isSelected ? Color.blue : Color("ControlBackground"))
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Interaktiver Punkt für die Tastenzuordnung
    private func buttonAssignmentPoint(button: Int) -> some View {
        let profile = profileManager.activeProfile
        let mapping = profile.buttons[button]
        
        return Button(action: {
            showButtonAssignmentMenu(button: button)
        }) {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 16, height: 16)
                
                Text(mapping?.action ?? "Nicht belegt")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Zeigt das Menü zur Tastenzuordnung an
    private func showButtonAssignmentMenu(button: Int) {
        let menu = NSMenu(title: "Tastenzuordnung")
        
        // Menügruppen
        let groups = [
            "Maustasten": ["Linksklick", "Rechtsklick", "Mittlere Taste", "Zurück", "Vorwärts"],
            "DPI": ["DPI Hoch", "DPI Runter", "DPI Zyklus"],
            "Scrollen": ["Scrollrad Hoch", "Scrollrad Runter"],
            "Tastatur": ["Strg", "Shift", "Alt", "Befehlstaste", "Doppelklick"],
            "Sonstiges": ["Deaktiviert"]
        ]
        
        // Menüeinträge hinzufügen
        for (group, actions) in groups {
            // Gruppen-Header
            let headerItem = NSMenuItem(title: group, action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            menu.addItem(headerItem)
            
            // Aktionen
            for action in actions {
                let item = NSMenuItem(title: action, action: #selector(AppDelegate.handleButtonAssignment(_:)), keyEquivalent: "")
                item.target = NSApplication.shared.delegate as? AppDelegate
                item.representedObject = ["button": button, "action": action]
                menu.addItem(item)
            }
            
            // Trennlinie, außer bei der letzten Gruppe
            if group != groups.keys.sorted().last {
                menu.addItem(NSMenuItem.separator())
            }
        }
        
        // Position für das Menü bestimmen (mittels NSEvent)
        if let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: NSApplication.shared.mainWindow?.contentView ?? NSView())
        }
    }
}

/// Dreiecksform für die DPI-Stufenindikatoren
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Erweiterung des AppDelegate für die Tastenzuordnung
extension AppDelegate {
    @objc func handleButtonAssignment(_ sender: NSMenuItem) {
        guard let menuInfo = sender.representedObject as? [String: Any],
              let button = menuInfo["button"] as? Int,
              let action = menuInfo["action"] as? String else {
            return
        }
        
        // Tastenzuordnung setzen
        USBDeviceManager.shared.setButtonMapping(button: button, action: action)
    }
}
