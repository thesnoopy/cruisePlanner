Gemeinsame Orte für Cruise Planner
=================================

Pro `Cruise` gibt es eine persistierte Sammlung `locations` mit
`CruiseLocation`-Einträgen (`id`, `name`, `type`, `updatedAtUtc`, `deletedAtUtc`).
Die Typen sind `port` und `stopPoint`. `PortCallItem` bleibt ein zeitgebundener
Besuch und speichert `locationId`; `Excursion` speichert ebenfalls `locationId`.
Ortsnamen werden in beiden Fällen aus der gemeinsamen Sammlung gelesen.
Die alten Felder `portName` und `port` werden ausschließlich bei der Migration
gelesen und im neuen Schema nicht geschrieben.

Schemaänderung: **3 → 4**. Die bestehende Versionsprüfung verwendet nun die
gemeinsame Konstante `currentCruiseSchemaVersion`. Es gibt kein zusätzliches
Writer-Version-System. Die bisherigen SharedPreferences-Schlüssel
`cruises_json_v3` und `cruises_sync_baseline_v3` bleiben bestehen; die gespeicherte
Schema-Version ist maßgeblich. Die Baseline wird künftig ebenfalls mit einem
Schema-Wrapper gespeichert. Die App-Version in `pubspec.yaml` wurde nicht geändert.

Migration und Persistenz
-----------------------

Der vorhandene Migrationsbereich wurde um eine sequenzielle Verarbeitung
`1 → 2 → 3 → 4` erweitert. Historische optionale Felder werden weiterhin durch
die vorhandenen Model-Reader behandelt. Die vorhandene Normalisierung fehlender
Sync-Zeitstempel wird für Daten vor V3 wiederverwendet. Als deterministischer
Fallback dient der Unix-Epoch-Zeitpunkt, damit dieselben alten Daten auf mehreren
Geräten und in der Baseline identisch behandelt werden.

Die Migration V3 → V4 verarbeitet zunächst Hafenbesuche, danach Ausflüge.
Vergleiche verwenden ausschließlich Trimmen und Kleinschreibung. Passende Namen
teilen einen Ort; nicht zuordenbare Ausflugsorte werden als `stopPoint` angelegt.
Die erste erhaltene Schreibweise bleibt als Anzeigename bestehen. Die Migration
verwendet UUID v5 aus Kreuzfahrt-ID und normalisiertem Namen; neue Benutzerorte
verwenden die bestehende UUID-v4-Erzeugung. Persistierte Referenzen sind UUIDs,
keine Namen. Ein bereits migriertes Dokument erzeugt keine neuen IDs.

Lokaler Store, Repository-Leser, Remote-Leser und Baseline benutzen dieselbe
Migration. Das Ergebnis wird auf gültige Ortsreferenzen geprüft. Lokale Altdaten
werden nach erfolgreicher Migration als V4 gespeichert. Ungültige oder neuere
Versionen werden nicht als leere Kreuzfahrtlisten interpretiert.

WebDAV und Merge
----------------

1. Remote-Properties vor und nach dem Download sichern die Zuordnung zwischen
   gelesenen Bytes und ETag ab.
2. Die bestehende Prüfung verwirft Versionen oberhalb von 4 mit
   `RemoteCruiseSchemaTooNewException`. Ungültige Versionswerte werden ebenfalls
   abgelehnt. Danach sind weder Merge noch Upload erlaubt.
3. Unterstützte Altdaten werden migriert und validiert. Die Baseline ist ebenfalls
   migriert; der lokale Store liefert bereits aktuelle Modelle.
4. Der vorhandene Drei-Wege-Merge verarbeitet zusätzlich die Ortsammlung mit
   denselben Zeitstempel- und Löschregeln wie die anderen Entitäten.
5. Vor dem Upload sichert der bestehende `/old`-Pfad die alte Darstellung:
   bedingtes serverseitiges COPY, ersatzweise die ursprünglich heruntergeladenen
   Bytes. Backup-Namen enthalten zusätzlich Mikrosekunden zur Kollisionsvermeidung.
6. Der PUT verwendet `If-Match` mit dem ETag des Downloads. Bei einer fehlenden
   Remote-Datei wird `If-None-Match: *` verwendet. HTTP 412 bricht den Sync ab;
   die Baseline wird dann nicht geschrieben. Ein neuer Versuch lädt erneut.
7. Nach erfolgreichem Upload ersetzt der Response-ETag den alten Wert. Fehlt der
   Response-ETag, bleibt kein alter ETag als aktueller Wert gespeichert. Jeder
   weitere Sync lädt die Remote-Datei erneut. Erst nach erfolgreichem Upload wird
   die neue Baseline gespeichert.

Die bisherige Cruise-Implementierung las ETags nur vorbereitend; ihre Uploads
waren unbedingte Schreibvorgänge. Die Absicherung wurde innerhalb des bestehenden
WebDAV-Transports ergänzt. Für vorhandene Remote-Dateien ist jetzt ein starker
ETag erforderlich. Bei fehlendem oder schwachem ETag wird sicher abgebrochen.
Es gibt keinen unbedingten Fallback-Upload. Fehler laufen über den bestehenden
App-Sync-Fehlerstatus. Bereits veröffentlichte alte Apps behalten ihre vorhandene
Prüfung: Version 4 liegt oberhalb ihrer unterstützten Version 3.

