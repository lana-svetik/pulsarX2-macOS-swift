//
//  SidebarView.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// SwiftUI-Seitenleisten-Ansicht
struct SidebarView: View {
    /// Aktuell ausgewählte Seite
    @Binding var selectedPage: NavigationPage
    
    /// USB-Gerätemanager für den Verbindungsstatus
    @EnvironmentObject private var usbManager: USBDeviceManager
    
    var body: some View {
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
                Button(action: {
                    selectedPage = page
                }) {
                    HStack {
                        Image(systemName: page.icon)
                            .frame(width: 24, height: 24)
                        Text(page.rawValue)
                            .fontWeight(selectedPage == page ? .bold : .regular)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(SidebarListStyle())
            
            Spacer()
            
            // Verbindungsstatus
            connectionStatusView
                .padding(.bottom, 12)
        }
        .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)
        .background(Color("SidebarBackground"))
    }
    
    /// Verbindungsstatusanzeige
    private var connectionStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Verbindungsstatus-Zeile
            HStack {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 10, height: 10)
                
                Text(connectionStatusText)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Wireless Mode")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            // Batterieanzeige für drahtlose Verbindung
            if usbManager.isWireless {
                HStack {
                    Image(systemName: batteryIcon)
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
    
    /// Berechnet die Farbe der Batterieanzeige
    private var batteryColor: Color {
        switch usbManager.batteryLevel {
        case 51...:
            return .green
        case 21...50:
            return .yellow
        default:
            return .red
        }
    }
    
    /// Liefert das passende Batterie-Icon
    private var batteryIcon: String {
        switch usbManager.batteryLevel {
        case 76...:
            return "battery.100"
        case 51...75:
            return "battery.75"
        case 26...50:
            return "battery.50"
        case 11...25:
            return "battery.25"
        default:
            return "battery.0"
        }
    }
    
    /// Bestimmt die Farbe basierend auf dem Verbindungsstatus
    private var connectionStatusColor: Color {
        switch usbManager.connectionStatus {
        case .connected:
            return .green
        case .disconnected:
            return .red
        case .error(_):
            return .yellow
        }
    }
    
    /// Bestimmt den Statustext basierend auf dem Verbindungsstatus
    private var connectionStatusText: String {
        switch usbManager.connectionStatus {
        case .connected:
            return "Verbunden"
        case .disconnected:
            return "Getrennt"
        case .error(let message):
            return "Fehler: \(message)"
        }
    }
}
