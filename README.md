# CruisePlanner

CruisePlanner ist eine Flutter-App zur strukturierten Planung von Kreuzfahrten – inklusive Reisevorbereitung, Route, Ausflügen und optionaler Cloud-Synchronisierung per WebDAV.

> Aktueller App-Stand laut `pubspec.yaml`: `0.3.0+19`.

## Funktionsumfang

Pro Kreuzfahrt kannst du folgende Bereiche verwalten:

- **Cruise-Details:** Titel, Schiff, Zeitraum, optionale Kabinen-/Decknummer
- **Route:** Seetage und Hafenanläufe mit Zeitangaben
- **Ausflüge:** Planung inkl. Zahlungs-/Kosteninformationen
- **Reiseanreise/-abreise:** Flug, Bahn, Transfer, Mietwagen, Hotel, Cruise Check-In/Check-Out
- **Cloud-Sync:** WebDAV-Synchronisierung mit Merge-Logik für Mehrgerätebetrieb
- **Mehrsprachigkeit:** Deutsch und Englisch (systemabhängig)

## Technologie

- **Framework:** Flutter (Material 3)
- **Sprache:** Dart (`sdk: ^3.9.2`)
- **Lokale Speicherung:** SharedPreferences
- **Cloud-Anbindung:** WebDAV
- **Lokalisierung:** `flutter_localizations` + ARB-Dateien

## Architektur (kurz)

```text
lib/
  models/        Domänenmodelle (Cruise, RouteItem, TravelItem, Excursion, ...)
  store/         App-State + Persistenz (CruiseStore)
  sync/          WebDAV-Client + 3-Wege-Merge (CruiseSyncService)
  screens/       UI-Screens für Home/Hub/Details/Route/Travel/Excursions/Settings
  settings/      WebDAV-Konfiguration
  l10n/          Übersetzungen (app_de.arb, app_en.arb)
  widgets/       Wiederverwendbare UI-Komponenten
  utils/         Formatierung und Helferfunktionen
```

## Synchronisierung (WebDAV)

Die Synchronisierung besteht aus zwei Ebenen:

1. **Transport:** `WebDavSync` lädt/speichert Cruise-Daten in der Cloud.
2. **Konfliktauflösung:** `CruiseSyncService` führt einen **3-Wege-Merge** aus:
   - Baseline (letzter erfolgreicher Sync)
   - lokaler Stand
   - Remote-Stand

Aktuelle Konfliktregeln im Code:

- **Beide ändern denselben Datensatz:** Remote gewinnt.
- **Änderung vs. Löschung:** Änderung gewinnt.
- **Nur eine Seite geändert:** diese Seite gewinnt.

## Lokale Entwicklung

### Voraussetzungen

- Installiertes Flutter SDK (mit Dart)
- Optional WebDAV-Zugangsdaten für Cloud-Sync

### Setup

```bash
flutter pub get
```

### App starten

```bash
flutter run
```

### Qualitätschecks

```bash
flutter analyze
flutter test
```

## Lokalisierung

- Übersetzungsdateien: `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb`
- Neue UI-Texte immer über `AppLocalizations` hinzufügen, nicht hardcodiert.

## Beitragshinweise

- Änderungen möglichst klein und klar abgegrenzt halten.
- Bei Modelländerungen immer `toMap` / `fromMap` / `copyWith` mitpflegen.
- Persistenz-/Sync-Änderungen mit Fokus auf Rückwärtskompatibilität und Konfliktszenarien prüfen.
- Bei UI-Textänderungen beide ARB-Sprachen aktualisieren.
