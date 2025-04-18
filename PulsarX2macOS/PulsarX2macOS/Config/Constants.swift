//
//  Constants.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import SwiftUI

/// Konstanten für die gesamte App
struct Constants {
    /// App-Version
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    /// Build-Nummer
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    /// Vollständige Versionsnummer (Version + Build)
    static let fullVersionString = "v\(appVersion) (\(buildNumber))"
    
    /// Copyright-Hinweis
    static let copyright = "© 2025 Svetlana Sibiryakova"
    
    /// GitHub-Repository-URL
    static let repositoryURL = URL(string: "https://github.com/lana-svetik/pulsarX2-macOS-swift")!
    
    /// Support-Email
    static let supportEmail = "support@example.com"
    
    /// App-Beschreibung für den About-Dialog
    static let appDescription = """
    Pulsar X2 macOS App ist eine native macOS-Anwendung zur Konfiguration der Gaming-Maus Pulsar X2. 
    Da die offizielle Pulsar-Software nur für Windows verfügbar ist, bietet diese App eine vollständige 
    Konfiguration der Pulsar X2 unter macOS, einschließlich DPI-Einstellungen, Polling-Rate, Lift-Off-Distanz (LOD), 
    Tastenbelegung und Energiesparoptionen.
    """
    
    /// Minimale Fenstergröße
    static let minWindowSize = CGSize(width: 960, height: 640)
    
    /// Standardwerte für macOS UI-Elemente
    struct UI {
        /// Seitenleisten-Breite
        static let sidebarWidth: CGFloat = 200
        
        /// Header-Höhe
        static let headerHeight: CGFloat = 50
        
        /// Standardabstand für UI-Elemente
        static let standardPadding: CGFloat = 16
        
        /// Kleine Abrundung für UI-Elemente
        static let smallCornerRadius: CGFloat = 4
        
        /// Mittlere Abrundung für UI-Elemente
        static let mediumCornerRadius: CGFloat = 8
        
        /// Große Abrundung für UI-Elemente
        static let largeCornerRadius: CGFloat = 12
        
        /// Kleine Schrift
        static let smallFont: Font = .system(size: 12)
        
        /// Mittlere Schrift
        static let mediumFont: Font = .system(size: 14)
        
        /// Große Schrift
        static let largeFont: Font = .system(size: 16)
        
        /// Überschrift-Schrift
        static let headlineFont: Font = .headline
        
        /// Untertitel-Schrift
        static let subheadlineFont: Font = .subheadline
        
        /// Titel-Schrift
        static let titleFont: Font = .title3
    }
    
    /// Farben-Konstanten
    struct Colors {
        /// Primärfarbe
        static let primary = Color("PrimaryColor")
        
        /// Akzentfarbe
        static let accent = Color("AccentColor")
        
        /// Hintergrundfarbe
        static let background = Color("BackgroundColor")
        
        /// Seitenleisten-Hintergrundfarbe
        static let sidebarBackground = Color("SidebarBackground")
        
        /// Header-Hintergrundfarbe
        static let headerBackground = Color("HeaderBackground")
        
        /// Sektions-Hintergrundfarbe
        static let sectionBackground = Color("SectionBackground")
        
        /// Steuerelemente-Hintergrundfarbe
        static let controlBackground = Color("ControlBackground")
        
        /// Erfolgsfarbe
        static let success = Color.green
        
        /// Warnfarbe
        static let warning = Color.yellow
        
        /// Fehlerfarbe
        static let error = Color.red
        
        /// Farben für DPI-Stufen
        static let dpiStageColors: [Color] = [
            .blue,
            .blue,
            .green,
            .yellow,
            .orange,
            .pink
        ]
    }
    
    /// Zeitkonstanten
    struct Timing {
        /// Kurze Animation
        static let shortAnimation: Double = 0.2
        
        /// Standard-Animation
        static let standardAnimation: Double = 0.3
        
        /// Lange Animation
        static let longAnimation: Double = 0.5
        
        /// Verzögerung für Statusaktualisierungen
        static let statusUpdateDelay: Double = 1.0
        
        /// Verzögerung für Tooltips
        static let tooltipDelay: Double = 0.5
    }
    
    /// Speicherorte
    struct Storage {
        /// Verzeichnis für App-Daten
        static let appDataDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("PulsarX2", isDirectory: true)
        
        /// Verzeichnis für Log-Dateien
        static let logDirectory = appDataDirectory.appendingPathComponent("Logs", isDirectory: true)
        
        /// Pfad zur Konfigurationsdatei
        static let configFile = appDataDirectory.appendingPathComponent("config.json")
        
        /// Pfad zur Makro-Datei
        static let macroFile = appDataDirectory.appendingPathComponent("macros.json")
        
        /// Pfad zur Backup-Verzeichnis
        static let backupDirectory = appDataDirectory.appendingPathComponent("Backups", isDirectory: true)
    }
    
    /// Berechtigungen
    struct Permissions {
        /// Name der Berechtigung für USB-Zugriff
        static let usbAccess = "usb"
        
        /// Name der Berechtigung für Admin-Rechte
        static let adminPrivileges = "admin"
        
        /// Name der Berechtigung für Eingabeüberwachung
        static let inputMonitoring = "input-monitoring"
        
        /// Name der Berechtigung für Autostart
        static let autoLaunch = "auto-launch"
    }
    
    /// Benachrichtigungen
    struct Notifications {
        /// Name der Benachrichtigung für Geräteverbindung
        static let deviceConnected = "DeviceConnected"
        
        /// Name der Benachrichtigung für Gerätetrennung
        static let deviceDisconnected = "DeviceDisconnected"
        
        /// Name der Benachrichtigung für Batteriestandänderung
        static let batteryLevelChanged = "BatteryLevelChanged"
        
        /// Name der Benachrichtigung für Profiländerung
        static let profileChanged = "ProfileChanged"
        
        /// Name der Benachrichtigung für Einstellungsänderung
        static let settingsChanged = "SettingsChanged"
    }
    
    /// Einstellungen für Exportformate
    struct ExportFormats {
        /// JSON-Erweiterung
        static let json = "json"
        
        /// Pulsar-Profil-Erweiterung
        static let profile = "pulsar"
    }
    
    /// URL-Schema für tiefe Links
    struct URLSchemes {
        /// Basis-Schema
        static let base = "pulsarx2://"
        
        /// Schema für Profil-Aktivierung
        static let activateProfile = "\(base)profile/"
        
        /// Schema für DPI-Änderung
        static let changeDPI = "\(base)dpi/"
        
        /// Schema für Makro-Ausführung
        static let executeMacro = "\(base)macro/"
    }
}
