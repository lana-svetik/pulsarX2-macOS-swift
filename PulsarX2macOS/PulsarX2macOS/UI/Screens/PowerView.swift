//
//  PowerView.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Ansicht für die Energiesparoptionen der Maus
struct PowerView: View {
    @EnvironmentObject private var usbManager: USBDeviceManager
    @StateObject private var profileManager = ProfileManager.shared
    
    // Energiesparoptionen
    @State private var idleTime: Double = 30
    @State private var batteryThreshold: Double = 10
    
    // Initialisierung der State-Variablen aus dem aktiven Profil
    private func initializeFromProfile() {
        let profile = profileManager.activeProfile
        
        idleTime = Double(profile.powerSaving.idleTime)
        batteryThreshold = Double(profile.powerSaving.lowBatteryThreshold)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Kabellose Energiesparfunktion
                VStack(alignment: .leading, spacing: 16) {
                    // Überschrift mit Symbol
                    HStack {
                        Image(systemName: "bolt")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        Text("KABELLOSE ENERGIESPARFUNKTION")
                            .font(.headline)
                    }
                    
                    // Beschreibung
                    Text("Diese Funktion ermöglicht es Ihnen, festzulegen, wie lange die Maus im Leerlauf bleibt, bevor sie in den Ruhemodus wechselt.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    // Slider für Leerlaufzeit
                    VStack(spacing: 8) {
                        // Aktueller Wert
                        HStack {
                            if idleTime < 60 {
                                Text("\(Int(idleTime))s")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(width: 50, alignment: .center)
                                    .padding(.horizontal, 8)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            } else {
                                let minutes = Int(idleTime) / 60
                                Text("\(minutes)min")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(width: 50, alignment: .center)
                                    .padding(.horizontal, 8)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        
                        // Slider
                        HStack {
                            Text("30s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $idleTime, in: 30...900, step: 30) { editing in
                                if !editing {
                                    updateIdleTime()
                                }
                            }
                            .accentColor(.blue)
                            
                            Text("15min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color("SectionBackground"))
                .cornerRadius(8)
                
                // Batteriesparfunktion
                VStack(alignment: .leading, spacing: 16) {
                    // Überschrift mit Symbol
                    HStack {
                        Image(systemName: "battery.25")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        Text("BATTERIESPARFUNKTION")
                            .font(.headline)
                    }
                    
                    // Beschreibung
                    Text("Wenn der Batteriestand unter den angegebenen Prozentsatz (%) fällt, wird dieser Modus aktiviert.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    // Slider für Batterieschwellwert
                    VStack(spacing: 8) {
                        // Aktueller Wert
                        HStack {
                            Text("\(Int(batteryThreshold))%")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(width: 50, alignment: .center)
                                .padding(.horizontal, 8)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        // Slider
                        HStack {
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $batteryThreshold, in: 5...20, step: 1) { editing in
                                if !editing {
                                    updateBatteryThreshold()
                                }
                            }
                            .accentColor(.blue)
                            
                            Text("20")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color("SectionBackground"))
                .cornerRadius(8)
                
                // Aktuelle Batterieanzeige
                if usbManager.isWireless {
                    VStack(alignment: .leading, spacing: 16) {
                        // Überschrift mit Symbol
                        HStack {
                            Image(systemName: batteryIcon)
                                .font(.title)
                                .foregroundColor(batteryColor)
                            
                            Text("AKTUELLER BATTERIESTAND")
                                .font(.headline)
                        }
                        
                        // Batteriestatus-Anzeige
                        HStack {
                            // Batteriebalken
                            ZStack(alignment: .leading) {
                                // Hintergrund
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 20)
                                    .cornerRadius(4)
                                
                                // Füllstand
                                Rectangle()
                                    .fill(batteryColor)
                                    .frame(width: CGFloat(usbManager.batteryLevel) / 100.0 * 300, height: 20)
                                    .cornerRadius(4)
                                
                                // Prozentwert
                                Text("\(usbManager.batteryLevel)%")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.leading, 8)
                            }
                            .frame(width: 300)
                            
                            // Status-Text
                            Text(batteryStatusText)
                                .font(.body)
                                .foregroundColor(batteryColor)
                                .frame(width: 100, alignment: .trailing)
                        }
                    }
                    .padding()
                    .background(Color("SectionBackground"))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .onAppear {
            initializeFromProfile()
        }
    }
    
    /// Aktualisiert die Leerlaufzeit
    private func updateIdleTime() {
        let intValue = Int(idleTime)
        usbManager.setPowerSaving(idleTime: intValue)
    }
    
    /// Aktualisiert den Batterieschwellwert
    private func updateBatteryThreshold() {
        let intValue = Int(batteryThreshold)
        usbManager.setPowerSaving(idleTime: Int(idleTime), batteryThreshold: intValue)
    }
    
    /// Berechnet die Farbe basierend auf dem Batteriestand
    private var batteryColor: Color {
        let level = usbManager.batteryLevel
        if level > 50 {
            return .green
        } else if level > 20 {
            return .yellow
        } else {
            return .red
        }
    }
    
    /// Liefert das passende Batterie-Icon
    private var batteryIcon: String {
        let level = usbManager.batteryLevel
        if level > 75 {
            return "battery.100"
        } else if level > 50 {
            return "battery.75"
        } else if level > 25 {
            return "battery.50"
        } else if level > 10 {
            return "battery.25"
        } else {
            return "battery.0"
        }
    }
    
    /// Liefert einen beschreibenden Text für den Batteriestatus
    private var batteryStatusText: String {
        let level = usbManager.batteryLevel
        if level > 75 {
            return "Ausgezeichnet"
        } else if level > 50 {
            return "Gut"
        } else if level > 25 {
            return "Mittel"
        } else if level > 10 {
            return "Niedrig"
        } else {
            return "Kritisch"
        }
    }
}
