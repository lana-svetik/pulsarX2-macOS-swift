//
//  MainWindowController.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Cocoa
import SwiftUI
import Combine

/// Controller für das Hauptfenster der Anwendung
class MainWindowController: NSWindowController {
    /// Der aktuelle USB-Status der Maus
    @Published var usbStatus: ConnectionStatus = .disconnected
    
    /// Referenz zum USBDeviceManager
    private let usbManager = USBDeviceManager.shared
    
    /// Referenz zum ProfileManager
    private let profileManager = ProfileManager.shared
    
    /// Cancellables für Combine-Abonnements
    private var cancellables = Set<AnyCancellable>()
    
    /// Wird aufgerufen, wenn das Fenster geladen wurde
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Fenstereinstellungen konfigurieren
        configureWindow()
        
        // Abonnements einrichten
        setupSubscriptions()
        
        // Status aktualisieren
        updateConnectionStatus()
        
        // Konfiguration laden
        loadConfiguration()
    }
    
    /// Konfiguriert die Fenstereinstellungen
    private func configureWindow() {
        guard let window = window else { return }
        
        // Fenstereinstellungen
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.styleMask.insert(.fullSizeContentView)
        
        // Minimale Fenstergröße festlegen
        window.minSize = NSSize(width: Constants.UI.minWindowSize.width,
                                height: Constants.UI.minWindowSize.height)
        
        // Window-Buttons anpassen
        configureWindowButtons()
        
        // Fenster ins Zentrum des Bildschirms positionieren
        window.center()
    }
    
    /// Konfiguriert die Window-Buttons (Schließen, Minimieren, Maximieren)
    private func configureWindowButtons() {
        guard let window = window else { return }
        
        // Standardbuttons sichtbar machen
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
        
        // Button-Einstellungen anpassen
        [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton].forEach { buttonType in
            if let button = window.standardWindowButton(buttonType) {
                button.frame.origin.y = 5
            }
        }
    }
    
    /// Richtet Abonnements für verschiedene Events ein
    private func setupSubscriptions() {
        // Verbindungsstatus-Änderungen
        usbManager.devicesPublisher
            .sink { [weak self] _ in
                self?.updateConnectionStatus()
            }
            .store(in: &cancellables)
        
        // Benachrichtigungen abonnieren
        NotificationCenter.default.publisher(for: .deviceConnected)
            .sink { [weak self] _ in
                self?.handleDeviceConnected()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .deviceDisconnected)
            .sink { [weak self] _ in
                self?.handleDeviceDisconnected()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .batteryLevelChanged)
            .sink { [weak self] notification in
                if let level = notification.userInfo?["level"] as? Int {
                    self?.handleBatteryLevelChanged(level: level)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .profileChanged)
            .sink { [weak self] _ in
                self?.handleProfileChanged()
            }
            .store(in: &cancellables)
    }
    
    /// Aktualisiert den Verbindungsstatus
    private func updateConnectionStatus() {
        DispatchQueue.main.async { [weak self] in
            if self?.usbManager.connectedDevices.isEmpty ?? true {
                self?.usbStatus = .disconnected
            } else {
                self?.usbStatus = .connected
            }
        }
    }
    
    /// Lädt die Konfiguration
    private func loadConfiguration() {
        profileManager.loadConfig()
    }
    
    /// Behandelt ein Device-Connected-Ereignis
    private func handleDeviceConnected() {
        DispatchQueue.main.async { [weak self] in
            self?.usbStatus = .connected
            
            // Laden der aktuellen Einstellungen vom Gerät
            // In einer echten Implementierung würde hier die Verbindung mit dem Gerät eingerichtet
            
            // Benachrichtigung anzeigen
            self?.showNotification(
                title: "Pulsar X2 verbunden",
                message: "Die Verbindung zur Maus wurde hergestellt."
            )
        }
    }
    
    /// Behandelt ein Device-Disconnected-Ereignis
    private func handleDeviceDisconnected() {
        DispatchQueue.main.async { [weak self] in
            self?.usbStatus = .disconnected
            
            // Benachrichtigung anzeigen
            self?.showNotification(
                title: "Pulsar X2 getrennt",
                message: "Die Verbindung zur Maus wurde getrennt."
            )
        }
    }
    
    /// Behandelt eine Änderung des Batteriestands
    private func handleBatteryLevelChanged(level: Int) {
        // Niedrigen Batteriestand prüfen
        if level <= 10 {
            showNotification(
                title: "Niedriger Batteriestand",
                message: "Der Batteriestand der Maus ist auf \(level)% gesunken."
            )
        }
    }
    
    /// Behandelt eine Profiländerung
    private func handleProfileChanged() {
        // UI aktualisieren, falls nötig
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
    
    /// Zeigt eine Benachrichtigung an
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    /// Öffnet den Dialog zum Erstellen eines neuen Profils
    func showCreateProfileDialog() {
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
                profileManager.createProfile(profileId: profileID, setActive: true)
            }
        }
    }
    
    /// Öffnet den Dialog zum Zurücksetzen des aktuellen Profils
    func showResetProfileDialog() {
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
    
    /// Öffnet den Dialog zum Exportieren eines Profils
    func showExportProfileDialog() {
        // Datei-Dialog zum Speichern erstellen
        let savePanel = NSSavePanel()
        savePanel.title = "Profil exportieren"
        savePanel.nameFieldStringValue = "pulsar_profile.json"
        savePanel.allowedFileTypes = ["json"]
        savePanel.canCreateDirectories = true
        
        savePanel.begin { [weak self] result in
            if result == .OK, let url = savePanel.url {
                // Profil exportieren
                if let jsonString = MouseSettings.shared.exportSettings(),
                   let data = jsonString.data(using: .utf8) {
                    do {
                        try data.write(to: url)
                        self?.showNotification(
                            title: "Profil exportiert",
                            message: "Das Profil wurde erfolgreich exportiert."
                        )
                    } catch {
                        Logger.error("Fehler beim Exportieren des Profils: \(error)")
                        self?.showErrorAlert(message: "Das Profil konnte nicht exportiert werden: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Öffnet den Dialog zum Importieren eines Profils
    func showImportProfileDialog() {
        // Datei-Dialog zum Öffnen erstellen
        let openPanel = NSOpenPanel()
        openPanel.title = "Profil importieren"
        openPanel.allowedFileTypes = ["json"]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { [weak self] result in
            if result == .OK, let url = openPanel.url {
                do {
                    let data = try Data(contentsOf: url)
                    if let jsonString = String(data: data, encoding: .utf8) {
                        if MouseSettings.shared.importSettings(from: jsonString) {
                            self?.showNotification(
                                title: "Profil importiert",
                                message: "Das Profil wurde erfolgreich importiert."
                            )
                        } else {
                            self?.showErrorAlert(message: "Das Profil konnte nicht importiert werden.")
                        }
                    }
                } catch {
                    Logger.error("Fehler beim Importieren des Profils: \(error)")
                    self?.showErrorAlert(message: "Das Profil konnte nicht gelesen werden: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Zeigt einen Fehler-Alert an
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Fehler"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        
        alert.runModal()
    }
    
    /// Öffnet das About-Panel
    func showAboutPanel() {
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "Pulsar X2 macOS",
            .applicationVersion: Constants.appVersion,
            .credits: NSAttributedString(
                string: "Entwickelt von Svetlana Sibiryakova\nhttps://github.com/lana-svetik",
                attributes: [
                    .foregroundColor: NSColor.textColor,
                    .font: NSFont.systemFont(ofSize: 12)
                ]
            ),
            .copyright: Constants.copyright
        ]
        
        NSApplication.shared.orderFrontStandardAboutPanel(options: options)
    }