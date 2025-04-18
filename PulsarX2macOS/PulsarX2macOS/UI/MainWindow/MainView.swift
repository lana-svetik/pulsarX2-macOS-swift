//
//  MainView.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Hauptnavigationsseiten
enum NavigationPage: String, CaseIterable, Identifiable {
    case home = "Home"
    case customize = "Anpassen"
    case performance = "Performance"
    case macro = "Makro"
    case power = "Energieoptionen"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .customize: return "dial.max"
        case .performance: return "gauge"
        case .macro: return "keyboard"
        case .power: return "bolt"
        }
    }
}

/// Hauptansicht der Anwendung
struct MainView: View {
    @EnvironmentObject private var usbManager: USBDeviceManager
    @StateObject private var profileManager = ProfileManager.shared
    
    @State private var selectedPage: NavigationPage = .home
    @State private var isProfilePickerShown = false
    @State private var selectedLanguage = "Deutsch"
    
    var body: some View {
        NavigationView {
            // Seitenleiste
            VStack(spacing: 0) {
                // Logo
                Image("PulsarLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                
                // Navigationsmenü
                List(NavigationPage.allCases) { page in
                    NavigationLink(
                        destination: destinationView(for: page),
                        tag: page,
                        selection: $selectedPage
                    ) {
                        HStack {
                            Image(systemName: page.icon)
                                .frame(width: 24, height: 24)
                            Text(page.rawValue)
                                .fontWeight(selectedPage == page ? .bold : .regular)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(SidebarListStyle())
                
                Spacer()
                
                // Verbindungsstatus
                connectionStatusView
                    .padding(.bottom, 12)
            }
            .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)
            .background(Color("SidebarBackground"))
            
            // Hauptinhalt
            VStack {
                // Obere Leiste
                HStack {
                    Spacer()
                    
                    // Sprachauswahl
                    HStack {
                        Text("SPRACHE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Menu {
                            Button("Deutsch") {
                                selectedLanguage = "Deutsch"
                            }
                            Button("English") {
                                selectedLanguage = "English"
                            }
                        } label: {
                            HStack {
                                Text(selectedLanguage)
                                    .frame(width: 80, alignment: .leading)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(6)
                            .background(Color("ControlBackground"))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Geräteauswahl
                    HStack {
                        Text("GERÄT")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Pulsar X2")
                            if case .connected = usbManager.connectionStatus {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                Text("Verbunden")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(6)
                        .frame(width: 180)
                        .background(Color("ControlBackground"))
                        .cornerRadius(4)
                    }
                    .padding(.horizontal)
                    
                    // Profilauswahl
                    HStack {
                        Text("PROFIL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(Array(profileManager.configuration.profiles.keys.sorted()), id: \.self) { profileId in
                                Button("Profil \(profileId)") {
                                    profileManager.setActiveProfile(profileId: profileId)
                                }
                            }
                            
                            Divider()
                            
                            Button("Neues Profil...") {
                                isProfilePickerShown = true
                            }
                        } label: {
                            HStack {
                                Text("Profil \(profileManager.configuration.activeProfile)")
                                    .frame(width: 80, alignment: .leading)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(6)
                            .background(Color("ControlBackground"))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Reset-Button
                    Button(action: resetCurrentProfile) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("RESET PROFIL")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(.trailing)
                }
                .padding(.vertical, 8)
                .background(Color("HeaderBackground"))
                
                // Aktuelle Seite
                destinationView(for: selectedPage)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $isProfilePickerShown) {
            createProfileView
        }
    }
    
    /// Erstellt die passende Ansicht für die ausgewählte Seite
    private func destinationView(for page: NavigationPage) -> some View {
        Group {
            switch page {
            case .home:
                HomeView()
            case .customize:
                CustomizeView()
            case .performance:
                PerformanceView()
            case .macro:
                MacroView()
            case .power:
                PowerView()
            }
        }
    }
    
    /// Verbindungsstatusanzeige für die Seitenleiste
    private var connectionStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Verbindungsstatus-Zeile
            HStack {
                Circle()
                    .fill(usbManager.isWireless ? Color.blue : Color.gray)
                    .frame(width: 10, height: 10)
                
                Text(usbManager.isWireless ? "1K" : "Kabelgebunden")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Wireless Mode")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            // Batterieanzeige
            if usbManager.isWireless {
                HStack {
                    Image(systemName: "battery.100")
                        .foregroundColor(batteryColor)
                    
                    Text("\(usbManager.batteryLevel)%")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
            }
            
            // Verbindungsqualität
            if usbManager.isWireless && usbManager.connectionStatus == .connected {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Hervorragend")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("Wireless Connection Stability")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color("SidebarBackground"))
    }
    
    /// Berechnet die Farbe der Batterieanzeige basierend auf dem Ladezustand
    private var batteryColor: Color {
        if usbManager.batteryLevel > 50 {
            return .green
        } else if usbManager.batteryLevel > 20 {
            return .yellow
        } else {
            return .red
        }
    }
    
    /// Setzt das aktuelle Profil zurück
    private func resetCurrentProfile() {
        let alert = NSAlert()
        alert.messageText = "Profil zurücksetzen"
        alert.informativeText = "Möchten Sie das aktuelle Profil wirklich auf Standardwerte zurücksetzen?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Zurücksetzen")
        alert.addButton(withTitle: "Abbrechen")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let activeProfileId = profileManager.configuration.activeProfile
            profileManager.resetProfile(profileId: activeProfileId)
        }
    }
    
    /// Dialog zum Erstellen eines neuen Profils
    private var createProfileView: some View {
        VStack(spacing: 20) {
            Text("Neues Profil erstellen")
                .font(.title2)
                .bold()
            
            Text("Bitte wählen Sie eine Profilnummer (1-4):")
                .font(.body)
            
            Picker("Profilnummer", selection: $selectedProfileNumber) {
                ForEach(1...4, id: \.self) { number in
                    Text("Profil \(number)").tag(number)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            HStack {
                Button("Abbrechen") {
                    isProfilePickerShown = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Erstellen") {
                    profileManager.createProfile(profileId: "\(selectedProfileNumber)", setActive: true)
                    isProfilePickerShown = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(BorderedButtonStyle())
            }
            .padding()
        }
        .frame(width: 300, height: 200)
        .padding()
    }
    
    @State private var selectedProfileNumber = 1
}

/// Platzhalter für die Home-Ansicht
struct HomeView: View {
    @EnvironmentObject private var usbManager: USBDeviceManager
    
    var body: some View {
        VStack {
            // Mausbild mit Tastenzuordnungen
            ZStack {
                // Mausbild
                Image("MouseTop")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 400)
                
                // Tastenzuordnungs-Overlays
                VStack {
                    // Links- und Rechtsklick
                    HStack(spacing: 80) {
                        buttonLabel("Linksklick")
                            .offset(y: -60)
                        
                        buttonLabel("Rechtsklick")
                            .offset(y: -60)
                    }
                    
                    // Mausrad
                    buttonLabel("Rad-Klick")
                        .offset(y: -40)
                    
                    // DPI-Anzeige
                    buttonLabel("DPI LOOP")
                        .offset(y: 20)
                    
                    // Seitentasten
                    HStack(spacing: 280) {
                        buttonLabel("Ctrl Links")
                            .offset(y: 10)
                        
                        buttonLabel("Ctrl Rechts")
                            .offset(y: 10)
                    }
                }
            }
            
            Spacer()
            
            // Startoptionen
            VStack(alignment: .leading, spacing: 20) {
                startupOptionView(title: "AUTOSTART", description: "Automatisch beim Systemstart starten", isOn: false)
                startupOptionView(title: "MINIMIERT STARTEN", description: "Im Dock minimiert starten", isOn: false)
            }
            .padding()
            .background(Color("SectionBackground"))
            .cornerRadius(8)
        }
    }
    
    /// Erzeugt ein Label für eine Maustaste
    private func buttonLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    /// Erzeugt eine Startoptionszeile mit Toggle
    private func startupOptionView(title: String, description: String, isOn: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isOn))
                .labelsHidden()
        }
    }
}
