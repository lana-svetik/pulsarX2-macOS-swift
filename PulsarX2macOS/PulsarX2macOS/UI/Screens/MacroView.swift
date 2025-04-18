//
//  MacroView.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import SwiftUI

/// Modell für Makroeingaben
struct MacroAction: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: MacroActionType
    var keyCode: Int?
    var delay: Int // in Millisekunden
    var state: MacroKeyState
    
    init(type: MacroActionType, keyCode: Int? = nil, delay: Int = 10, state: MacroKeyState = .pressed) {
        self.type = type
        self.keyCode = keyCode
        self.delay = delay
        self.state = state
    }
}

/// Typen von Makroaktionen
enum MacroActionType: String, Codable {
    case keypress = "Tastendruck"
    case mouseClick = "Mausklick"
    case delay = "Verzögerung"
}

/// Tastenzustand für Makroaktionen
enum MacroKeyState: String, Codable {
    case pressed = "Gedrückt"
    case released = "Losgelassen"
}

/// Modell für ein Makro
struct Macro: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var actions: [MacroAction]
    
    init(name: String, actions: [MacroAction] = []) {
        self.name = name
        self.actions = actions
    }
}

/// ViewModel für MacroView
class MacroViewModel: ObservableObject {
    @Published var macros: [Macro] = []
    @Published var selectedMacro: Macro?
    @Published var isRecording = false
    @Published var temporaryActions: [MacroAction] = []
    
    init() {
        loadMacros()
    }
    
    /// Lädt gespeicherte Makros
    private func loadMacros() {
        // Beispielmakros für die Vorschau
        macros = [
            Macro(name: "Doppelklick", actions: [
                MacroAction(type: .mouseClick, keyCode: 1, state: .pressed),
                MacroAction(type: .delay, delay: 100),
                MacroAction(type: .mouseClick, keyCode: 1, state: .released),
                MacroAction(type: .delay, delay: 100),
                MacroAction(type: .mouseClick, keyCode: 1, state: .pressed),
                MacroAction(type: .delay, delay: 100),
                MacroAction(type: .mouseClick, keyCode: 1, state: .released)
            ]),
            Macro(name: "Strg+C", actions: [
                MacroAction(type: .keypress, keyCode: 55, state: .pressed), // Strg
                MacroAction(type: .keypress, keyCode: 8, state: .pressed),  // C
                MacroAction(type: .delay, delay: 50),
                MacroAction(type: .keypress, keyCode: 8, state: .released), // C
                MacroAction(type: .keypress, keyCode: 55, state: .released) // Strg
            ]),
            Macro(name: "Gaming Combo", actions: [
                MacroAction(type: .keypress, keyCode: 14, state: .pressed), // E-Taste
                MacroAction(type: .delay, delay: 200),
                MacroAction(type: .keypress, keyCode: 14, state: .released),
                MacroAction(type: .delay, delay: 50),
                MacroAction(type: .keypress, keyCode: 38, state: .pressed), // Leertaste
                MacroAction(type: .delay, delay: 200),
                MacroAction(type: .keypress, keyCode: 38, state: .released)
            ])
        ]
    }
    
    /// Startet die Makroaufnahme
    func startRecording() {
        isRecording = true
        temporaryActions = []
        
        // Hier würde die tatsächliche Aufnahme beginnen
        // Das würde die Erfassung von Maus- und Tastaturereignissen beinhalten
    }
    
    /// Stoppt die Makroaufnahme
    func stopRecording() {
        isRecording = false
        
        // Wenn Aktionen aufgenommen wurden, Benutzer nach Namen fragen
        if !temporaryActions.isEmpty {
            showSaveDialog()
        }
    }
    
