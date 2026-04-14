# agent.md

Leitfaden für AI-Agents und Maintainer im Repository `cruisePlanner`.

---

## 1) Projektziel

CruisePlanner ist eine Flutter-Anwendung zur Verwaltung von Kreuzfahrten mit folgenden Kernbereichen:

- Cruise-Details
- Route
- Ausflüge
- Reise-Logistik (Travel)
- Dokumente / Attachments
- optionaler WebDAV-Cloud-Sync
- native Share-Intake auf Android und iOS

Ziel ist eine stabile, lokal nutzbare App mit robuster Persistenz, konsistenter UI und offline-sicherem Verhalten.

---

## 2) Allgemeine Arbeitsregeln (CRITICAL)

- Änderungen müssen **minimal-invasiv** sein
- Nur den **betroffenen Scope** ändern
- Keine unnötigen Refactorings
- Keine „Cleanups“, die Verhalten still verändern
- Bestehende Patterns und Architektur beibehalten
- Bei Unsicherheit: **konservative Lösung**
- Stabilität ist wichtiger als Eleganz

---

## 3) Kommunikationsregeln

- Kommunikation mit dem User: **Deutsch**
- Codex-/Agent-Prompts: **Englisch**
- Technische Aussagen klar und präzise formulieren
- Keine unbelegten Annahmen über nicht sichtbaren Code treffen

---

## 4) Repository- und Pfadregeln

- Änderungen **nur innerhalb des Projektordners**
- Niemals außerhalb des Repository-/Projektpfads schreiben
- Für dieses Projekt gilt insbesondere:
  - Änderungen nur innerhalb von `cruise_app`, falls dies im Arbeitskontext so vorgegeben ist
- Keine Dateien anlegen oder verschieben, wenn es nicht wirklich nötig ist

---

## 5) Architekturprinzipien (SEHR WICHTIG)

- UI (Screens/Widgets) muss möglichst **„dumm“** bleiben
- Geschäftslogik gehört ausschließlich in:
  - Store
  - Services
  - Models
  - Extensions
  - klar abgegrenzte Helper
- **Keine Business-Logik in Widgets einbauen**
- Screens arbeiten bevorzugt mit **IDs** und holen Daten aus dem Store
- Navigation soll möglichst **IDs statt kompletter Model-Objekte** übergeben
- Store ist die zentrale fachliche Instanz / Source of Truth
- Services kapseln IO und plattformspezifische Logik
- Models bleiben fachlich sauber und möglichst simpel

---

## 6) Relevante Codebereiche

- **State/Persistenz:** `lib/store/**`
- **Sync:** `lib/sync/**`
- **Modelle:** `lib/models/**`
- **Services:** `lib/services/**`
- **UI:** `lib/screens/**`, `lib/widgets/**`
- **Lokalisierung:** `lib/l10n/**`
- **Native Android-Integration:** `android/**`
- **Native iOS-Integration:** `ios/**`

---

## 7) Änderungsregeln für Code

- Keine Änderungen außerhalb des konkreten Problems
- Keine stillen API-Änderungen
- Keine stillen Verhaltensänderungen
- Keine unnötigen neuen Abhängigkeiten
- Keine breiten Dependency-Upgrades ohne klaren Grund
- Bestehende Datenflüsse respektieren
- Bereits vorhandene Logik bevorzugt **wiederverwenden statt kopieren**
- Keine Duplikation von Logik, wenn ein bestehender Service/Helper erweitert werden kann

---

## 8) Modell-/Datenregeln

Bei Änderungen an Modellen oder persistierten Daten immer prüfen:

- `toMap` / `toJson`
- `fromMap` / `fromJson`
- `copyWith`
- Gleichheitslogik (z. B. Equatable)
- bestehende Serialisierung
- Rückwärtskompatibilität

Für persistierte Daten gilt:

- SharedPreferences-/JSON-Strukturen nur kompatibel ändern
- wenn nicht kompatibel: Migration implementieren
- JSON muss stabil, nachvollziehbar und konsistent bleiben

---

## 9) Dokument-Subsystem (SEHR WICHTIG)

Das Dokument-Subsystem ist ein eigener sensibler Bereich.

### Grundregeln
- `DocumentStore` ist die **lokale Metadaten-Authority**
- `DocumentFileStore` ist die **lokale File-Authority**
- Remote-/WebDAV-Logik gehört nur in:
  - `DocumentRemoteStore`
  - oder dedizierte Sync-/Remote-Services
- Keine Remote-Logik in `DocumentStore`
- Keine Remote-Logik in `DocumentFileStore`

### Persistenzregeln
- Dokument-Metadaten bleiben kompatibel
- Keine zweite Metadatenstruktur einführen
- Relative Pfade bevorzugen, keine unnötigen absoluten Pfade
- Dokumente fachlich als immutable behandeln, soweit bestehende Architektur das vorsieht

