//
//  DPISlider.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Benutzerdefinierter Slider für DPI-Einstellungen
struct DPISlider: View {
    /// Binding für den DPI-Wert
    @Binding var dpiValue: Double
    
    /// Minimaler DPI-Wert
    var minValue: Double = 50
    
    /// Maximaler DPI-Wert
    var maxValue: Double = 32000
    
    /// Schrittgröße für DPI-Änderungen
    var step: Double = 50
    
    /// Akzentfarbe des Sliders
    var accentColor: Color = .blue
    
    /// Callback bei Änderung des DPI-Werts
    var onChanged: ((Double) -> Void)?
    
    /// Callback beim Loslassen des Sliders
    var onEnded: ((Double) -> Void)?
    
    /// Begrenzung des DPI-Werts auf gültige Werte
    private var validValue: Double {
        return max(minValue, min(maxValue, dpiValue))
    }
    
    /// Normalisierter Wert für die Position des Sliders (0-1)
    private var normalizedValue: Double {
        return (validValue - minValue) / (maxValue - minValue)
    }
    
    /// Flag für aktiven Slider-Zustand
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // DPI-Anzeige
            HStack {
                Text("\(Int(validValue))")
                    .font(.title)
                    .bold()
                    .foregroundColor(accentColor)
                    .frame(width: 100, alignment: .trailing)
                
                Text("DPI")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Benutzerdefinierter Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Slider-Hintergrund
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("ControlBackground"))
                        .frame(height: 8)
                    
                    // Slider-Fortschritt
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor)
                        .frame(width: max(0, min(geometry.size.width, geometry.size.width * normalizedValue)), height: 8)
                    
                    // Slider-Knopf
                    Circle()
                        .fill(isDragging ? accentColor : Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .overlay(
                            Circle()
                                .stroke(accentColor, lineWidth: 2)
                        )
                        .offset(x: max(0, min(geometry.size.width - 20, (geometry.size.width - 20) * normalizedValue)))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    
                                    // Berechne den neuen Wert basierend auf der Drag-Position
                                    let width = geometry.size.width - 20
                                    let dragPosition = max(0, min(width, value.location.x))
                                    let percentage = dragPosition / width
                                    let newValue = minValue + ((maxValue - minValue) * percentage)
                                    
                                    // Auf Schrittgröße runden
                                    let roundedValue = round(newValue / step) * step
                                    
                                    // Wert aktualisieren
                                    if roundedValue != dpiValue {
                                        dpiValue = roundedValue
                                        onChanged?(dpiValue)
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    onEnded?(dpiValue)
                                }
                        )
                }
                .frame(height: 30)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            
                            // Berechne den neuen Wert basierend auf der Tap-Position
                            let width = geometry.size.width - 20
                            let tapPosition = max(0, min(width, value.location.x - 10))
                            let percentage = tapPosition / width
                            let newValue = minValue + ((maxValue - minValue) * percentage)
                            
                            // Auf Schrittgröße runden
                            let roundedValue = round(newValue / step) * step
                            
                            // Wert aktualisieren
                            if roundedValue != dpiValue {
                                dpiValue = roundedValue
                                onChanged?(dpiValue)
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            onEnded?(dpiValue)
                        }
                )
            }
            
            // Beschriftung
            HStack {
                Text("\(Int(minValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(maxValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Zusätzliche Steuerelemente für präzise Anpassung
            HStack(spacing: 12) {
                Button(action: {
                    decrementDPI()
                }) {
                    Image(systemName: "minus")
                        .frame(width: 40, height: 30)
                        .background(Color("ControlBackground"))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: {
                    incrementDPI()
                }) {
                    Image(systemName: "plus")
                        .frame(width: 40, height: 30)
                        .background(Color("ControlBackground"))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 4)
    }
    
    /// Erhöht den DPI-Wert um die Schrittgröße
    private func incrementDPI() {
        let newValue = min(maxValue, dpiValue + step)
        if newValue != dpiValue {
            dpiValue = newValue
            onChanged?(dpiValue)
            onEnded?(dpiValue)
        }
    }
    
    /// Verringert den DPI-Wert um die Schrittgröße
    private func decrementDPI() {
        let newValue = max(minValue, dpiValue - step)
        if newValue != dpiValue {
            dpiValue = newValue
            onChanged?(dpiValue)
            onEnded?(dpiValue)
        }
    }
}

/// Vorschau für den DPI-Slider
struct DPISlider_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DPISlider(dpiValue: .constant(1600))
                .padding()
                .previewLayout(.fixed(width: 400, height: 150))
                .preferredColorScheme(.dark)
            
            DPISlider(dpiValue: .constant(8000), accentColor: .red)
                .padding()
                .previewLayout(.fixed(width: 400, height: 150))
                .preferredColorScheme(.dark)
            
            DPISlider(dpiValue: .constant(400), accentColor: .green, onChanged: { value in
                print("DPI changed: \(value)")
            })
            .padding()
            .previewLayout(.fixed(width: 400, height: 150))
            .preferredColorScheme(.dark)
        }
        .padding()
        .background(Color("BackgroundColor"))
    }
}
