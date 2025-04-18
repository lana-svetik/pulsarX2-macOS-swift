//
//  USBMonitor.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import IOKit
import IOKit.hid
import IOKit.usb
import Combine

/// Klasse zum Überwachen von USB-Geräten
class USBMonitor {
    /// Shared Instance für den Singleton-Zugriff
    static let shared = USBMonitor()
    
    /// HID-Manager für die Gerätesuche
    private var hidManager: IOHIDManager?
    
    /// Aktuell verbundene Geräte
    private(set) var connectedDevices: [IOHIDDevice] = []
    
    /// Publisher für Geräteänderungen
    private let deviceChangeSubject = PassthroughSubject<[IOHIDDevice], Never>()
    
    /// Publisher für Verbindungsänderungen (connect/disconnect)
    let deviceConnectionPublisher = PassthroughSubject<(device: IOHIDDevice, connected: Bool), Never>()
    
    /// Publisher für Eingabeereignisse von den Geräten
    let inputReportPublisher = PassthroughSubject<(device: IOHIDDevice, report: Data), Never>()
    
    /// Publisher für Verbindungsänderungen
    var devicesPublisher: AnyPublisher<[IOHIDDevice], Never> {
        return deviceChangeSubject.eraseToAnyPublisher()
    }
    
    /// Sucht nach Pulsar-Mäusen und überwacht das An- und Abstecken
    func startMonitoring() {
        Logger.info("Starte USB-Überwachung...")
        
        // HID-Manager erstellen
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        
        guard let manager = hidManager else {
            Logger.error("Fehler beim Erstellen des HID-Managers")
            return
        }
        
        // Matching-Dictionary für Pulsar X2 erstellen
        let matchingCriteria: [[String: Any]] = [
            [
                kIOHIDVendorIDKey: Settings.vendorID,
                kIOHIDProductIDKey: Settings.productID
            ],
            [
                kIOHIDVendorIDKey: Settings.vendorID,
                kIOHIDProductIDKey: Settings.productID8K
            ]
        ]
        
        // Matching-Dictionaries setzen
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingCriteria as CFArray)
        
        // Callbacks registrieren
        setupCallbacks()
        