    /// Zeigt den Dialog zum Speichern eines Makros
    private func showSaveDialog() {
        let alert = NSAlert()
        alert.messageText = "Makro speichern"
        alert.informativeText = "Bitte geben Sie einen Namen für das Makro ein:"
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.placeholderString = "Makroname"
        
        alert.accessoryView = inputTextField
        alert.addButton(withTitle: "Speichern")
        alert.addButton(withTitle: "Abbrechen")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let macroName = inputTextField.stringValue, !macroName.isEmpty {
                let newMacro = Macro(name: macroName, actions: temporaryActions)
                macros.append(newMacro)
                selectedMacro = newMacro
            }
        }
        
        temporaryActions = []
    }
    
    /// Fügt eine Aktion zum aktuellen Makro hinzu
    func addAction(type: MacroActionType, keyCode: Int? = nil, delay: Int = 10, state: MacroKeyState = .pressed) {
        guard let macro = selectedMacro else { return }
        
        let newAction = MacroAction(type: type, keyCode: keyCode, delay: delay, state: state)
        var updatedMacro = macro
        updatedMacro.actions.append(newAction)
        
        // Aktualisiere das ausgewählte Makro
        if let index = macros.firstIndex(where: { $0.id == macro.id }) {
            macros[index] = updatedMacro
            selectedMacro = updatedMacro
        }
    }
    
    /// Löscht eine Aktion aus dem aktuellen Makro
    func deleteAction(at indexSet: IndexSet) {
        guard var macro = selectedMacro else { return }
        
        macro.actions.remove(atOffsets: indexSet)
        
        // Aktualisiere das ausgewählte Makro
        if let index = macros.firstIndex(where: { $0.id == macro.id }) {
            macros[index] = macro
            selectedMacro = macro
        }
    }
    
    /// Erstellt ein neues Makro
    func createNewMacro() {
        let newMacro = Macro(name: "Neues Makro")
        macros.append(newMacro)
        selectedMacro = newMacro
    }
    
    /// Löscht ein Makro
    func deleteMacro(macro: Macro) {
        if let index = macros.firstIndex(where: { $0.id == macro.id }) {
            macros.remove(at: index)
            if selectedMacro?.id == macro.id {
                selectedMacro = macros.first
            }
        }
    }
}

/// Ansicht für die Makro-Bearbeitung und -Aufnahme
struct MacroView: View {
    @EnvironmentObject private var usbManager: USBDeviceManager
    @StateObject private var viewModel = MacroViewModel()
    
