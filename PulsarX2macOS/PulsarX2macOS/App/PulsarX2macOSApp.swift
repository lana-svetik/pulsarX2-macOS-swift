//
//  PulsarX2macOSApp.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

@main
struct PulsarX2macOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var usbManager = USBDeviceManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(usbManager)
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // Hauptmenü der Anwendung
            CommandGroup(replacing: .appInfo) {
                Button("Über Pulsar X2") {
                    appDelegate.showAboutPanel()
                }
            }
            
            CommandGroup(replacing: .newItem) {
                Button("Neues Profil") {
                    // Dialog zum Erstellen eines neuen Profils
                    appDelegate.createNewProfile()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // Bearbeitungsmenü anpassen
            CommandGroup(after: .pasteboard) {
                Button("Profil zurücksetzen") {
                    appDelegate.resetCurrentProfile()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}

// AppDelegate für systemnahe Funktionen
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Einstellungen beim Start laden
        ProfileManager.shared.loadConfig()
        
        // Fenstereinstellungen konfigurieren
        configureWindowAppearance()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Konfiguration speichern
        ProfileManager.shared.saveConfig()
    }
    
    // Konfiguriert das Erscheinungsbild des Hauptfensters
    private func configureWindowAppearance() {
        NSWindow.allowsAutomaticWindowTabbing = false
        
        if let window = NSApplication.shared.windows.first {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false
        }
    }
    
    // Zeigt den Info-Dialog an
    func showAboutPanel() {
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "Pulsar X2 macOS",
            .applicationVersion: "1.0.0",
            .credits: NSAttributedString(
                string: "Entwickelt von Svetlana Sibiryakova\nhttps://github.com/lana-svetik",
                attributes: [
                    .foregroundColor: NSColor.textColor,
                    .font: NSFont.systemFont(ofSize: 12)
                ]
            ),
            .copyright: "© 2025 Svetlana Sibiryakova"
        ]
        
        NSApplication.shared.orderFrontStandardAboutPanel(options: options)
    }
    
    // Erstellt ein neues Profil
    func createNewProfile() {
        let alert = NSAlert()
        alert.messageText = "Neues Profil erstellen"
        alert.informativeText = "Bitte wählen Sie eine Profilnummer (1-4):"
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.placeholderString = "Profilnummer"
        
        alert.accessoryView = inputTextField
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Abbrechen")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let profileID = inputTextField.stringValue, !profileID.isEmpty {
                ProfileManager.shared.createProfile(profileId: profileID, setActive: true)
            }
        }
    }
    
    // Setzt das aktuelle Profil zurück
    func resetCurrentProfile() {
        let alert = NSAlert()
        alert.messageText = "Profil zurücksetzen"
        alert.informativeText = "Möchten Sie das aktuelle Profil wirklich auf Standardwerte zurücksetzen?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Zurücksetzen")
        alert.addButton(withTitle: "Abbrechen")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let activeProfileId = ProfileManager.shared.configuration.activeProfile
            ProfileManager.shared.resetProfile(profileId: activeProfileId)
        }
    }
}