        // Manager öffnen
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            Logger.error("Fehler beim Öffnen des HID-Managers: \(result)")
            return
        }
        
        // Scheduling für den HID-Manager
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        // Nach bereits angeschlossenen Geräten suchen
        checkForExistingDevices()
        
        Logger.info("USB-Überwachung gestartet")
    }
    
    /// Beendet die Überwachung
    func stopMonitoring() {
        guard let manager = hidManager else {
            return
        }
        
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        hidManager = nil
        connectedDevices.removeAll()
        deviceChangeSubject.send([])
        
        Logger.info("USB-Überwachung beendet")
    }
    
    /// Registriert die Callbacks für den HID-Manager
    private func setupCallbacks() {
        guard let manager = hidManager else {
            return
        }
        
        // Callback für neu angeschlossene Geräte
        let deviceMatchedCallback: IOHIDDeviceCallback = { context, result, sender, device in
            let this = Unmanaged<USBMonitor>.fromOpaque(context!).takeUnretainedValue()
            this.deviceConnected(device: device)
        }
        
        // Callback für getrennte Geräte
        let deviceRemovedCallback: IOHIDDeviceCallback = { context, result, sender, device in
            let this = Unmanaged<USBMonitor>.fromOpaque(context!).takeUnretainedValue()
            this.deviceDisconnected(device: device)
        }
        
        // Callbacks registrieren
        let deviceCallbackContext = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, deviceMatchedCallback, deviceCallbackContext)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, deviceRemovedCallback, deviceCallbackContext)
    }
    
    /// Sucht nach bereits angeschlossenen Geräten
    private func checkForExistingDevices() {
        guard let manager = hidManager, 
              let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            Logger.info("Keine Geräte gefunden")
            return
        }
        
        for device in deviceSet {
            deviceConnected(device: device)
        }
    }
    
    /// Wird aufgerufen, wenn ein Gerät angeschlossen wird
    private func deviceConnected(device: IOHIDDevice) {
        // Geräteinformationen abrufen
        let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        let productName = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unbekannt"
        
        // Prüfen, ob es sich um eine Pulsar X2 handelt
        if vendorID == Settings.vendorID &&
           (productID == Settings.productID || productID == Settings.productID8K) {
            
            // Prüfen, ob das Gerät bereits bekannt ist
            if !connectedDevices.contains(where: { $0 == device }) {
                connectedDevices.append(device)
                deviceChangeSubject.send(connectedDevices)
                
                // Callbacks für Input-Reports registrieren
                setupDeviceCallbacks(device)
                
                Logger.info("Pulsar X2 verbunden: \(productName) (PID: 0x\(String(format: "%04X", productID)))")
                
                // Event veröffentlichen
                deviceConnectionPublisher.send((device: device, connected: true))
            }
        }
    }
    
    /// Wird aufgerufen, wenn ein Gerät getrennt wird
    private func deviceDisconnected(device: IOHIDDevice) {
        // Gerät aus der Liste entfernen
        if let index = connectedDevices.firstIndex(where: { $0 == device }) {
            connectedDevices.remove(at: index)
            deviceChangeSubject.send(connectedDevices)
            
            // Geräteinformationen abrufen (falls noch verfügbar)
            let productName = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unbekannt"
            
            Logger.info("Pulsar X2 getrennt: \(productName)")
            
            // Event veröffentlichen
            deviceConnectionPublisher.send((device: device, connected: false))
        }
    }
    
    /// Richtet die Callbacks für ein Gerät ein
    private func setupDeviceCallbacks(_ device: IOHIDDevice) {
        // Callback für Input-Reports
        let inputReportCallback: IOHIDReportCallback = { context, result, sender, type, reportID, report, reportLength in
            let this = Unmanaged<USBMonitor>.fromOpaque(context!).takeUnretainedValue()
            this.handleInputReport(device: sender, reportID: reportID, report: report, reportLength: reportLength)
        }
        
        // Callback für Value-Changes (Tasten, Bewegung, etc.)
        let valueCallback: IOHIDValueCallback = { context, result, sender, value in
            let this = Unmanaged<USBMonitor>.fromOpaque(context!).takeUnretainedValue()
            this.handleDeviceValue(device: sender, value: value)
        }
        
        // Callbacks registrieren
        let callbackContext = Unmanaged.passUnretained(self).toOpaque()
        
        IOHIDDeviceRegisterInputReportCallback(
            device,
            nil,
            0,
            inputReportCallback,
            callbackContext
        )
        
        IOHIDDeviceRegisterInputValueCallback(
            device,
            valueCallback,
            callbackContext
        )
        
        // Gerät öffnen
        IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
    }
    
    /// Verarbeitet eingehende Input-Reports
    private func handleInputReport(device: IOHIDDevice, reportID: Int, report: UnsafePointer<UInt8>, reportLength: Int) {
        // Report-Daten kopieren
        let reportData = Data(bytes: report, count: reportLength)
        
        // Bei Bedarf für Debug-Zwecke protokollieren
        if Logger.isDebugEnabled {
            let hexString = reportData.map { String(format: "%02X", $0) }.joined(separator: " ")
            Logger.debug("Input-Report (ID: \(reportID)): \(hexString)")
        }
        
        // Event veröffentlichen
        inputReportPublisher.send((device: device, report: reportData))
    }
    
    /// Verarbeitet Wertänderungen (Tasten, Bewegung, etc.)
    private func handleDeviceValue(device: IOHIDDevice, value: IOHIDValue) {
        // Element-Informationen extrahieren
        guard let element = IOHIDValueGetElement(value) else {
            return
        }
        
        let elementType = IOHIDElementGetType(element)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)
        let intValue = IOHIDValueGetIntegerValue(value)
        
        // Bei Bedarf für Debug-Zwecke protokollieren
        if Logger.isDebugEnabled {
            Logger.debug("Value-Change: Type=\(elementType), UsagePage=\(usagePage), Usage=\(usage), Value=\(intValue)")
        }
        
        // Hier könnten spezifische Ereignisse verarbeitet werden, z. B. Batteriestatus-Updates
    }
    
    /// Liefert Geräteinformationen
    /// - Parameter device: HID-Gerät
    /// - Returns: Dictionary mit Geräteinformationen
    func getDeviceInfo(device: IOHIDDevice) -> [String: Any] {
        var info: [String: Any] = [:]
        
        // Standardeigenschaften abrufen
        let properties: [(String, CFString)] = [
            ("vendorID", kIOHIDVendorIDKey),
            ("productID", kIOHIDProductIDKey),
            ("serialNumber", kIOHIDSerialNumberKey),
            ("manufacturer", kIOHIDManufacturerKey),
            ("product", kIOHIDProductKey),
            ("version", kIOHIDVersionNumberKey),
            ("primaryUsage", kIOHIDPrimaryUsageKey),
            ("primaryUsagePage", kIOHIDPrimaryUsagePageKey)
        ]
        
        for (key, propKey) in properties {
            if let value = IOHIDDeviceGetProperty(device, propKey) {
                info[key] = value
            }
        }
        
        return info
    }
    
    /// Sendet einen Befehl an ein Gerät
    /// - Parameters:
    ///   - device: Zielgerät
    ///   - reportID: Report-ID
    ///   - data: Zu sendende Daten
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func sendCommand(to device: IOHIDDevice, reportID: Int, data: Data) -> Bool {
        var mutableData = data
        let result = mutableData.withUnsafeMutableBytes { pointer in
            return IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeOutput,
                CFIndex(reportID),
                pointer.baseAddress!,
                mutableData.count
            )
        }
        
        // Ergebnis prüfen
        if result != kIOReturnSuccess {
            Logger.error("Fehler beim Senden des Befehls an Gerät (Error: \(result))")
            return false
        }
        
        // Bei Bedarf für Debug-Zwecke protokollieren
        if Logger.isDebugEnabled {
            let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            Logger.debug("Befehl gesendet (ID: \(reportID)): \(hexString)")
        }
        
        return true
    }
    
    /// Sucht nach einem bestimmten Gerät
    /// - Parameters:
    ///   - vendorID: Hersteller-ID
    ///   - productID: Produkt-ID
    /// - Returns: Gefundenes Gerät oder nil
    func findDevice(vendorID: Int, productID: Int) -> IOHIDDevice? {
        return connectedDevices.first { device in
            let deviceVendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
            let deviceProductID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
            return deviceVendorID == vendorID && deviceProductID == productID
        }
    }
    
    /// Prüft, ob ein bestimmtes Gerät angeschlossen ist
    /// - Parameters:
    ///   - vendorID: Hersteller-ID
    ///   - productID: Produkt-ID
    /// - Returns: True, wenn das Gerät angeschlossen ist, sonst False
    func isDeviceConnected(vendorID: Int, productID: Int) -> Bool {
        return findDevice(vendorID: vendorID, productID: productID) != nil
    }
    
    /// Privater Initialisierer für Singleton-Pattern
    private init() {}
}