### Verlinkung / Lifecycle
- Dokumente können an Cruise / Excursion / TravelItem / PortCall hängen
- Duplicate-Erkennung und Linking-Verhalten respektieren
- Bestehende Import-Pipeline wiederverwenden
- Kein zweiter Dokument-Importpfad
- Letzter Unlink muss zu korrektem Soft Delete führen
- Hard Delete / Cleanup darf nur auf bestehender Lifecycle-Logik aufbauen

---

## 10) Share-Intake-Regeln (ANDROID / iOS)

Die App verwendet native Share-Intake-Pfade.

### Grundregeln
- Kein Drittplugin für Share-Intake erneut einführen, wenn der native Bridge-Ansatz etabliert ist
- Android- und iOS-Bridge sollen möglichst unter derselben Flutter-seitigen Abstraktion laufen
- Native Plattformteile bleiben **dünn**
- Flutter-seitig bleibt `ShareIntakeService` die zentrale Intake-/Pending-Queue-Schicht

### iOS
- Share Extension bleibt **nativ und leichtgewichtig**
- Datenaustausch über **App Group / Shared Resources**
- Keine unnötige Flutter-UI in der Extension
- Die Haupt-App übernimmt Pending-Review / Assignment / Import
- iOS-Extension-Flow möglichst robust und systemkonform halten

### Android
- Native Share-Intents im Plattformcode kapseln
- Daten in normalisierter Form an Flutter übergeben
- Keine UI-Logik in den nativen Bridges

### Allgemein
- Pending-Queue-Logik nicht duplizieren
- Review-/Assignment-/Import-Flow in Flutter wiederverwenden
- Keine Sonderwege pro Zielobjekt, wenn bestehende Import-/Linking-Services genutzt werden können

---

## 11) Sync-Regeln (SEHR SENSIBEL)

Änderungen an der Sync-Logik sind kritisch.

Vor Änderungen immer folgende Fälle berücksichtigen:

- lokal geändert / remote unverändert
- remote geändert / lokal unverändert
- beide geändert (Konfliktfall)
- gelöscht vs. geändert

Zusätzlich:

- „neuer gewinnt“-Strategie respektieren, soweit bestehend
- ETag-/Timestamp-Logik nicht still verändern
- Remote-Backups vor Überschreiben beibehalten, falls vorhanden
- Merge-Logik darf keine Daten verlieren
- Sync soll möglichst offline-sicher und robust bleiben
- Keine zufälligen Trigger-/Timing-Änderungen ohne klaren Grund

---

## 12) UI- und L10n-Regeln

- Keine hardcodierten Texte → immer `AppLocalizations`
- Neue Texte in **allen relevanten ARB-Dateien** pflegen
- ARB-Dateien sind die Source of Truth
- Keine kaputten Encodings / Mojibake
- UI bleibt einfach
- Keine Business-Logik im Widget
- Bestehende UI-Struktur nicht unnötig verändern
- Neue Debug-/Status-UI nur so lange wie nötig und später wieder bereinigen

---

## 13) Native Plattformregeln

### Android
- Änderungen in `android/**` minimal halten
- Keine breiten Gradle-Workarounds, wenn ein gezielter Fix reicht
- Plugin-/Toolchain-Probleme möglichst an der echten Ursache beheben

### iOS
- Änderungen in `ios/**` besonders vorsichtig
- Share Extension, App Group, URL-/Handoff-Mechanismen und Build-/Signing-Setup respektieren
- Keine generierten Dateien als dauerhafte Lösung patchen
- Pod-/Xcode-/Build-Workarounds nur, wenn sie deterministisch und source-controlled sind
- Extension-spezifische Logik von Runner-Logik sauber trennen

---

## 14) Logging & Debugging

- Kritische Prozesse müssen nachvollziehbar loggen
- Logs sollen erklären:
  - warum eine Entscheidung getroffen wurde
  - welcher Zustand gewählt wurde
- Keine unnötigen `print`-Statements in finalem Code
- Temporäre Debug-Ausgaben nach erfolgreicher Verifikation wieder entfernen oder entschärfen

---

## 15) Standard-Workflow für Änderungen

1. Scope eingrenzen
2. Relevante Dateien gezielt prüfen
3. Kleine, fokussierte Änderung umsetzen
4. Bestehende Logik respektieren
5. Offensichtliche Folgestellen mitprüfen
6. L10n / Serialisierung / Persistenz mitprüfen, falls betroffen
7. Dokumentation aktualisieren, wenn sinnvoll
8. Präzise Commit-Message formulieren

---

## 16) Qualitätschecks / Tooling-Regeln

Egal ob Flutter lokal verfügbar ist, niemals ausführen:

Benutze niemals flutter commandos, wie z.B. flutter analyze, dart format, flutter pub get, usw.