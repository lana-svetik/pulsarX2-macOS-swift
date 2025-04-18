//
//  DPIStageView.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Ansicht für die Darstellung einer DPI-Stufe
struct DPIStageView: View {
    /// Stufennummer
    var stage: Int
    
    /// DPI-Wert der Stufe
    var dpiValue: Int
    
    /// Ob die Stufe aktiv ist
    var isActive: Bool
    
    /// Callback bei Auswahl der Stufe
    var onSelect: (() -> Void)?
    
    /// Farbe der Stufe
    var color: Color
    
    /// Standardfarbe für die Stufe basierend auf der Stufennummer
    static func defaultColor(forStage stage: Int) -> Color {
        switch stage {
        case 1: return .blue
        case 2: return .blue
        case 3: return .green
        case 4: return .yellow
        case 5: return .orange
        case 6: return .pink
        default: return .gray
        }
    }
    
    /// Initialisiert eine neue DPI-Stufen-Ansicht
    /// - Parameters:
    ///   - stage: Stufennummer
    ///   - dpiValue: DPI-Wert
    ///   - isActive: Ob die Stufe aktiv ist
    ///   - onSelect: Callback bei Auswahl
    ///   - color: Farbe (optional, wenn nicht angegeben wird eine Standardfarbe verwendet)
    init(stage: Int, dpiValue: Int, isActive: Bool, onSelect: (() -> Void)? = nil, color: Color? = nil) {
        self.stage = stage
        self.dpiValue = dpiValue
        self.isActive = isActive
        self.onSelect = onSelect
        self.color = color ?? Self.defaultColor(forStage: stage)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Farbiger Indikator
            Triangle()
                .fill(color)
                .frame(width: 12, height: 8)
                .opacity(isActive ? 1.0 : 0.0)
            
            // Button
            Button(action: {
                onSelect?()
            }) {
                VStack {
                    Text("DPI STAGE \(stage)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("\(dpiValue)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                }
                .frame(width: 100, height: 60)
                .background(isActive ? color : Color("ControlBackground"))
                .cornerRadius(Constants.UI.smallCornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

/// Dreiecksform für den DPI-Stufen-Indikator
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Ansicht für mehrere DPI-Stufen
struct DPIStagesView: View {
    /// DPI-Stufen (Key: Stufennummer, Value: DPI-Wert)
    var stages: [Int: Int]
    
    /// Aktive Stufe
    var activeStage: Int
    
    /// Callback bei Auswahl einer Stufe
    var onSelectStage: ((Int) -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...stages.count, id: \.self) { stage in
                if let dpiValue = stages[stage] {
                    DPIStageView(
                        stage: stage,
                        dpiValue: dpiValue,
                        isActive: stage == activeStage,
                        onSelect: {
                            onSelectStage?(stage)
                        }
                    )
                }
            }
        }
    }
}

/// Vorschau für die DPI-Stufen-Ansicht
struct DPIStageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Einzelne DPI-Stufe
            DPIStageView(stage: 1, dpiValue: 800, isActive: true)
                .previewLayout(.sizeThatFits)
            
            // Mehrere DPI-Stufen
            DPIStagesView(
                stages: [1: 800, 2: 1600, 3: 3200, 4: 6400, 5: 12800, 6: 25600],
                activeStage: 3,
                onSelectStage: { stage in
                    print("Selected stage: \(stage)")
                }
            )
            .previewLayout(.sizeThatFits)
        }
        .padding()
        .background(Color("BackgroundColor"))
        .preferredColorScheme(.dark)
    }
}