/// Erweiterung für Diagnose- und Debug-Funktionen
extension USBMonitor {
    /// Protokolliert alle angeschlossenen Geräte
    func logConnectedDevices() {
        Logger.info("Aktuell verbundene Geräte:")
        
        guard !connectedDevices.isEmpty else {
            Logger.info("- Keine Geräte verbunden")
            return
        }
        
        for (index, device) in connectedDevices.enumerated() {
            let info = getDeviceInfo(device: device)
            let vendorID = info["vendorID"] as? Int ?? 0
            let productID = info["productID"] as? Int ?? 0
            let product = info["product"] as? String ?? "Unbekannt"
            
            Logger.info("- Gerät \(index + 1): \(product) (VID: 0x\(String(format: "%04X", vendorID)), PID: 0x\(String(format: "%04X", productID)))")
        }
    }
    
    /// Führt einen Diagnosetest für alle angeschlossenen Geräte durch
    func runDiagnostics() {
        Logger.info("Starte USB-Geräte-Diagnose...")
        
        guard !connectedDevices.isEmpty else {
            Logger.info("Keine Geräte für Diagnose verfügbar")
            return
        }
        
        for device in connectedDevices {
            let info = getDeviceInfo(device: device)
            Logger.info("Diagnose für Gerät: \(info["product"] as? String ?? "Unbekannt")")
            
            // Hier würden Tests für das Gerät durchgeführt werden
            // z. B. Verbindungsqualität, Antwortzeiten, etc.
            
            // Einfacher Kommunikationstest
            let testData = Data([0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]) // Get Info
            if sendCommand(to: device, reportID: 0, data: testData) {
                Logger.info("- Kommunikationstest: Bestanden")
            } else {
                Logger.warning("- Kommunikationstest: Fehlgeschlagen")
            }
        }
        
        Logger.info("USB-Geräte-Diagnose abgeschlossen")
    }
    
    /// Überwacht den USB-Verkehr für Debugging-Zwecke
    /// - Parameter duration: Überwachungsdauer in Sekunden
    func monitorTraffic(duration: TimeInterval) {
        guard Logger.isDebugEnabled else {
            Logger.warning("Verkehrsüberwachung erfordert aktiviertes Debug-Logging")
            return
        }
        
        Logger.debug("Starte USB-Verkehrsüberwachung für \(Int(duration)) Sekunden...")
        
        // Temporäre Erhöhung des Logging-Levels
        let originalLevel = Logger.logLevel
        Logger.logLevel = .debug
        
        // Timer für das Ende der Überwachung
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            Logger.debug("USB-Verkehrsüberwachung beendet")
            Logger.logLevel = originalLevel
        }
    }
}
