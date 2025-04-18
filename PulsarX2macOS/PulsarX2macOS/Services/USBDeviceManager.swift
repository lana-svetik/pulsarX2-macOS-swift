//
//  USBDeviceManager.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import IOKit.hid
import Combine

/// Status der Verbindung zur Maus
enum ConnectionStatus {
    case connected
    case disconnected
    case error(String)
}

/// Manager-Klasse für die USB-Kommunikation mit der Pulsar X2 Maus
class USBDeviceManager: ObservableObject {
    /// Shared Instance für den Singleton-Zugriff
    static let shared = USBDeviceManager()
    
    /// Aktueller Verbindungsstatus
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    
    /// Aktueller Batteriestand in Prozent (0-100)
    @Published private(set) var batteryLevel: Int = 100
    
    /// Aktuelle Verbindungsart (kabellos/kabelgebunden)
    @Published private(set) var isWireless: Bool = true
    
    /// HID-Manager für die Gerätesuche
    private var hidManager: IOHIDManager?
    
    /// Aktuelles Gerät
    private var device: IOHIDDevice?
    
    /// Debug-Modus
    private let debugMode: Bool
    
    /// Privater Initialisierer für Singleton-Pattern
    private init(debugMode: Bool = false) {
        self.debugMode = debugMode
        setupHIDManager()
    }
    
    /// Richtet den HID-Manager ein und startet die Gerätesuche
    private func setupHIDManager() {
        // Im Debug-Modus nicht mit tatsächlicher Hardware kommunizieren
        if debugMode {
            connectionStatus = .connected
            print("Debug-Modus: Simulierte Verbindung zur Pulsar X2 hergestellt")
            return
        }
        
        // HID-Manager erstellen
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = hidManager else {
            connectionStatus = .error("Fehler beim Erstellen des HID-Managers")
            return
        }
        
        // Matching-Dictionary für Pulsar X2
        let matchingDict: CFDictionary = [
            kIOHIDVendorIDKey: Settings.vendorID,
            kIOHIDProductIDKey: [Settings.productID, Settings.productID8K]
        ] as CFDictionary
        
        // Matching-Dictionary setzen
        IOHIDManagerSetDeviceMatching(manager, matchingDict)
        
        // Callbacks registrieren
        setupCallbacks()
        
        // HID-Manager öffnen
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            connectionStatus = .error("Fehler beim Öffnen des HID-Managers: \(result)")
            return
        }
        
