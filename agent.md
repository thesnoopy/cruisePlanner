# agent.md

Leitfaden für AI-Agents und Maintainer im Repository `cruisePlanner`.

---

## 1) Projektziel

CruisePlanner ist eine Flutter-Anwendung zur Verwaltung von Kreuzfahrten mit folgenden Kernbereichen:

- Cruise-Details  
- Route  
- Ausflüge  
- Reise-Logistik (Travel)  
- optionaler WebDAV-Cloud-Sync  

---

## 2) Architekturprinzipien (SEHR WICHTIG)

- UI (Screens/Widgets) muss möglichst **„dumm“** bleiben  
- Geschäftslogik gehört ausschließlich in:
  - Store (`cruise_store.dart`)
  - Services (`sync/**`)
  - Helper (`utils/**`)
- **Keine Logik in Widgets verschieben oder neu einbauen**
- Screens arbeiten primär mit IDs und holen Daten aus dem Store
- Änderungen müssen die bestehende Architektur respektieren

---

## 3) Relevante Codebereiche

- **State/Persistenz:** `lib/store/cruise_store.dart`  
- **Sync:** `lib/sync/webdav_sync.dart`, `lib/sync/cruise_sync_service.dart`  
- **Modelle:** `lib/models/**`  
- **UI:** `lib/screens/**`, `lib/widgets/**`  
- **Lokalisierung:** `lib/l10n/**`  

---

## 4) Standard-Workflow für Änderungen

1. Scope eingrenzen (gezielte Datei-Inspektion, keine globalen Änderungen)  
2. Kleine, fokussierte Änderungen umsetzen  
3. Bestehende Logik respektieren (keine stillen Refactors)  
4. Qualitätschecks durchführen  
5. Dokumentation aktualisieren (`README.md`, ggf. `agent.md`)  
6. Commit mit präziser Message erstellen  

---

## 5) Änderungsregeln (CRITICAL für AI-Agents)

- **Keine unnötigen Refactorings**
- **Keine Änderungen außerhalb des betroffenen Scopes**
- Bestehende Struktur beibehalten
- Keine neuen Dependencies ohne klaren Grund
- Bestehende APIs nicht stillschweigend ändern
- Keine „Cleanups“, die Verhalten beeinflussen könnten

---

## 6) Modell-/Datenregeln

- Bei neuen Feldern IMMER prüfen:
  - `toMap`
  - `fromMap`
  - `copyWith`
- Gleichheitslogik konsistent halten (z. B. Equatable)
- SharedPreferences-Daten:
  - nur kompatibel ändern ODER
  - Migration implementieren
- JSON muss **stabil und nachvollziehbar** bleiben

---

## 7) Sync-Regeln (SEHR SENSIBEL)

Änderungen an der Sync-Logik sind kritisch.

Vor Änderungen IMMER folgende Fälle berücksichtigen:

- lokal geändert / remote unverändert  
- remote geändert / lokal unverändert  
- beide geändert (Konfliktfall)  
- gelöscht vs. geändert  

Zusätzlich:

- „neuer gewinnt“ Strategie respektieren (ETag + Timestamp)
- Remote-Backup vor Überschreiben beibehalten
- Merge-Logik darf keine Daten verlieren

---

## 8) UI- und L10n-Regeln

- Keine hardcodierten Texte → immer `AppLocalizations`
- Neue Texte in **allen ARB-Dateien** pflegen
- UI bleibt einfach → keine Business-Logik im Widget
- Bestehende UI-Struktur nicht unnötig verändern

---

## 9) Logging & Debugging

- Kritische Prozesse (Sync, Persistenz) müssen nachvollziehbar loggen
- Logs sollen erklären:
  - warum eine Entscheidung getroffen wurde
  - welcher Zustand gewählt wurde
- Keine unnötigen `print`-Statements in finalem Code

---

## 10) Flutter-Umgebung

- Flutter ist möglicherweise **nicht in der Agent-Umgebung verfügbar**
- Code muss auch ohne Ausführung korrekt sein
- Fokus liegt auf **Dart-Code und Logik**
- Änderungen sollen lokal bestehen:

```bash
flutter analyze
flutter test
```

---

## 11) Qualitätschecks

Wenn Flutter verfügbar ist:

```bash
flutter analyze
flutter test
```

Wenn nicht verfügbar:

- Änderungen logisch prüfen
- mögliche Risiken dokumentieren

---

## 12) Git-Workflow

- Zielbranch ist in der Regel `main`
- **Direkte Pushes auf main vermeiden**, wenn nicht explizit gewünscht
- Bevorzugt Feature-Branches verwenden
- Commit-Messages müssen klar und präzise sein

Beispiel:

```bash
git commit -m "Fix: prevent data loss in WebDAV merge conflict"
```

---

## 13) Verhalten von AI-Agents

- Änderungen müssen minimal-invasiv sein
- Keine Annahmen über nicht sichtbaren Code treffen
- Bestehende Patterns beibehalten
- Bei Unsicherheit: konservative Lösung wählen
- Fokus: Stabilität > Eleganz

---