UI und Sonderfälle
------------------

- Ausflugs- und Hafenbesuch-Editor verwenden dieselbe Ortsauswahl. Orte der Route
  stehen zuerst, weitere aktive Orte danach. Ein neuer Ort kann mit Name und Typ
  direkt angelegt werden, wird sofort gespeichert und automatisch ausgewählt.
  Die übrigen Formularfelder bleiben erhalten.
- Ein neuer Hafenbesuch erhält seinen Ort vor dem Speichern. Ausflugsentwürfe
  ohne bisherigen Ort bleiben lesbar (`locationId == null`); beim Speichern über
  den Editor ist eine Auswahl erforderlich.
- Leere alte Hafennamen werden als separate Orte erhalten. Es gibt kein Fuzzy
  Matching und keine globale Ortsdatenbank. Gleichnamige neue Orte werden bei
  expliziter Neuanlage nicht automatisch zusammengelegt.
- Referenzierte Orte können über den Store nicht gelöscht werden, auch wenn die
  Referenz selbst bereits gelöscht ist. Neue Orte ausschließlich gelöschter
  Alt-Einträge erhalten ebenfalls einen Löschzeitstempel. Bestehende Tombstones,
  Dokumentreferenzen und Seetage bleiben erhalten. Widersprüchliche Referenzen
  nach einem Merge führen zum Abbruch statt zur Wiederherstellung gelöschter Orte.
- Die unbenutzte ältere Modelldatei `lib/models/route_item.dart` bleibt unverändert;
  der persistierte Cruise-Datenpfad verwendet `lib/models/route/`.

Geänderte und neue Dateien
-------------------------

- `lib/models/cruise_location.dart` (neu)
- `lib/models/cruise.dart`
- `lib/models/excursion.dart`
- `lib/models/route/port_call_item.dart`
- `lib/store/cruise_store.dart`
- `lib/data/cruise_repository.dart`
- `lib/sync/cruise_persistence_migration.dart`
- `lib/sync/cruise_sync_service.dart`
- `lib/sync/webdav_sync.dart`
- `lib/widgets/cruise_location_selector.dart` (neu)
- `lib/screens/cruise_hub_screen.dart`
- `lib/screens/excursions/excursion_detail_screen.dart`
- `lib/screens/excursions/excursion_edit_screen.dart`
- `lib/screens/excursions/excursion_list_screen.dart`
- `lib/screens/route/port_call_detail_screen.dart`
- `lib/screens/route/route_edit_screen.dart`
- `lib/screens/route/route_list_screen.dart`
- `lib/services/share/pending_share_assignment_service.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `test/cruise_location_migration_test.dart` (neu)
- `test/cruise_location_webdav_test.dart` (neu)
- `test/cruise_location_selector_test.dart` (neu)
- `test/app_sync_service_test.dart`
- `test/chronological_list_screens_test.dart`
- `test/cruise_sync_refresh_test.dart`
- `test/sea_day_document_support_test.dart`
- `test/temporal_list_item_test.dart`
- `test/url_document_service_test.dart`
- `docs/cruise_locations_result.md` (neu)

Manuelle Validierung
--------------------

Gemäß `agent.md` wurden keine Flutter-/Dart-Befehle, Tests, Analyzer oder Builds
ausgeführt. Durchgeführt wurden Quelldurchsicht, ARB-JSON-/Schlüsselprüfung und
`git diff --check`. Die generierten Lokalisierungsdateien wurden nicht manuell
gepatcht. Vor Analyse, Tests oder Build müssen sie aus den ARBs erzeugt werden.

Im Projektordner ausführen:

```powershell
flutter gen-l10n --arb-dir=lib/l10n --template-arb-file=app_de.arb --output-dir=lib/l10n
$changedDartFiles = @(git diff --name-only -- '*.dart') + @(git ls-files --others --exclude-standard -- '*.dart')
dart format $changedDartFiles
flutter analyze
flutter test
flutter build apk --debug
```

Die neuen Tests prüfen Migration, Wiederöffnung, konservatives Matching,
Referenzsicherheit, Löschkonflikte, Ortsanlage und Formularerhalt. Die WebDAV-Tests
verwenden einen lokalen HTTP-Server und den tatsächlichen bestehenden Transport;
sie decken alte/neue Schemas, Backup-Fallback, ETags und konkurrierende Änderungen
ab. Die bestehenden betroffenen Tests wurden auf aktuelle Referenzen und
Schema-Wrapper umgestellt.

Zusätzlich manuell sinnvoll: eine V3-Datei von WebDAV synchronisieren, ihr
Original unter `/old` prüfen und anschließend mit einem zweiten Gerät erneut
synchronisieren. Im Editor einen vorhandenen Ort wählen sowie einen Zwischenstopp
neu anlegen und nach App-Neustart beide Beziehungen prüfen.

Vorgeschlagene Commit-Message:

```text
feat: share cruise locations and migrate schema v3 to v4 safely
```