        // Scheduling für den HID-Manager
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        // Nach vorhandenen Geräten suchen
        checkForExistingDevices()
    }
    
    /// Registriert die Callbacks für den HID-Manager
    private func setupCallbacks() {
        guard let manager = hidManager else { return }
        
        // Callback für neu angeschlossene Geräte
        let deviceMatchedCallback: IOHIDDeviceCallback = { context, result, sender, device in
            let this = Unmanaged<USBDeviceManager>.fromOpaque(context!).takeUnretainedValue()
            this.deviceConnected(device: device)
        }
        
        // Callback für getrennte Geräte
        let deviceRemovedCallback: IOHIDDeviceCallback = { context, result, sender, device in
            let this = Unmanaged<USBDeviceManager>.fromOpaque(context!).takeUnretainedValue()
            this.deviceDisconnected(device: device)
        }
        
        // Callbacks registrieren
        let deviceCallbackContext = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, deviceMatchedCallback, deviceCallbackContext)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, deviceRemovedCallback, deviceCallbackContext)
    }
    
    /// Sucht nach bereits angeschlossenen Geräten
    private func checkForExistingDevices() {
        guard let manager = hidManager else { return }
        
        guard let deviceSet = IOHIDManagerCopyDevices(manager) else {
            print("Keine Geräte gefunden")
            return
        }
        
        let devices = deviceSet as! Set<IOHIDDevice>
        if !devices.isEmpty {
            for device in devices {
                deviceConnected(device: device)
            }
        } else {
            print("Keine Pulsar X2 Geräte gefunden")
        }
    }
    
    /// Wird aufgerufen, wenn ein Gerät angeschlossen wird
    private func deviceConnected(device: IOHIDDevice) {
        // Geräteinformationen abrufen
        let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        
        // Prüfen, ob es sich um eine Pulsar X2 handelt
        if vendorID == Settings.vendorID && 
           (productID == Settings.productID || productID == Settings.productID8K) {
            self.device = device
            
            // Verbindungstyp feststellen
            let isHighPolling = (productID == Settings.productID8K)
            let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Pulsar X2"
            
            print("Pulsar X2 verbunden: \(name) (8K: \(isHighPolling))")
            
            // Input-Reports registrieren
            setupDeviceReports(device)
            
            // Verbindungsstatus aktualisieren
            DispatchQueue.main.async {
                self.connectionStatus = .connected
                
                // Geräteinformationen abrufen
                self.getDeviceInfo()
            }
        }
    }
    
    /// Wird aufgerufen, wenn ein Gerät getrennt wird
    private func deviceDisconnected(device: IOHIDDevice) {
        if self.device == device {
            self.device = nil
            
            DispatchQueue.main.async {
                self.connectionStatus = .disconnected
                print("Pulsar X2 getrennt")
            }
        }
    }
    
    /// Richtet die Input-Reports für das Gerät ein
    private func setupDeviceReports(_ device: IOHIDDevice) {
        // Input-Report-Callback
        let inputReportCallback: IOHIDReportCallback = { context, result, sender, type, reportID, report, reportLength in
            let this = Unmanaged<USBDeviceManager>.fromOpaque(context!).takeUnretainedValue()
            this.handleInputReport(reportID: reportID, report: report, reportLength: reportLength)
        }
        
        // Callback registrieren
        let reportCallbackContext = Unmanaged.passRetained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(
            device,
            nil,
            0,
            inputReportCallback,
            reportCallbackContext
        )
    }
    
    /// Verarbeitet eingehende Input-Reports
    private func handleInputReport(reportID: Int, report: UnsafePointer<UInt8>, reportLength: Int) {
        // Hier würden die verschiedenen Report-Typen verarbeitet
        // z.B. Batteriestatus, DPI-Änderungen, etc.
        
        // Beispiel für Batteriestatus-Update
        if reportID == 0x01 && reportLength >= 2 {
            let battery = Int(report[1])
            DispatchQueue.main.async {
                self.batteryLevel = battery
            }
        }
    }
    
    /// Sendet einen Befehl an die Maus
    /// - Parameters:
    ///   - command: Befehl als Byte-Array
    ///   - expectResponse: Ob eine Antwort erwartet wird
    ///   - timeout: Timeout in Millisekunden
    /// - Returns: Die Antwort der Maus oder nil bei Fehler/Timeout
    func sendCommand(_ command: [UInt8], expectResponse: Bool = true, timeout: Int = 300) -> [UInt8]? {
        // Im Debug-Modus keine tatsächlichen Befehle senden
        if debugMode {
            let cmdString = command.map { String(format: "%02x", $0) }.joined(separator: " ")
            print("DEBUG - Befehl senden: \(cmdString)")
            
            // Im Debug-Modus eine Dummy-Antwort zurückgeben
            return expectResponse ? Array(repeating: 0, count: 8) : nil
        }
        
        guard let device = device else {
            print("Keine Verbindung zur Maus. Befehl kann nicht gesendet werden.")
            return nil
        }
        
        // Befehl als Output-Report senden
        var mutableCommand = command
        let commandLength = mutableCommand.count
        
        let result = mutableCommand.withUnsafeMutableBufferPointer { pointer in
            return IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeOutput,
                CFIndex(0), // reportID
                pointer.baseAddress!,
                CFIndex(commandLength)
            )
        }
        
        if result != kIOReturnSuccess {
            print("Fehler beim Senden des Befehls: \(result)")
            return nil
        }
        
        let cmdString = command.map { String(format: "%02x", $0) }.joined(separator: " ")
        print("Befehl gesendet: \(cmdString)")
        
        if !expectResponse {
            return nil
        }
        
        // Auf Antwort warten und zurückgeben
        // (vereinfacht - in einer echten Implementierung würde man hier auf einen Input-Report warten)
        let response = Array(repeating: UInt8(0), count: 8)
        return response
    }
    
    /// Ruft Informationen über die Maus ab
    func getDeviceInfo() {
        let response = sendCommand(USBCommands.cmdGetInfo)
        
        if let response = response {
            // Beispielhafte Interpretation der Antwort
            print("Geräteinformationen:")
            print("Firmware-Version: \(response[1]).\(response[2])")
            print("Hardware-Revision: \(response[3])")
            print("Aktives Profil: \(response[4])")
            
            // Wireless-Status aus der Antwort extrahieren (hypothetisch)
            self.isWireless = (response[5] & 0x01) != 0
        } else {
            print("Keine Geräteinformationen verfügbar.")
        }
    }
    
    /// Setzt die DPI für eine bestimmte Stufe
    /// - Parameters:
    ///   - dpi: DPI-Wert
    ///   - stage: DPI-Stufe (1-6)
    func setDPI(dpi: Int, stage: Int) {
        let command = USBCommands.setDPI(dpi: dpi, stage: stage)
        _ = sendCommand(command, expectResponse: false)
        
        // Auch im Profil speichern
        ProfileManager.shared.setDPI(dpi: dpi, stage: stage)
    }
    
    /// Setzt die Polling-Rate
    /// - Parameter rate: Rate in Hz
    func setPollingRate(rate: Int) {
        let command = USBCommands.setPollingRate(rate: rate)
        _ = sendCommand(command, expectResponse: false)
        
        // Auch im Profil speichern
        ProfileManager.shared.updateSetting(\.pollingRate, value: rate)
    }
    
    /// Setzt die Lift-Off-Distanz
    /// - Parameter distance: Distanz in mm
    func setLiftOffDistance(distance: Double) {
        let command = USBCommands.setLiftOffDistance(distance: distance)
        _ = sendCommand(command, expectResponse: false)
        
        // Auch im Profil speichern
        ProfileManager.shared.updateSetting(\.liftOffDistance, value: distance)
    }
    
    /// Weist einer Taste eine Aktion zu
    /// - Parameters:
    ///   - button: Tastennummer (1-5)
    ///   - action: Aktionsname
    func setButtonMapping(button: Int, action: String) {
        guard let code = Settings.buttonActions[action] else {
            print("Ungültige Aktion: \(action)")
            return
        }
        
        let command = USBCommands.setButton(button: button, action: code)
        _ = sendCommand(command, expectResponse: false)
        
        // Auch im Profil speichern
        ProfileManager.shared.setButtonMapping(button: button, action: action)
    }
    
    /// Aktiviert/Deaktiviert Motion Sync
    /// - Parameter enabled: Ob Motion Sync aktiviert werden soll
    func setMotionSync(enabled: Bool) {
        let command = USBCommands.setMotionSync(enabled: enabled)
        _ = sendCommand(command, expectResponse: false)
        
        // Auch im Profil speichern
        ProfileManager.shared.updateSetting(\.motionSync, value: enabled)
    }
    
    /// Setzt die Energiesparoptionen
    /// - Parameters:
    ///   - idleTime: Zeit in Sekunden, bevor die Maus in den Ruhemodus wechselt
    ///   - batteryThreshold: Optional, Prozentwert für den Low-Battery-Modus
    func setPowerSaving(idleTime: Int, batteryThreshold: Int? = nil) {
        let command = USBCommands.setPowerSaving(idleTime: idleTime, batteryThreshold: batteryThreshold)
        _ = sendCommand(command, expectResponse: false)
        
        // Auch im Profil speichern
        var powerSaving = ProfileManager.shared.activeProfile.powerSaving
        powerSaving.idleTime = idleTime
        if let threshold = batteryThreshold {
            powerSaving.lowBatteryThreshold = threshold
        }
        ProfileManager.shared.updateSetting(\.powerSaving, value: powerSaving)
    }
    
    /// Speichert die Einstellungen in einem Profil
    /// - Parameter profileNumber: Profilnummer (1-4)
    func saveToProfile(profileNumber: Int) {
        let command = USBCommands.saveProfile(profileNumber: profileNumber)
        _ = sendCommand(command, expectResponse: false)
        
        // Auch in der Konfiguration speichern
        ProfileManager.shared.setActiveProfile(profileId: String(profileNumber))
    }
}
