//
//  AppDelegate.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Cocoa
import SwiftUI

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
    
    // Handler für die Tastenzuordnung aus dem Kontextmenü
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