    var body: some View {
        HStack {
            // Makroliste
            VStack(alignment: .leading, spacing: 16) {
                Text("MAKROS")
                    .font(.headline)
                    .padding(.top, 8)
                
                macroListView
                
                HStack {
                    Button(action: viewModel.createNewMacro) {
                        Label("Neu", systemImage: "plus")
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Spacer()
                    
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }) {
                        Label(viewModel.isRecording ? "Stopp" : "Aufnehmen", 
                              systemImage: viewModel.isRecording ? "stop.fill" : "record.circle")
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .foregroundColor(viewModel.isRecording ? .red : .primary)
                }
                .padding(.vertical, 8)
            }
            .frame(width: 200)
            .padding()
            .background(Color("SectionBackground"))
            .cornerRadius(8)
            
            // Aktionsdetails
            VStack(alignment: .leading, spacing: 16) {
                // Kopfzeile mit Makroname
                HStack {
                    Text(viewModel.selectedMacro?.name ?? "Kein Makro ausgewählt")
                        .font(.headline)
                    
                    Spacer()
                    
                    if viewModel.selectedMacro != nil {
                        Button("Umbenennen") {
                            renameMacro()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button("Löschen") {
                            if let macro = viewModel.selectedMacro {
                                viewModel.deleteMacro(macro: macro)
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .foregroundColor(.red)
                    }
                }
                .padding(.top, 8)
                
                // Aufnahmestatusanzeige
                if viewModel.isRecording {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text("Aufnahme läuft... Drücken Sie Tasten oder klicken Sie Maustasten")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                }
                
                if let macro = viewModel.selectedMacro {
                    if macro.actions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            
                            Text("Keine Aktionen in diesem Makro")
                                .foregroundColor(.secondary)
                            
                            Text("Klicken Sie auf 'Aufnehmen', um Aktionen hinzuzufügen,\noder fügen Sie sie manuell hinzu.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Aktion hinzufügen") {
                                addManualAction()
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Aktionsliste
                        List {
                            ForEach(macro.actions) { action in
                                actionRow(action: action)
                            }
                            .onDelete { indexSet in
                                viewModel.deleteAction(at: indexSet)
                            }
                        }
                        .listStyle(PlainListStyle())
                        
                        // Aktionsbuttons
                        HStack {
                            Button("Aktion hinzufügen") {
                                addManualAction()
                            }
                            .buttonStyle(BorderedButtonStyle())
                            
                            Spacer()
                            
                            Button("Testen") {
                                testMacro()
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    // Kein Makro ausgewählt
                    VStack(spacing: 16) {
                        Image(systemName: "keyboard.macwindow")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        Text("Kein Makro ausgewählt")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Wählen Sie ein vorhandenes Makro aus der Liste aus\noder erstellen Sie ein neues Makro.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Neues Makro erstellen") {
                            viewModel.createNewMacro()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color("SectionBackground"))
            .cornerRadius(8)
        }
        .padding()
    }
    
    /// Ansicht für die Makroliste
    private var macroListView: some View {
        List(viewModel.macros) { macro in
            HStack {
                Text(macro.name)
                    .foregroundColor(viewModel.selectedMacro?.id == macro.id ? .blue : .primary)
                
                Spacer()
                
                if !macro.actions.isEmpty {
                    Text("\(macro.actions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectedMacro = macro
            }
        }
        .listStyle(PlainListStyle())
    }
    
    /// Zeile für eine Makroaktion
    private func actionRow(action: MacroAction) -> some View {
        HStack {
            // Symbol für den Aktionstyp
            Image(systemName: actionTypeIcon(for: action.type))
                .frame(width: 24)
            
            // Beschreibung der Aktion
            VStack(alignment: .leading, spacing: 4) {
                Text(actionDescription(for: action))
                
                if action.type == .delay {
                    Text("\(action.delay) ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let keyCode = action.keyCode {
                    Text("Code: \(keyCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Zustand (für Tasten und Mausklicks)
            if action.type != .delay {
                Text(action.state.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(action.state == .pressed ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Liefert das passende Symbol für einen Aktionstyp
    private func actionTypeIcon(for type: MacroActionType) -> String {
        switch type {
        case .keypress:
            return "keyboard"
        case .mouseClick:
            return "mouse"
        case .delay:
            return "timer"
        }
    }
    
    /// Liefert eine Beschreibung für eine Aktion
    private func actionDescription(for action: MacroAction) -> String {
        switch action.type {
        case .keypress:
            if let keyCode = action.keyCode {
                return "Taste \(keyNameForKeyCode(keyCode))"
            }
            return "Tastendruck"
        case .mouseClick:
            if let button = action.keyCode {
                let buttonNames = ["Linksklick", "Rechtsklick", "Mittlere Taste"]
                return button < buttonNames.count ? buttonNames[button] : "Maustaste \(button + 1)"
            }
            return "Mausklick"
        case .delay:
            return "Verzögerung"
        }
    }
    
    /// Liefert einen Tastennamen für einen Keycode
    private func keyNameForKeyCode(_ keyCode: Int) -> String {
        // Vereinfachte Zuordnung einiger häufiger Tasten
        let keyNames: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Leertaste", 50: "`", 51: "Delete",
            53: "Escape", 55: "Command", 56: "Shift", 57: "Capslock", 58: "Option", 59: "Control"
        ]
        
        return keyNames[keyCode] ?? "Taste \(keyCode)"
    }
    
    /// Zeigt den Dialog zum Umbenennen eines Makros
    private func renameMacro() {
        guard let macro = viewModel.selectedMacro else { return }
        
        let alert = NSAlert()
        alert.messageText = "Makro umbenennen"
        alert.informativeText = "Bitte geben Sie einen neuen Namen für das Makro ein:"
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.stringValue = macro.name
        
        alert.accessoryView = inputTextField
        alert.addButton(withTitle: "Umbenennen")
        alert.addButton(withTitle: "Abbrechen")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let newName = inputTextField.stringValue, !newName.isEmpty {
                // Makro mit neuem Namen aktualisieren
                var updatedMacro = macro
                updatedMacro.name = newName
                
                if let index = viewModel.macros.firstIndex(where: { $0.id == macro.id }) {
                    viewModel.macros[index] = updatedMacro
                    viewModel.selectedMacro = updatedMacro
                }
            }
        }
    }
    
    /// Zeigt den Dialog zum manuellen Hinzufügen einer Aktion
    private func addManualAction() {
        let alert = NSAlert()
        alert.messageText = "Aktion hinzufügen"
        alert.informativeText = "Bitte wählen Sie den Typ der Aktion:"
        
        // Erstelle einen vertikalen Stack für die Bedienelemente
        let stackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 300, height: 120))
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        
        // Typ-Auswahl
        let typeLabel = NSTextField(labelWithString: "Aktionstyp:")
        let typePopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        typePopup.addItems(withTitles: ["Tastendruck", "Mausklick", "Verzögerung"])
        
        // Code/Verzögerung eingeben
        let codeLabel = NSTextField(labelWithString: "Code/Verzögerung:")
        let codeField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        codeField.placeholderString = "Keycode oder Verzögerung in ms"
        
        // Zustand auswählen
        let stateLabel = NSTextField(labelWithString: "Zustand:")
        let statePopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        statePopup.addItems(withTitles: ["Gedrückt", "Losgelassen"])
        
        // Alle Elemente zum Stack hinzufügen
        stackView.addArrangedSubview(typeLabel)
        stackView.addArrangedSubview(typePopup)
        stackView.addArrangedSubview(codeLabel)
        stackView.addArrangedSubview(codeField)
        stackView.addArrangedSubview(stateLabel)
        stackView.addArrangedSubview(statePopup)
        
        alert.accessoryView = stackView
        alert.addButton(withTitle: "Hinzufügen")
        alert.addButton(withTitle: "Abbrechen")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Aktion basierend auf den Eingaben erstellen
            let typeIndex = typePopup.indexOfSelectedItem
            let type: MacroActionType
            switch typeIndex {
            case 0:
                type = .keypress
            case 1:
                type = .mouseClick
            case 2:
                type = .delay
            default:
                type = .keypress
            }
            
            // Code oder Verzögerung parsen
            let valueString = codeField.stringValue
            let value = Int(valueString) ?? (type == .delay ? 100 : 0)
            
            // Zustand
            let state: MacroKeyState = statePopup.indexOfSelectedItem == 0 ? .pressed : .released
            
            // Aktion hinzufügen
            if type == .delay {
                viewModel.addAction(type: type, delay: value)
            } else {
                viewModel.addAction(type: type, keyCode: value, state: state)
            }
        }
    }
    
    /// Testet die Ausführung eines Makros
    private func testMacro() {
        guard let macro = viewModel.selectedMacro, !macro.actions.isEmpty else { return }
        
        // In einer echten Implementierung würde hier die Makroausführung
        // an den USBDeviceManager delegiert werden.
        print("Teste Makro: \(macro.name) mit \(macro.actions.count) Aktionen")
        
        // Zeige eine Benachrichtigung an
        let notification = NSUserNotification()
        notification.title = "Makro-Test"
        notification.informativeText = "Makro '\(macro.name)' wurde ausgeführt"
        NSUserNotificationCenter.default.deliver(notification)
    }
}

struct MacroView_Previews: PreviewProvider {
    static var previews: some View {
        MacroView()
            .environmentObject(USBDeviceManager.shared)
    }
}
