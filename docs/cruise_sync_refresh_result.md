State-Aktualisierung nach WebDAV-Sync – externe Prüfung

Stand: 14.09.2026. Implementiert, aber nicht auf iPhone/iPad reproduziert und
nicht mit Flutter/Dart ausgeführt. Aussagen zum bisherigen Verhalten beruhen
auf Codeanalyse. Die neuen Regressionstests sind für die externe Ausführung
vorbereitet.

Eine `AGENTS.md` existiert weder im Projekt noch in den geprüften übergeordneten
Projektverzeichnissen. Die vorhandene [agent.md](../agent.md) wurde vollständig
gelesen und befolgt. Abschnitt 16 untersagt Flutter-/Dart-Kommandos; deshalb
wurden weder Tests, Analyzer, Formatter, L10n-Generator, Paketinstallation noch
Builds ausgeführt. Die Anleitung schreibt keine Ergebnis-/Diff-Dateinamen vor.
Dieser Bericht und [cruise_sync_refresh.diff](cruise_sync_refresh.diff) folgen
dem vorhandenen Muster unter `docs/`. Kein Commit, keine Änderung am Git-Index.
Die bisherigen `cruise_documents`-Prüfdateien bleiben erhalten.

1. Root Cause und Neustart

`HomeScreen.build()` las `_store.activeCruises` vor dem `AnimatedBuilder` in
eine lokale Variable. `activeCruises` erzeugt eine neue unveränderliche Liste
mit sichtbaren Cruise-Kopien. Der Builder und die Tile-Callbacks hielten diese
Aufnahme fest. `notifyListeners()` baute nur den Builder-Inhalt neu auf, der
weiterhin dieselbe alte Liste verwendete. Damit konnten neue Cruises fehlen,
vorhandene Cruise-Texte veraltet bleiben und entfernte Cruises sichtbar bleiben.

Der aktive, synchronisierende `CruiseStore` übernimmt das Ergebnis im vorhandenen
Code bereits: Reload konkurrierender lokaler Änderungen, Reconciliation,
Ersetzen von `_cruises`, Neuaufbau von `_index`, abgewartete Persistenz und
Notification. Es fehlte hier kein allgemeiner Post-Sync-Reload. Der entscheidende
fehlende Schritt war das erneute Lesen dieses Store-Zustands innerhalb des
benachrichtigten Home-Builders.

Ein Neustart lädt die bereits gespeicherten Daten in eine neue Store-Instanz
und führt einen neuen äußeren Home-Build aus. Dadurch entsteht eine aktuelle
Listenaufnahme. Dies erklärt das Verschwinden des Home-Anzeigefehlers.

Unabhängig davon verwendete `CruiseHubScreen` `_cruise == null` als einziges
Ladekriterium. Nach einem abgeschlossenen Lookup ohne Treffer blieb der Spinner
deshalb unbegrenzt sichtbar. Auch ein Fehler beim Laden beendete diesen Zustand
nicht. `CruiseDetailsScreen` unterschied bereits Laden und Null-Lookup, fing
Ladefehler aber nicht ab und zeigte bei fehlender Cruise nur den Text „Cruise“.

Die konkrete Ursache für den gemeldeten erfolglosen Lookup ist ohne Gerätelogs
nicht bewiesen: Eine korrekt persistierte, nicht gelöschte Cruise sollte nach
abgeschlossenem `runAppSync()` in der neu ladenden Hub-Instanz auffindbar sein.
Die veraltete Home-Liste allein beweist keinen fehlenden Datensatz. Der Fix
beseitigt den nachgewiesenen Anzeige- und Endlos-Loading-Fehler; die vollständige
Zwei-Geräte-Reproduktion bleibt Bestandteil der externen Prüfung.

2. Nachverfolgter Datenfluss und Prüfung A–F

