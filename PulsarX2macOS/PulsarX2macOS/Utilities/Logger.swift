//
//  Logger.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import os.log

/// Log-Level für die Protokollierung
enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    /// String-Repräsentation des Log-Levels
    var description: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARN"
        case .error:
            return "ERROR"
        }
    }
    
    /// Vergleichsoperator für Log-Level
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Ziel für die Protokollierung
protocol LogDestination {
    /// Protokolliert eine Nachricht
    /// - Parameters:
    ///   - message: Nachricht
    ///   - level: Log-Level
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    func log(message: String, level: LogLevel, file: String, function: String, line: Int)
}

/// Ziel für die Protokollierung in der Konsole
class ConsoleLogDestination: LogDestination {
    /// Protokolliert eine Nachricht in der Konsole
    /// - Parameters:
    ///   - message: Nachricht
    ///   - level: Log-Level
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    func log(message: String, level: LogLevel, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = Logger.dateFormatter.string(from: Date())
        
        // Farbige Ausgabe je nach Log-Level
        let levelColor: String
        switch level {
        case .debug:
            levelColor = "\u{001B}[36m" // Cyan
        case .info:
            levelColor = "\u{001B}[32m" // Grün
        case .warning:
            levelColor = "\u{001B}[33m" // Gelb
        case .error:
            levelColor = "\u{001B}[31m" // Rot
        }
        
        // Formatierte Ausgabe
        let output = "\(timestamp) \(levelColor)[\(level.description)]\u{001B}[0m [\(fileName):\(line)] \(function): \(message)"
        print(output)
    }
}

/// Ziel für die Protokollierung in eine Datei
class FileLogDestination: LogDestination {
    /// Pfad zur Log-Datei
    private let filePath: URL
    
    /// File-Handle für die Log-Datei
    private var fileHandle: FileHandle?
    
    /// Initialisiert ein neues Datei-Log-Ziel
    /// - Parameter filePath: Pfad zur Log-Datei
    init(filePath: URL) {
        self.filePath = filePath
        
        // Log-Verzeichnis erstellen, falls nicht vorhanden
        try? FileManager.default.createDirectory(
            at: filePath.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Log-Datei erstellen, falls nicht vorhanden
        if !FileManager.default.fileExists(atPath: filePath.path) {
            FileManager.default.createFile(atPath: filePath.path, contents: nil, attributes: nil)
        }
        
        // File-Handle öffnen
        do {
            fileHandle = try FileHandle(forWritingTo: filePath)
            fileHandle?.seekToEndOfFile()
        } catch {
            print("Fehler beim Öffnen der Log-Datei: \(error)")
        }
    }
    
    deinit {
        // File-Handle schließen
        do {
            try fileHandle?.close()
        } catch {
            print("Fehler beim Schließen der Log-Datei: \(error)")
        }
    }
    
    /// Protokolliert eine Nachricht in die Datei
    /// - Parameters:
    ///   - message: Nachricht
    ///   - level: Log-Level
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    func log(message: String, level: LogLevel, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = Logger.dateFormatter.string(from: Date())
        
        // Formatierte Ausgabe
        let output = "\(timestamp) [\(level.description)] [\(fileName):\(line)] \(function): \(message)\n"
        
        guard let data = output.data(using: .utf8) else {
            return
        }
        
        // In die Datei schreiben
        do {
            try fileHandle?.write(contentsOf: data)
        } catch {
            print("Fehler beim Schreiben in die Log-Datei: \(error)")
        }
    }
}

/// Ziel für die Protokollierung mit os_log
class OSLogDestination: LogDestination {
    /// OS-Logger für die Protokollierung
    private let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.lana-svetik.PulsarX2macOS", category: "PulsarX2")
    
    /// Protokolliert eine Nachricht mit os_log
    /// - Parameters:
    ///   - message: Nachricht
    ///   - level: Log-Level
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    func log(message: String, level: LogLevel, file: String, function: String, line: Int) {
        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        }
        
        os_log("%{public}@", log: osLog, type: osLogType, message)
    }
}

/// Statischer Logger für die App
class Logger {
    /// Standard-Log-Level
    static var logLevel: LogLevel = .info
    
    /// Ob Debug-Logging aktiviert ist
    static var isDebugEnabled: Bool {
        return logLevel <= .debug
    }
    
    /// Log-Ziele
    private static var destinations: [LogDestination] = [
        ConsoleLogDestination(),
        FileLogDestination(filePath: logFilePath),
        OSLogDestination()
    ]
    
    /// Pfad zur Log-Datei
    private static var logFilePath: URL {
        let logDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("PulsarX2", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
        
        let dateString = Self.fileDateFormatter.string(from: Date())
        return logDir.appendingPathComponent("pulsar_\(dateString).log")
    }
    
    /// Datumsformatter für Log-Zeitstempel
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    /// Datumsformatter für Log-Dateinamen
    static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// Protokolliert eine Nachricht
    /// - Parameters:
    ///   - message: Nachricht
    ///   - level: Log-Level
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    private static func log(message: String, level: LogLevel, file: String = #file, function: String = #function, line: Int = #line) {
        // Nur protokollieren, wenn das Level hoch genug ist
        guard level >= logLevel else {
            return
        }
        
        // An alle Ziele protokollieren
        for destination in destinations {
            destination.log(message: message, level: level, file: file, function: function, line: line)
        }
    }
    
    /// Protokolliert eine Debug-Nachricht
    /// - Parameters:
    ///   - message: Nachricht
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, level: .debug, file: file, function: function, line: line)
    }
    
    /// Protokolliert eine Info-Nachricht
    /// - Parameters:
    ///   - message: Nachricht
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, level: .info, file: file, function: function, line: line)
    }
    
    /// Protokolliert eine Warnung
    /// - Parameters:
    ///   - message: Nachricht
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Protokolliert einen Fehler
    /// - Parameters:
    ///   - message: Nachricht
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, level: .error, file: file, function: function, line: line)
    }
    
    /// Fügt ein Log-Ziel hinzu
    /// - Parameter destination: Log-Ziel
    static func addDestination(_ destination: LogDestination) {
        destinations.append(destination)
    }
    
    /// Entfernt alle Log-Ziele
    static func removeAllDestinations() {
        destinations.removeAll()
    }
    
    /// Protokolliert eine Exception
    /// - Parameters:
    ///   - exception: Exception
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    static func exception(_ exception: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let message = "Exception: \(exception.localizedDescription)"
        log(message: message, level: .error, file: file, function: function, line: line)
    }
    
    /// Protokolliert Methodenaufrufe (für Debugging)
    /// - Parameters:
    ///   - parameters: Parameter des Aufrufs
    ///   - file: Quelldatei
    ///   - function: Funktion
    ///   - line: Zeilennummer
    static func trace(parameters: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        var message = "TRACE: \(function)"
        
        if !parameters.isEmpty {
            let paramsString = parameters.map { "\($0.key)=\(String(describing: $0.value))" }.joined(separator: ", ")
            message += " - Parameters: {\(paramsString)}"
        }
        
        log(message: message, level: .debug, file: file, function: function, line: line)
    }
}
