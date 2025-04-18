//
//  PerformanceView.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Ansicht für die Performance-Einstellungen der Maus
struct PerformanceView: View {
    @EnvironmentObject private var usbManager: USBDeviceManager
    @StateObject private var profileManager = ProfileManager.shared
    
    // Performance-Einstellungen
    @State private var motionSync: Bool = true
    @State private var rippleControl: Bool = false
    @State private var angleSnap: Bool = false
    @State private var debounceTime: Double = 3
    @State private var dpiEffect: String = "OFF"
    @State private var brightness: Double = 50
    @State private var speed: Double = 50
    
    // Windows-Einstellungen
    @State private var mouseSensitivity: Double = 10
    @State private var scrollSpeed: Double = 3
    @State private var scrollMode: String = "Zeile"
    @State private var doubleClickSpeed: Double = 480
    
    // Initialisierung der State-Variablen aus dem aktiven Profil
    private func initializeFromProfile() {
        let profile = profileManager.activeProfile
        
        motionSync = profile.motionSync
        rippleControl = profile.rippleControl
        angleSnap = profile.angleSnap
        debounceTime = Double(profile.debounceTime)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Leistungsoptionen
                HStack(spacing: 20) {
                    // Motion Sync und weitere Optionen
                    VStack(alignment: .leading, spacing: 20) {
                        // Motion Sync
                        toggleOption(
                            title: "Motion Sync",
                            isOn: $motionSync,
                            onChange: { enabled in
                                usbManager.setMotionSync(enabled: enabled)
                            }
                        )
                        
                        // Ripple Control
                        toggleOption(
                            title: "Ripple Control",
                            isOn: $rippleControl,
                            onChange: { enabled in
                                profileManager.updateSetting(\.rippleControl, value: enabled)
                            }
                        )
                        
                        // Angle Snap
                        toggleOption(
                            title: "Angle Snap",
                            isOn: $angleSnap,
                            onChange: { enabled in
                                profileManager.updateSetting(\.angleSnap, value: enabled)
                            }
                        )
                        
                        // DPI-Effekt
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DPI EFFEKT")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                dpiEffectButton(title: "Stabil", selected: dpiEffect == "Stabil")
                                dpiEffectButton(title: "Atmen", selected: dpiEffect == "Atmen")
                                dpiEffectButton(title: "OFF", selected: dpiEffect == "OFF")
                            }
                        }
                        
                        // Helligkeit
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Helligkeit")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "sun.min")
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $brightness, in: 0...100, step: 1)
                                    .disabled(dpiEffect == "OFF")
                                
                                Image(systemName: "sun.max")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Geschwindigkeit
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Geschwindigkeit")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "tortoise")
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $speed, in: 0...100, step: 1)
                                    .disabled(dpiEffect == "OFF" || dpiEffect == "Stabil")
                                
                                Image(systemName: "hare")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .frame(width: 300)
                    .padding()
                    .background(Color("SectionBackground"))
                    .cornerRadius(8)
                    
                    // Debounce-Zeit und Windows-Einstellungen
                    VStack(alignment: .leading, spacing: 20) {
                        // Debounce-Zeit
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Debounce Time")
                                .font(.headline)
                            
                            HStack {
                                Slider(value: $debounceTime, in: 0...20, step: 1) { editing in
                                    if !editing {
                                        let intValue = Int(debounceTime)
                                        profileManager.updateSetting(\.debounceTime, value: intValue)
                                    }
                                }
                                
                                Text("\(Int(debounceTime))")
                                    .frame(width: 30, alignment: .trailing)
                                    .font(.body)
                            }
                        }
                        
                        // Windows-Eigenschaften
                        Text("Windows-Eigenschaften")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        // Mausempfindlichkeit
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mausempfindlichkeit")
                                .font(.subheadline)
                            
                            HStack {
                                Image(systemName: "minus")
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $mouseSensitivity, in: 1...20, step: 1)
                                
                                Image(systemName: "plus")
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(mouseSensitivity))")
                                    .frame(width: 30, alignment: .trailing)
                                    .font(.body)
                            }
                        }
                        
                        // Scrollgeschwindigkeit
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scrollgeschwindigkeit")
                                .font(.subheadline)
                            
                            HStack {
                                Image(systemName: "minus")
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $scrollSpeed, in: 1...10, step: 1)
                                
                                Image(systemName: "plus")
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(scrollSpeed))")
                                    .frame(width: 30, alignment: .trailing)
                                    .font(.body)
                            }
                        }
                        
                        // Scrollmodus
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scrollmodus")
                                .font(.subheadline)
                            
                            HStack {
                                RadioButton(
                                    title: "Scrolle eine Seite",
                                    isSelected: scrollMode == "Seite",
                                    action: { scrollMode = "Seite" }
                                )
                                
                                Spacer()
                                
                                RadioButton(
                                    title: "Scrolle eine Zeile",
                                    isSelected: scrollMode == "Zeile",
                                    action: { scrollMode = "Zeile" }
                                )
                            }
                        }
                        
                        // Doppelklick-Geschwindigkeit
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Doppelklick-Geschwindigkeit")
                                .font(.subheadline)
                            
                            HStack {
                                Image(systemName: "tortoise")
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $doubleClickSpeed, in: 200...800, step: 10)
                                
                                Image(systemName: "hare")
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(doubleClickSpeed))")
                                    .frame(width: 40, alignment: .trailing)
                                    .font(.body)
                            }
                        }
                    }
                    .frame(minWidth: 300)
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
    
    /// Erstellt eine Toggle-Option mit Titel
    private func toggleOption(title: String, isOn: Binding<Bool>, onChange: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .onChange(of: isOn.wrappedValue) { newValue in
                    onChange(newValue)
                }
        }
    }
    
    /// Button für DPI-Effekt
    private func dpiEffectButton(title: String, selected: Bool) -> some View {
        Button(action: {
            dpiEffect = title
        }) {
            Text(title)
                .font(.body)
                .foregroundColor(selected ? .white : .secondary)
                .frame(minWidth: 60, minHeight: 30)
                .background(selected ? Color.blue : Color("ControlBackground"))
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Radio-Button-Komponente
struct RadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.blue, lineWidth: 1)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
