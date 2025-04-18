//
//  PulsarX2macOSTests.swift
//  PulsarX2macOSTests
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import XCTest
@testable import PulsarX2macOS

class PulsarX2macOSTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Initialisierung vor jedem Test
    }
    
    override func tearDown() {
        // Aufräumen nach jedem Test
        super.tearDown()
    }
    
    // Test für USB-Gerätemanager
    func testUSBDeviceManager() {
        let usbManager = USBDeviceManager.shared
        
        // Initialer Verbindungsstatus sollte disconnected sein
        XCTAssertEqual(usbManager.connectionStatus, .disconnected, "Initialer Verbindungsstatus sollte disconnected sein")
    }
    
    // Test für Profil-Management
    func testProfileManager() {
        let profileManager = ProfileManager.shared
        
        // Prüfen, ob Standardprofil existiert
        XCTAssertNotNil(profileManager.configuration.profiles["1"], "Standardprofil sollte existieren")
        
        // Prüfen des aktiven Profils
        XCTAssertEqual(profileManager.configuration.activeProfile, "1", "Aktives Profil sollte '1' sein")
    }
    
    // Test für DPI-Controller
    func testDPIController() {
        let dpiController = DPIController.shared
        
        // Prüfen der Standard-DPI-Einstellungen
        XCTAssertNotNil(dpiController.getCurrentPollingRate(), "Aktuelle DPI-Rate sollte nicht nil sein")
    }
    
    // Test für Buttonmapping
    func testButtonMapping() {
        let buttonController = ButtonController.shared
        
        // Standard-Tastenbelegungen prüfen
        let defaultMappings = StandardButtonMappings.defaultMappings
        XCTAssertEqual(defaultMappings[1], "Linksklick", "Erste Taste sollte Linksklick sein")
        XCTAssertEqual(defaultMappings[2], "Rechtsklick", "Zweite Taste sollte Rechtsklick sein")
    }
    
    // Performance-Test
    func testPerformanceExample() {
        self.measure {
            // Code, der gemessen werden soll
            let _ = ProfileManager.shared.configuration
        }
    }
}
