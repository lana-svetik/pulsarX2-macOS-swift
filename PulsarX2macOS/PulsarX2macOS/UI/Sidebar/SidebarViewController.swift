//
//  SidebarViewController.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Cocoa
import SwiftUI

/// View Controller für die Seitenleiste der Anwendung
class SidebarViewController: NSViewController {
    /// Aktuell ausgewählte Seite
    @Published private(set) var selectedPage: NavigationPage = .home
    
    /// Referenz auf den USB-Gerätemanager
    private let usbManager = USBDeviceManager.shared
    
    /// Container für die Seitenleisten-Ansicht
    private var sidebarHostingController: NSHostingController<SidebarView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Seitenleisten-Ansicht erstellen
        let sidebarView = SidebarView(
            selectedPage: $selectedPage,
            connectionStatus: usbManager.connectionStatus
        )
        
        sidebarHostingController = NSHostingController(rootView: sidebarView)
        
        if let sidebarView = sidebarHostingController?.view {
            // Seitenleiste zur View-Hierarchie hinzufügen
            view.addSubview(sidebarView)
            sidebarView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
                sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                sidebarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    /// Wechselt zur angegebenen Seite
    func navigateTo(_ page: NavigationPage) {
        selectedPage = page
    }
}

/// SwiftUI-Seitenleisten-Ansicht
struct SidebarView: View {
    @Binding var selectedPage: NavigationPage
    var connectionStatus: ConnectionStatus
    
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
            
            // Zusätzliche Statusinformationen basierend auf dem Verbindungsstatus
            additionalConnectionInfo
        }
        .padding(.vertical, 8)
        .background(Color("SidebarBackground"))
    }
    
    /// Bestimmt die Farbe basierend auf dem Verbindungsstatus
    private var connectionStatusColor: Color {
        switch connectionStatus {
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
        switch connectionStatus {
        case .connected:
            return "Verbunden"
        case .disconnected:
            return "Getrennt"
        case .error(let message):
            return "Fehler: \(message)"
        }
    }
    
    /// Zusätzliche Verbindungsinformationen
    private var additionalConnectionInfo: some View {
        Group {
            switch connectionStatus {
            case .connected:
                // Weitere Details bei erfolgreicher Verbindung
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
            
            case .disconnected:
                // Hinweis bei getrennter Verbindung
                Text("Bitte Gerät anschließen")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            
            case .error(_):
                // Fehlerhinweis
                Text("Verbindungsproblem")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(.horizontal)
            }
        }
    }
}
