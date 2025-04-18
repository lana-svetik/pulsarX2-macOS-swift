//
//  USBProtocol.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import IOKit
import IOKit.hid
import Combine

/// Klasse für die Implementierung des USB-Kommunikationsprotokolls mit der Pulsar X2 Maus
class USBProtocol {
    /// Shared Instance für den Singleton-Zugriff
    static let shared = USBProtocol()
    
    /// USB-Monitor für die Geräteüberwachung
    private let usbMonitor = USBMonitor.shared
    
    /// Subject für Antworten auf Befehle
    private let responseSubject = PassthroughSubject<(command: USBCommand, response: Data?), Error>()
    
    /// Warteschlange für Befehle (FIFO)
    private var commandQueue: [USBCommand] = []
    
    /// Ob gerade ein Befehl verarbeitet wird
    private var isProcessingCommand = false
    
    /// Speicher für ausstehende Antwort-Callbacks
    private var pendingResponses: [UUID: (Data?) -> Void] = [:]
    
    /// Timeouts für Befehle
    private var commandTimeouts: [UUID: Timer] = [:]
    
    /// Aktives Gerät
    private var activeDevice: IOHIDDevice?
    
    /// Publisher für Antworten auf Befehle
    var responsePublisher: AnyPublisher<(command: USBCommand, response: Data?), Error> {
        return responseSubject.eraseToAnyPublisher()
    }
    
    /// Abonnements von Combine-Publishers
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialisiert das USB-Protokoll
    private init() {
        setupSubscriptions()
    }
    
    /// Richtet die Abonnements für Geräteänderungen und Input-Reports ein
    private func setupSubscriptions() {
        // Auf Geräteverbindungsänderungen reagieren
        usbMonitor.deviceConnectionPublisher
            .sink { [weak self] deviceEvent in
                if deviceEvent.connected {
                    self?.handleDeviceConnected(deviceEvent.device)
                } else {
                    self?.handleDeviceDisconnected(deviceEvent.device)
                }
            }
            .store(in: &cancellables)
        
        // Auf Input-Reports reagieren
        usbMonitor.inputReportPublisher
            .sink { [weak self] reportEvent in
                self?.handleInputReport(device: reportEvent.device, reportData: reportEvent.report)
            }
            .store(in: &cancellables)
        
        // USB-Überwachung starten
        usbMonitor.startMonitoring()
    }
    
