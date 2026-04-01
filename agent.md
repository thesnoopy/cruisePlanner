# agent.md

Leitfaden für AI-Agents und Maintainer im Repository `cruisePlanner`.

## 1) Projektziel

CruisePlanner ist eine Flutter-Anwendung zur Verwaltung von Kreuzfahrten mit folgenden Kernbereichen:

- Cruise-Details
- Route
- Ausflüge
- Reise-Logistik (Travel)
- optionaler WebDAV-Cloud-Sync

## 2) Relevante Codebereiche

- **State/Persistenz:** `lib/store/cruise_store.dart`
- **Sync:** `lib/sync/webdav_sync.dart`, `lib/sync/cruise_sync_service.dart`
- **Modelle:** `lib/models/**`
- **UI:** `lib/screens/**`, `lib/widgets/**`
- **Lokalisierung:** `lib/l10n/**`

## 3) Standard-Workflow für Änderungen

1. Scope eingrenzen (`rg`, gezielte Datei-Inspektion).
2. Kleine, fokussierte Änderungen umsetzen.
3. Qualitätschecks laufen lassen.
4. Dokumentation aktualisieren (`README.md`, ggf. `agent.md`).
5. Commit mit präziser Message erstellen.

## 4) Technische Regeln

### Modell-/Datenregeln

- Bei neuen Modellfeldern immer Serialization (`toMap`/`fromMap`) und `copyWith` prüfen.
- Gleichheitslogik (z. B. Equatable/`props`) konsistent halten.
- SharedPreferences-Strukturen nur kompatibel ändern oder Migration ergänzen.

### Sync-Regeln

- Änderungen an Merge-Strategien sind verhaltenskritisch.
- Vor Merge-Änderungen mindestens diese Fälle validieren:
  - lokal geändert / remote unverändert
  - remote geändert / lokal unverändert
  - beide geändert
  - gelöscht vs. geändert

### UI-/L10n-Regeln

- Keine hardcodierten UI-Texte, stattdessen `AppLocalizations`.
- Neue Texte in **beiden** ARB-Dateien pflegen (`de`, `en`).

## 5) Checks vor Abschluss

Wenn Flutter verfügbar ist:

```bash
flutter --version
flutter analyze
flutter test
```

Wenn Flutter in der Umgebung fehlt, als Umgebungslimit dokumentieren.

## 6) Git-/Push-Hinweise

- Zielbranch für Auslieferung ist in der Regel `main`.
- Wenn lokal ein anderer Arbeitsbranch verwendet wird, kann gezielt nach `main` gepusht werden, z. B.:

```bash
git push origin HEAD:main
```

- Existiert kein Remote oder fehlen Berechtigungen, muss das im Ergebnis explizit gemeldet werden.
