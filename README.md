# macOS-App für Pulsar X2

Eine macOS-Anwendung zur Konfiguration der Gaming-Maus Pulsar X2. Erstellt unter Anleitung von Claude 3.7 Sonnet.

## Beschreibung

Da die offizielle Pulsar-Software nur für Windows verfügbar ist, bietet diese App eine vollständige Konfiguration der Pulsar X2 unter macOS. Sie ermöglicht Zugriff auf alle wichtigen Funktionen der Maus wie DPI-Einstellungen, Polling-Rate, Lift-Off-Distanz (LOD), Tastenbelegung und Energiesparoptionen.

Diese App ist die Swift-Implementierung des ursprünglichen Python-CLI-Tools [pulsarX2-macOS-cli](https://github.com/lana-svetik/pulsarX2-macOS-cli).

## Funktionen

- Vollständige Kontrolle über die Mauseinstellungen unter macOS
- SwiftUI-Benutzeroberfläche
- Einstellung der DPI (50-32000)
- Anpassung der Polling-Rate (125-8000 Hz)
- Einstellung der Lift-Off-Distanz (0.7, 1.0, 2.0 mm)
- Vollständige Tastenkonfiguration
- Motion Sync und andere Performanceoptionen
- Energiesparoptionen für den kabellosen Betrieb
- Makro-Aufnahme und -Verwaltung
- Speichern und Laden von Profilen

## Systemanforderungen

- macOS 12.0 (Monterey) oder höher
- Apple Silicon oder Intel-Mac
- Admin-Rechte für USB-Zugriff

## Installation

```bash
git clone https://github.com/lana-svetik/pulsarX2-macOS-swift.git
cd pulsarX2-macOS-swift
open PulsarX2macOS/PulsarX2macOS.xcodeproj
```

Kompilieren Sie die App in Xcode und führen Sie sie aus oder exportieren Sie sie als App.

## Verwendung

1. Verbinden Sie Ihre Pulsar X2 mit Ihrem Mac
2. Starten Sie die PulsarX2macOS-App
3. Verwenden Sie die verschiedenen Registerkarten, um Ihre Maus anzupassen:
   - **Home**: Übersicht und allgemeine Einstellungen
   - **Anpassen**: DPI-Stufen, Polling-Rate und Tastenbelegung
   - **Performance**: Motion Sync, Ripple Control und andere Leistungsoptionen
   - **Makro**: Makroaufnahme und -verwaltung
   - **Energieoptionen**: Energiesparoptionen für den kabellosen Betrieb

## Besondere Features

### DPI-Management

Bis zu 6 DPI-Stufen mit individuellen Werten zwischen 50 und 32.000 DPI sind einstellbar. Der integrierte Slider ermöglicht eine präzise Einstellung in 10er-Schritten.

### Tastenzuordnung

Jede Taste der Maus kann individuell angepasst werden. Die verfügbaren Aktionen umfassen:
- Standard-Mausfunktionen
- DPI-Steuerung
- Tastaturkürzel
- Makros

### Energieoptionen

Für den kabellosen Betrieb bietet die App umfangreiche Energiesparfunktionen:
- Einstellbare Leerlaufzeit (30 s bis 15 min)
- Batterieschwellwert für den Energiesparmodus (5-20 %)
- Batteriestatus-Anzeige

## Architektur

Die App ist modular aufgebaut und verwendet die moderne SwiftUI-Framework für die Benutzeroberfläche. Die Architektur folgt dem MVVM-Muster (Model-View-ViewModel) mit folgenden Hauptkomponenten:

- **Models**: Datenmodelle für Profile, Einstellungen und Befehle
- **Services**: USB-Kommunikation und Profilmanagement
- **UI**: SwiftUI-Ansichten für die verschiedenen Bildschirme
- **Utilities**: Hilfsfunktionen für Protokollierung und Berechtigungsverwaltung

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).