| Station / Hypothese | Befund und Änderung |
| --- | --- |
| Sync-Button | `HomeScreen._runCloudSync()` übergibt seinen aktiven Store an `SyncProgressScreen`. Kein zweiter Store für manuellen Sync. |
| Progress-Screen / E | Start nach dem ersten Frame; `_startSync()` wartet auf `store.runAppSync()`. Der Abschluss-/Schließen-Zustand hängt bereits an diesem Future. Zurücknavigation während eines laufenden Syncs bleibt möglich; sie beendet den Store-Sync nicht. |
| `runAppSync()` | Lädt bei Bedarf und verwendet `_runAppSync()` mit einer laufenden Operation pro Store. `AppSyncService` teilt außerdem den laufenden Netzwerksync zwischen Aufrufern. |
| WebDAV / Merge | `CruiseSyncService.sync()` lädt Baseline und Remote-Cruises, führt den Drei-Wege-Merge aus, lädt das Ergebnis hoch und speichert die Baseline. `WebDavSync` deserialisiert die gesamte Cruise einschließlich Unterobjekten und sichert die Remote-Datei vor Überschreiben. |
| App-Service | Führt Cruise- und Dokument-Sync aus. Die lokale Cruise-Persistenz ist Aufgabe des aufrufenden Stores; die gespeicherte Sync-Baseline ist keine zweite UI-Datenquelle. |
| Store / A | `_performAppSync()` lädt vor und nach dem Service lokale Daten, bewahrt zwischenzeitliche Änderungen durch `reconcileLocalChanges`, persistiert und benachrichtigt. Kein fehlender Reload auf dem manuellen Erfolgspfad. |
| Unterobjekte / B | Cruise, Route, Travel, Excursions und Dokument-IDs werden gemeinsam übernommen. `_rebuildIndex()` stellt Cruise- und Unterobjekt-Lookups bereit. Kein eigener unaktualisierter Route-Cache in diesem Pfad gefunden. |
| Home / C und D | Listener war vorhanden, sein Closure las aber eine veraltete Liste. Der Store-Zugriff liegt jetzt im Builder. Die Navigation verwendet weiterhin IDs. |
| Abschlussmeldung / E | Der Service meldete `completed`, bevor der Store Reconciliation/Persistenz beendet hatte. Der Progress-Screen maskierte dies bereits bis zum Future-Abschluss; andere Store-Listener konnten dennoch zu früh Erfolg sehen. Der Store hält terminale Service-Meldungen nun bis zur eigenen Ergebnisübernahme zurück. |
| Hub und Details / F | Beide laden aus einer eigenen Store-Instanz und suchen über die Cruise-ID. Fehlend/gelöscht und Ladefehler führen jetzt zu lokalisierten Meldungen statt unbegrenztem Laden. `mounted`-Prüfung und Freigabe der temporären Stores schützen den asynchronen Abschluss. |
| Weitere Datenhaltung | Cruise-Persistenz liegt in SharedPreferences unter `cruises_json_v3`. Alle hier betrachteten Cruise-Zugriffe nutzen denselben bestehenden Preferences-Zugang; es wurde kein zusätzlicher Cruise-Repository-Cache gefunden. `DocumentStore` liest Metadaten separat aus Preferences, Dateizugriffe bleiben im bestehenden Dokumentservice. |

3. Umfang des Fixes

Die Daten werden für Store-Listener gemeinsam mit dem terminalen Sync-Status
veröffentlicht, nachdem Liste und ID-Index aktualisiert und die Persistenz
abgewartet wurden. „Atomar“ bezieht sich hier auf diese Veröffentlichung; es
wird keine neue globale Transaktion zwischen allen Store-Instanzen eingeführt.
Fortschrittsmeldungen während des Syncs bleiben erhalten. Übersprungene/fehlende
Ergebnisse benachrichtigen ebenfalls nach dem bereits ausgeführten Store-Load.

Es gibt keinen zusätzlichen Reload nach Navigation, keinen Neustart-Mechanismus
und keinen künstlichen Full-Screen-Rebuild. Der Home-Konstruktor erhält lediglich
eine optionale Store-Injektion für Tests; regulär erstellt und besitzt Home
weiterhin seine eigene Store-Instanz. Ein injizierter Store gehört dem Aufrufer.

Unverändert bleiben Drei-Wege-Merge, Zeitstempel-/Löschkonflikte, Remote-Backup,
Baseline-Format, Schema und Serialisierung. Die vorhandenen Fälle „nur lokal“,
„nur remote“, „beide geändert“ und „gelöscht gegen geändert“ verwenden dieselben
Merge-/Reconciliation-Funktionen. Es gibt keinen neuen Sync-Trigger oder Timer.
Ein Folge-Sync bleibt ausschließlich bei bereits erkannten lokalen Änderungen
ausstehend, wie im bisherigen Code.

4. Geänderte Dateien

- `lib/screens/home_screen.dart`: Live-Liste innerhalb des Listener-Builders;
  optionale Store-Injektion mit klarer Ownership für Widgettests.
- `lib/store/cruise_store.dart`: terminalen Sync-Status erst mit dem lokal
  übernommenen Ergebnis an Listener veröffentlichen.