    /// Verarbeitet neu verbundene Geräte
    private func handleDeviceConnected(_ device: IOHIDDevice) {
        let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        
        // Prüfen, ob es sich um eine Pulsar X2 handelt
        if vendorID == Settings.vendorID &&
           (productID == Settings.productID || productID == Settings.productID8K) {
            
            // Gerät als aktiv markieren
            activeDevice = device
            
            // Initialisierungssequenz starten
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.initializeDevice(device)
            }
        }
    }
    
    /// Verarbeitet getrennte Geräte
    private func handleDeviceDisconnected(_ device: IOHIDDevice) {
        if activeDevice == device {
            activeDevice = nil
            
            // Alle laufenden Befehle abbrechen
            cancelAllPendingCommands()
        }
    }
    
    /// Initialisiert ein neu verbundenes Gerät
    private func initializeDevice(_ device: IOHIDDevice) {
        Logger.info("Initialisiere Pulsar X2...")
        
        // Geräteinformationen abrufen
        let infoCommand = USBCommand(
            type: .getInfo,
            parameters: [],
            timeout: 1.0,
            expectResponse: true
        )
        
        sendCommand(infoCommand) { [weak self] response in
            if let response = response {
                self?.processDeviceInfo(response)
            } else {
                Logger.error("Fehler beim Abrufen der Geräteinformationen")
            }
        }
    }
    
    /// Verarbeitet Geräteinformationen
    private func processDeviceInfo(_ data: Data) {
        guard data.count >= 8 else {
            Logger.error("Ungültige Geräteinformationen empfangen")
            return
        }
        
        // Firmware-Version extrahieren
        let fwMajor = data[1]
        let fwMinor = data[2]
        let hwRevision = data[3]
        let activeProfile = data[4]
        
        Logger.info("Pulsar X2 initialisiert:")
        Logger.info("- Firmware: \(fwMajor).\(fwMinor)")
        Logger.info("- Hardware: Rev \(hwRevision)")
        Logger.info("- Aktives Profil: \(activeProfile)")
        
        // Aktuellen Batteriestand abrufen (falls kabellos)
        checkBatteryStatus()
    }
    
    /// Prüft den Batteriestand
    private func checkBatteryStatus() {
        let batteryCommand = USBCommand(
            type: .getBattery,
            parameters: [],
            timeout: 1.0,
            expectResponse: true
        )
        
        sendCommand(batteryCommand) { response in
            if let response = response, response.count >= 2 {
                let batteryLevel = Int(response[1])
                Logger.info("Batteriestand: \(batteryLevel)%")
                
                // Hier könnte der Batteriestand an einen Observer weitergeleitet werden
                NotificationCenter.default.post(
                    name: Notification.Name("PulsarBatteryLevelChanged"),
                    object: nil,
                    userInfo: ["level": batteryLevel]
                )
            }
        }
    }
    
    /// Verarbeitet eingehende Input-Reports
    private func handleInputReport(device: IOHIDDevice, reportData: Data) {
        // Nur Reports vom aktiven Gerät verarbeiten
        guard device == activeDevice else {
            return
        }
        
        // Report-Typ anhand des ersten Bytes identifizieren
        guard !reportData.isEmpty else {
            return
        }
        
        let reportType = reportData[0]
        
        switch reportType {
        case 0x10:  // Antwort auf GetInfo
            processResponseForCommand(type: .getInfo, data: reportData)
            
        case 0x12:  // Antwort auf GetSettings
            processResponseForCommand(type: .getSettings, data: reportData)
            
        case 0x70:  // Batteriestatus-Update
            // Bei einem spontanen Batteriestatus-Update (ohne vorherigen Befehl)
            if reportData.count >= 2 {
                let batteryLevel = Int(reportData[1])
                NotificationCenter.default.post(
                    name: Notification.Name("PulsarBatteryLevelChanged"),
                    object: nil,
                    userInfo: ["level": batteryLevel]
                )
            }
            
        case 0x80:  // Fehlerantwort
            handleErrorResponse(data: reportData)
            
        default:
            if reportData.count >= 2 {
                // Versuchen, einem ausstehenden Befehl zuzuordnen
                processResponseForAnyPendingCommand(data: reportData)
            }
        }
    }
    
    /// Ordnet eine Antwort einem ausstehenden Befehl zu
    private func processResponseForCommand(type: USBCommandType, data: Data) {
        // Suche nach einem passenden ausstehenden Befehl
        for id in pendingResponses.keys {
            if let command = commandQueue.first(where: { $0.id == id && $0.type == type }) {
                // Befehl gefunden, Antwort zuordnen
                if let callback = pendingResponses.removeValue(forKey: id) {
                    // Timeout abbrechen
                    commandTimeouts[id]?.invalidate()
                    commandTimeouts.removeValue(forKey: id)
                    
                    // Callback aufrufen
                    callback(data)
                    responseSubject.send((command: command, response: data))
                    
                    // Befehl aus der Queue entfernen
                    if let index = commandQueue.firstIndex(where: { $0.id == id }) {
                        commandQueue.remove(at: index)
                    }
                    
                    // Nächsten Befehl verarbeiten
                    isProcessingCommand = false
                    processNextCommand()
                    
                    return
                }
            }
        }
    }
    
    /// Versucht, eine Antwort einem beliebigen ausstehenden Befehl zuzuordnen
    private func processResponseForAnyPendingCommand(data: Data) {
        // Wenn es nur einen ausstehenden Befehl gibt, nehmen wir an, dass die Antwort dazu gehört
        if pendingResponses.count == 1, let id = pendingResponses.keys.first {
            if let command = commandQueue.first(where: { $0.id == id }) {
                if let callback = pendingResponses.removeValue(forKey: id) {
                    // Timeout abbrechen
                    commandTimeouts[id]?.invalidate()
                    commandTimeouts.removeValue(forKey: id)
                    
                    // Callback aufrufen
                    callback(data)
                    responseSubject.send((command: command, response: data))
                    
                    // Befehl aus der Queue entfernen
                    if let index = commandQueue.firstIndex(where: { $0.id == id }) {
                        commandQueue.remove(at: index)
                    }
                    
                    // Nächsten Befehl verarbeiten
                    isProcessingCommand = false
                    processNextCommand()
                }
            }
        }
    }
    
    /// Verarbeitet eine Fehlerantwort
    private func handleErrorResponse(data: Data) {
        guard data.count >= 2 else {
            return
        }
        
        let errorCode = data[1]
        var errorMessage = "Unbekannter Fehler"
        
        switch errorCode {
        case 0x01:
            errorMessage = "Ungültiger Befehl"
        case 0x02:
            errorMessage = "Ungültiger Parameter"
        case 0x03:
            errorMessage = "Nicht unterstützt"
        case 0x04:
            errorMessage = "Hardwarefehler"
        default:
            errorMessage = "Fehler \(errorCode)"
        }
        
        Logger.error("Gerät meldete Fehler: \(errorMessage)")
        
        // Wenn es ausstehende Befehle gibt, den ältesten als fehlgeschlagen markieren
        if let oldestID = pendingResponses.keys.first,
           let callback = pendingResponses.removeValue(forKey: oldestID) {
            // Timeout abbrechen
            commandTimeouts[oldestID]?.invalidate()
            commandTimeouts.removeValue(forKey: oldestID)
            
            // Callback mit nil aufrufen (Fehler)
            callback(nil)
            
            // Befehl aus der Queue entfernen
            if let index = commandQueue.firstIndex(where: { $0.id == oldestID }) {
                commandQueue.remove(at: index)
            }
            
            // Nächsten Befehl verarbeiten
            isProcessingCommand = false
            processNextCommand()
        }
    }
    
    /// Sendet einen Befehl an die Maus
    /// - Parameters:
    ///   - command: Der zu sendende Befehl
    ///   - completion: Callback mit der Antwort (nil bei Fehler)
    func sendCommand(_ command: USBCommand, completion: @escaping (Data?) -> Void) {
        // Befehl zur Warteschlange hinzufügen
        commandQueue.append(command)
        pendingResponses[command.id] = completion
        
        // Timeout einrichten
        setupTimeout(for: command)
        
        // Befehl verarbeiten, wenn kein anderer gerade verarbeitet wird
        if !isProcessingCommand {
            processNextCommand()
        }
    }
    
    /// Verarbeitet den nächsten Befehl in der Warteschlange
    private func processNextCommand() {
        guard !isProcessingCommand, !commandQueue.isEmpty, let activeDevice = activeDevice else {
            return
        }
        
        // Nächsten Befehl aus der Warteschlange nehmen
        let command = commandQueue.first!
        
        // Befehl senden
        isProcessingCommand = true
        
        // Befehlsbytes erstellen
        var commandData = createCommandData(command)
        
        // Befehl an das Gerät senden
        let result = usbMonitor.sendCommand(
            to: activeDevice,
            reportID: 0,
            data: commandData
        )
        
        if !result {
            // Fehler beim Senden
            Logger.error("Fehler beim Senden des Befehls: \(command.type)")
            
            // Callback mit nil aufrufen (Fehler)
            if let callback = pendingResponses.removeValue(forKey: command.id) {
                callback(nil)
            }
            
            // Timeout abbrechen
            commandTimeouts[command.id]?.invalidate()
            commandTimeouts.removeValue(forKey: command.id)
            
            // Befehl aus der Queue entfernen
            commandQueue.removeFirst()
            
            // Nächsten Befehl verarbeiten
            isProcessingCommand = false
            processNextCommand()
            
            return
        }
        
        // Bei Befehlen ohne erwartete Antwort sofort zum nächsten Befehl übergehen
        if !command.expectResponse {
            // Callback aufrufen (ohne Antwort)
            if let callback = pendingResponses.removeValue(forKey: command.id) {
                callback(Data())
            }
            
            // Timeout abbrechen
            commandTimeouts[command.id]?.invalidate()
            commandTimeouts.removeValue(forKey: command.id)
            
            // Befehl aus der Queue entfernen
            commandQueue.removeFirst()
            
            // Nächsten Befehl verarbeiten
            isProcessingCommand = false
            processNextCommand()
        }
    }
    
    /// Erstellt die Befehlsbytes für einen Befehl
    private func createCommandData(_ command: USBCommand) -> Data {
        var commandBytes: [UInt8] = []
        
        // Befehlstyp als erstes Byte
        switch command.type {
        case .getInfo:
            commandBytes = [0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            
        case .getSettings:
            commandBytes = [0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            
        case .setDPI:
            guard command.parameters.count >= 2 else {
                Logger.error("Ungültige Parameter für setDPI")
                return Data([0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
            }
            
            let stage = command.parameters[0]
            let dpi = command.parameters[1]
            
            commandBytes = [0x20, UInt8(stage), UInt8((dpi >> 8) & 0xFF), UInt8(dpi & 0xFF), 0x00, 0x00, 0x00, 0x00]
            
        case .setPollingRate:
            guard command.parameters.count >= 1 else {
                Logger.error("Ungültige Parameter für setPollingRate")
                return Data([0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
            }
            
            let rateValue = command.parameters[0]
            commandBytes = [0x30, UInt8(rateValue), 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            
        case .setLiftOffDistance:
            guard command.parameters.count >= 1 else {
                Logger.error("Ungültige Parameter für setLiftOffDistance")
                return Data([0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
            }
            
            let distValue = command.parameters[0]
            commandBytes = [0x40, UInt8(distValue), 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            
        case .setButton:
            guard command.parameters.count >= 2 else {
                Logger.error("Ungültige Parameter für setButton")
                return Data([0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
            }
            
            let button = command.parameters[0]
            let action = command.parameters[1]
            
            commandBytes = [0x50, UInt8(button), UInt8(action), 0x00, 0x00, 0x00, 0x00, 0x00]
            
        case .setMotionSync:
            guard command.parameters.count >= 1 else {
                Logger.error("Ungültige Parameter für setMotionSync")
                return Data([0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
            }
            
            let enabled = command.parameters[0]
            commandBytes = [0x60, UInt8(enabled), 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            
        case .setPowerSaving:
            guard command.parameters.count >= 1 else {
                Logger.error("Ungültige Parameter für setPowerSaving")
                return Data([0x70, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
            }
            
            let idleTime = command.parameters[0]
            
            // Idle-Zeit auf Bytes aufteilen
            let idleTimeLow = UInt8(idleTime & 0xFF)
            let idleTimeHigh = UInt8((idleTime >> 8) & 0xFF)
            
            var bytes: [UInt8] = [0x70, idleTimeLow, idleTimeHigh, 0x00, 0x00, 0x00, 0x00, 0x00]
            
            // Optionaler Batterieschwellwert
            if command.parameters.count >= 2 {
                let threshold = command.parameters[1]
                bytes[3] = UInt8(threshold)
            }
            
            commandBytes = bytes
            
        case .saveProfile:
            guard command.parameters.count >= 1 else {
                Logger.error("Ungültige Parameter für saveProfile")
                return Data([0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
            }
            
            let profile = command.parameters[0]
            commandBytes = [0xF0, UInt8(profile), 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            
        case .getBattery:
            commandBytes = [0x70, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            
        case .custom:
            // Bei einem benutzerdefinierten Befehl die Parameter direkt verwenden
            commandBytes = command.parameters.map { UInt8($0) }
            
            // Auf mindestens 8 Bytes auffüllen
            while commandBytes.count < 8 {
                commandBytes.append(0x00)
            }
        }
        
        return Data(commandBytes)
    }
    
    /// Richtet einen Timeout für einen Befehl ein
    private func setupTimeout(for command: USBCommand) {
        let timer = Timer.scheduledTimer(withTimeInterval: command.timeout, repeats: false) { [weak self] _ in
            self?.handleCommandTimeout(command)
        }
        
        commandTimeouts[command.id] = timer
    }
    
    /// Verarbeitet einen Timeout für einen Befehl
    private func handleCommandTimeout(_ command: USBCommand) {
        Logger.warning("Timeout für Befehl: \(command.type)")
        
        // Callback mit nil aufrufen (Timeout)
        if let callback = pendingResponses.removeValue(forKey: command.id) {
            callback(nil)
        }
        
        // Timer entfernen
        commandTimeouts.removeValue(forKey: command.id)
        
        // Befehl aus der Queue entfernen
        if let index = commandQueue.firstIndex(where: { $0.id == command.id }) {
            commandQueue.remove(at: index)
        }
        
        // Nächsten Befehl verarbeiten
        isProcessingCommand = false
        processNextCommand()
    }
    
    /// Bricht alle ausstehenden Befehle ab
    private func cancelAllPendingCommands() {
        // Alle Timeouts abbrechen
        for timer in commandTimeouts.values {
            timer.invalidate()
        }
        commandTimeouts.removeAll()
        
        // Alle Callbacks mit nil aufrufen (abgebrochen)
        for (id, callback) in pendingResponses {
            callback(nil)
        }
        pendingResponses.removeAll()
        
        // Warteschlange leeren
        commandQueue.removeAll()
        
        isProcessingCommand = false
    }
}

/// Typ eines USB-Befehls
enum USBCommandType {
    case getInfo
    case getSettings
    case setDPI
    case setPollingRate
    case setLiftOffDistance
    case setButton
    case setMotionSync
    case setPowerSaving
    case saveProfile
    case getBattery
    case custom
}

/// Struktur für einen USB-Befehl
class USBCommand {
    /// Eindeutige ID des Befehls
    let id = UUID()
    
    /// Typ des Befehls
    let type: USBCommandType
    
    /// Parameter für den Befehl
    let parameters: [Int]
    
    /// Timeout für den Befehl in Sekunden
    let timeout: TimeInterval
    
    /// Ob eine Antwort erwartet wird
    let expectResponse: Bool
    
    /// Initialisiert einen neuen USB-Befehl
    /// - Parameters:
    ///   - type: Typ des Befehls
    ///   - parameters: Parameter für den Befehl
    ///   - timeout: Timeout in Sekunden
    ///   - expectResponse: Ob eine Antwort erwartet wird
    init(type: USBCommandType, parameters: [Int] = [], timeout: TimeInterval = 1.0, expectResponse: Bool = true) {
        self.type = type
        self.parameters = parameters
        self.timeout = timeout
        self.expectResponse = expectResponse
    }
}
