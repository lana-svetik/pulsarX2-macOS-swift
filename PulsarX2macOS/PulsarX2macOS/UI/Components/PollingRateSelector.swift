//
//  PollingRateSelector.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Komponente für die Auswahl der Polling-Rate
struct PollingRateSelector: View {
    /// Verfügbare Polling-Raten
    var availableRates: [Int]
    
    /// Aktuell ausgewählte Rate
    var selectedRate: Int
    
    /// Callback bei Auswahl einer Rate
    var onSelect: ((Int) -> Void)?
    
    /// Style der Anzeige
    var style: PollingRateSelectorStyle = .horizontal
    
    var body: some View {
        Group {
            switch style {
            case .horizontal:
                horizontalLayout
            case .vertical:
                verticalLayout
            case .grid:
                gridLayout
            }
        }
    }
    
    /// Horizontales Layout der Ratenauswahl
    private var horizontalLayout: some View {
        HStack(spacing: 16) {
            ForEach(availableRates, id: \.self) { rate in
                rateButton(rate: rate)
            }
        }
    }
    
    /// Vertikales Layout der Ratenauswahl
    private var verticalLayout: some View {
        VStack(spacing: 12) {
            ForEach(availableRates, id: \.self) { rate in
                rateButton(rate: rate)
            }
        }
    }
    
    /// Grid-Layout der Ratenauswahl
    private var gridLayout: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80), spacing: 12)
        ], spacing: 12) {
            ForEach(availableRates, id: \.self) { rate in
                rateButton(rate: rate)
            }
        }
    }
    
    /// Button für eine einzelne Polling-Rate
    private func rateButton(rate: Int) -> some View {
        let isSelected = rate == selectedRate
        let requiresSpecialDongle = rate > 1000
        
        return Button(action: {
            onSelect?(rate)
        }) {
            VStack(spacing: 4) {
                Text("\(rate)")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                if requiresSpecialDongle {
                    Text("High")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary.opacity(0.7))
                } else {
                    Text("Hz")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary.opacity(0.7))
                }
            }
            .frame(width: 60, height: 40)
            .background(isSelected ? Color.blue : Color("ControlBackground"))
            .cornerRadius(Constants.UI.smallCornerRadius)
            .overlay(
                Group {
                    if requiresSpecialDongle {
                        RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                            .strokeBorder(Color.yellow.opacity(0.7), lineWidth: 1)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .help(helpText(for: rate))
    }
    
    /// Hilfetext für eine Rate
    private func helpText(for rate: Int) -> String {
        if rate > 1000 {
            return "Polling-Rate mit \(rate)Hz (erfordert speziellen Dongle)"
        } else {
            return "Polling-Rate mit \(rate)Hz"
        }
    }
}

/// Stil für den Polling-Rate-Selektor
enum PollingRateSelectorStyle {
    case horizontal
    case vertical
    case grid
}

/// Vorschau für den Polling-Rate-Selektor
struct PollingRateSelector_Previews: PreviewProvider {
    static var availableRates = [125, 250, 500, 1000, 2000, 4000, 8000]
    
    static var previews: some View {
        VStack(spacing: 30) {
            // Horizontales Layout
            PollingRateSelector(
                availableRates: availableRates,
                selectedRate: 1000,
                onSelect: { rate in
                    print("Selected rate: \(rate)")
                },
                style: .horizontal
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Horizontal")
            
            // Vertikales Layout
            PollingRateSelector(
                availableRates: availableRates,
                selectedRate: 1000,
                onSelect: { rate in
                    print("Selected rate: \(rate)")
                },
                style: .vertical
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Vertical")
            
            // Grid-Layout
            PollingRateSelector(
                availableRates: availableRates,
                selectedRate: 1000,
                onSelect: { rate in
                    print("Selected rate: \(rate)")
                },
                style: .grid
            )
            .frame(width: 300)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Grid")
        }
        .padding()
        .background(Color("BackgroundColor"))
        .preferredColorScheme(.dark)
    }
}