- `lib/screens/cruise_hub_screen.dart`: Laden, fehlende/gelöschte Cruise und
  Ladefehler unterscheiden; asynchronen Abschluss absichern.
- `lib/screens/details/cruise_details_screen.dart`: Ladefehler beenden und
  fehlende Cruise mit passender Meldung anzeigen.
- `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`: `cruiseNotFound` und
  `cruiseLoadFailed`. Die drei eingecheckten `app_localizations*.dart`-Dateien
  wurden dazu konsistent ergänzt, da der Generator nicht ausgeführt werden darf.
  ARB bleibt die Source of Truth.
- `test/app_sync_service_test.dart`: zwei zusätzliche Store-Regressionstests.
- `test/cruise_sync_refresh_test.dart`: neun neue Widgettest-Fälle.
- Dieser Bericht und `docs/cruise_sync_refresh.diff`: externe Prüfartefakte.

5. Regressionstests und Validierung

Die zwei Store-Tests laufen über den echten `CruiseStore`, `AppSyncService` und
`CruiseSyncService`, mit In-Memory-WebDAV an der Netzwerkgrenze. Sie prüfen für
manuellen und App-Open-Sync: zunächst A, danach A+B; blockierte Dokumentphase;
vollständige Listener-Snapshots; genau eine Abschlussmeldung mit bereits
persistiertem B; unmittelbare ID-Lookups von Cruise, Route, Hotel und Ausflug;
Erhalt der Dokument-IDs; unabhängiges Laden aus der Persistenz; kein unnötiger
Folge-Sync nach zwei Sekunden virtueller Zeit.

Die Widgettests verwenden einen echten aktiven Store mit simuliertem
Service-I/O. Sie prüfen den manuellen Button-/Progress-Screen-Pfad und den
Resume-Callback, aktualisieren zusätzlich Cruise A unter gleicher ID und
öffnen B über Home → Hub → Details. Die Home-Inhalte werden beim manuellen
Test bereits vor dem Zurückkehren vom Progress-Screen geprüft. Ein weiterer
Fall prüft die leere Home-Liste während eines verzögerten Launch-Syncs. Für
Hub und Details werden jeweils fehlende ID, Soft Delete und ungültiges lokales
JSON geprüft: Meldung vorhanden, kein Spinner, keine unbehandelte Exception.

Bestehende Tests zu parallelen Sync-Aufrufern, zwischenzeitlichen lokalen
Änderungen, Dokumentfehlern und Folge-Sync bleiben erhalten. Ebenso bleiben die
Tests in `test/sync_progress_screen_test.dart` zur aktiven Anzeige bis zum
Future-Abschluss erhalten und sollten extern mit ausgeführt werden.

Lokal geprüft: `git diff --check`, Syntax beider ARB-Dateien per JSON-Parser,
Übereinstimmung der neuen deutschen/englischen Texte mit ihren Dart-Gettern,
gezielte Code-/Aufruferprüfung. Keine Flutter-/Dart-Ausführung. Deshalb keine
Aussage, dass Tests oder Analyzer bereits bestanden hätten.

6. Andere Sync-Einstiegspunkte und verbleibende Grenzen

Launch, Resume und der verzögerte Store-Auto-Sync verwenden denselben
`_runAppSync()`-Pfad. Der Home-Listenfehler konnte bei allen Notifications seines
aktiven Stores auftreten und ist durch den gemeinsamen Builder-Fix adressiert.
Screen-Rückkehr verwendet weiter die bestehenden Loads. Der WebDAV-Settings-
Screen hat keinen eigenen vollständigen Cruise-Sync-Einstieg.

Die App besitzt mehrere unabhängige `CruiseStore`-Instanzen. Ein Store, der an
einem anderen Store-Sync nicht teilnimmt, erhält dessen Notifications nicht.
Bereits geöffnete Hub-/Details-Screens halten außerdem lokale Cruise-Snapshots
bis zu ihrem nächsten bestehenden Load. Solche übergreifenden stale-state-
Situationen bleiben architektonisch möglich; eine globale Store-Umstellung
oder automatische Reload-Schleifen sind nicht Teil dieses gezielten Fixes.
Die externe Zwei-Geräte-Prüfung sollte sowohl manuellen Sync als auch Resume
und das unmittelbare Öffnen der neuen Cruise umfassen.

Vorgeschlagene Commit-Message für eine spätere Übernahme (nicht ausgeführt):
`Fix cruise state refresh and missing-cruise loading after sync`
