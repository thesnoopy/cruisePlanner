Dokumentzuordnung an Cruises – Ergebnis für die externe Prüfung

Stand: 14.09.2026. Die Korrektur ist implementiert. Die Aussagen zum bisherigen
Verhalten beruhen auf der Codeanalyse; eine Laufzeitreproduktion auf dem Gerät
und die Ausführung der Tests stehen noch aus. Ob der gemeldete Fehler auch ohne
WebDAV auftritt, wurde vom Benutzer noch nicht geprüft.

Im Projekt und in den übergeordneten Projektverzeichnissen wurde keine
`AGENTS.md` gefunden. Die vorhandene [agent.md](../agent.md) wurde vollständig
gelesen und befolgt. Abschnitt 16 untersagt Flutter-/Dart-Kommandos. Deshalb
wurden weder Tests noch Analyzer, Formatter, Paketinstallation oder Builds
ausgeführt. Die Datei enthält keine Vorgabe für Namen oder Formate der
Prüfartefakte; dieser Bericht und [cruise_documents.diff](cruise_documents.diff)
erfüllen den ausdrücklichen Wunsch nach Ergebnis und Diff. Es gibt keinen Commit.

1. Ursachen und Erklärung des Verlusts

Der lokale Attachment-Pfad unterstützt bereits mehrere Dokumente. Er ergänzt
`Cruise.documentIds` mit `DocumentIds.appendUnique`; es gibt hier keine einzelne
Document-ID und keine Zuweisung einer Liste nur mit dem neuen Dokument.

Ein Verlustpfad liegt in `CruiseStore._performAppSync`: Der Sync erhielt bisher
den möglicherweise veralteten Speicherstand einer Store-Instanz und schrieb
sein Ergebnis nach dem Netzwerk- und Dokument-Sync ungeprüft zurück. Andere
Screens und Dokumentservices erzeugen eigene `CruiseStore`-Instanzen. Änderungen
aus diesen Instanzen oder während eines laufenden Syncs konnten somit durch
einen älteren vollständigen Cruise-Snapshot überschrieben werden.

Konkreter Ablauf: Ein Sync startet mit einer Cruise ohne Dokumente. Während der
Dokumentphase wird A verknüpft und persistiert. Anschließend schreibt der alte
Sync seine Cruise ohne A zurück. Beim nächsten Verknüpfen von B liest der
Attachment-Service bereits die überschriebene Liste und ergänzt diese um B.
Das Ergebnis enthält nur B. Das Entfernen von A passiert in diesem Ablauf beim
Übernehmen des Sync-Ergebnisses, nicht in `appendUnique`.

Zusätzlich enthielt der zu Aufgabenbeginn vorhandene, noch nicht committete
Arbeitsstand in `CruiseSyncService._mergeCruiseLegacy` einen Cruise-spezifischen
Ausschluss von `documentIds`. `_mergeLegacyEntity` beginnt mit der Remote-Map.
Ein ausgeschlossenes Feld bleibt deshalb vollständig auf dem Remote-Stand.
Beispiel: Basis `[A]`, lokal `[A, B, C]`, remote `[A]` mit verändertem Titel und
gleichen oder fehlenden Zeitstempeln. Vor der Korrektur blieb `[A]` erhalten und
B/C gingen verloren. Ebenso konnte ein lokal entferntes Dokument wiederkehren.
Dieser zusätzliche Fehler stammt aus dem angetroffenen Arbeitsstand; er war
noch nicht Teil von `HEAD`. Er erklärt nicht für sich allein, welche Version
auf dem Gerät den ursprünglichen Fehler ausgelöst hat.

Der zuvor vorhandene Sync-Test verwendete eine leere Remote-Cruise-Liste.
Damit wurde der frühe Zweig `remote == null` durchlaufen, der die lokale Cruise
behält. Der fehlerhafte Legacy-Konflikt-Merge wurde dadurch nicht getestet.

2. Nachvollzogener Datenfluss und Referenzimplementierungen

| Station | Befund |
| --- | --- |
| `CruiseDetailsScreen` / `CruiseEditScreen` | Navigation erfolgt per Cruise-ID. Die Edit-Ansicht enthält die schreibbare Document Section. Beim Speichern der Cruise lädt der Screen die aktuelle Cruise und verwendet deren `copyWith`. |
| `CruiseDocumentsSection` | Auswahl, Dateiimport und URL-Snapshot delegieren an Services. Nach Verknüpfen/Entfernen wird neu geladen. Die Anzeige iteriert über alle `linkedDocuments`. `allowMultiple: false` im Dateipicker begrenzt nur eine Auswahlaktion. |
| `CruiseDocumentSectionService` | `loadForCruise` löst alle Links auf; verfügbare Dokumente werden über die bereits verknüpften IDs ausgefiltert. Attach/Detach delegieren an den gemeinsamen Attachment-Service. |
| `DocumentAttachmentService` | Lädt vor Zugriff den persistierten Cruise-Stand. Attach nutzt `appendUnique`, Detach `remove`; anschließend wird `copyWith(documentIds: ...)` gespeichert. `_resolveDocuments` löst jede ID im `DocumentStore` auf. |
| `DocumentIds` / `Cruise` | Zuordnungen liegen als normalisierte, unveränderliche `List<String>` in der Entität. `copyWith`, `toMap`, `fromMap` und Equatable-`props` berücksichtigen die gesamte Liste. Fehlende Legacy-Listen werden als leer gelesen. |
| `DocumentRecord` | Enthält Dokumentmetadaten, Dateireferenz, Hash, Zeitstempel und Löschstatus. Keine einzelne Cruise-ID und keine zweite Attachment-Struktur. `copyWith` und JSON erhalten diese Metadaten. |
| `DocumentStore` / `DocumentFileStore` | Metadaten werden nach Document-ID in `document_store_v1` gespeichert; `saveDocument`/`saveDocuments` ergänzen bzw. aktualisieren nach ID. Dateien bleiben unter relativen Pfaden im File-Store. |
| `CruiseStore` | Persistiert sämtliche `documentIds` innerhalb `cruises_json_v3`, Schema 3. V1-/Legacy-Migration und sichtbare Cruise-Kopien erhalten die Dokumentliste. |
| Dateiimport / Pending Shares | `DocumentImportService.importFileIfNeeded` verwendet Hash-Deduplizierung, sonst eine neue UUID. `PendingShareAssignmentService._assignFileItem` verwendet denselben Cruise-Section-Service. Kein separater Cruise-Importpfad. |
| URL-Import | `UrlDocumentService._attachDocument` delegiert auch für Cruise an `DocumentAttachmentService`. |
| Unlink / Lifecycle | Cruise-Detach entfernt genau die angegebene ID. `DocumentReferenceCleanupService` prüft Referenzen an allen unterstützten Entitäten, bevor der letzte Unlink das Dokument soft-deleted. |
| Sync / Merge | Cruise-JSON und Baseline enthalten die komplette Liste. Der separate Dokument-Sync arbeitet mit Dokumentmetadaten nach ID. Die beiden oben beschriebenen Überschreibungen betreffen die Cruise-Snapshots und deren Übernahme. |

Als Referenz wurden Excursion-, TravelItem-, PortCall- und SeaDay-Sections samt
Section-Services, Modellen und Attachment-Methoden verglichen. Sie verwenden
dieselben `appendUnique`-/`remove`-Operationen und dieselbe Auflösung der
Dokumentliste. Auch Cruise nutzt dieses gemeinsame Muster bereits. Die
Abweichung lag im Sync: Bei den anderen Entitäten nimmt `documentIds` regulär
am gemeinsamen Feldvergleich teil. Cruise wurde an dieses Verhalten angeglichen.

3. Implementierte Änderung und Kompatibilität

| Geänderte Datei | Änderung |
| --- | --- |
| [lib/store/cruise_store.dart](../lib/store/cruise_store.dart) | Lädt vor Sync-Beginn sowie vor Ergebnisübernahme den persistierten Stand ohne zusätzliche Zwischenbenachrichtigungen. Führt aktuelle lokale Änderungen und Sync-Ergebnis anhand des tatsächlichen Sync-Eingangsstands zusammen. Plant einen weiteren Auto-Sync, wenn noch nicht hochgeladene lokale Änderungen verbleiben. |
| [lib/sync/app_sync_service.dart](../lib/sync/app_sync_service.dart) | Fixiert die Eingabeliste für den gestarteten Sync und liefert sie als optionales `localCruisesAtSyncStart` im Ergebnis mit. Mitlaufende Aufrufer erhalten dieselbe tatsächliche Grundlage, auch bei Fehlern der Dokumentphase nach erfolgreichem Cruise-Sync. |
| [lib/sync/cruise_sync_service.dart](../lib/sync/cruise_sync_service.dart) | Entfernt den angetroffenen `documentIds`-Ausschluss. `reconcileLocalChanges` verwendet den bestehenden Drei-Wege-Merge erneut. Dafür wurden dessen zustandslose private Methoden statisch gemacht; die bestehende Test-API bleibt erhalten. |
| [test/app_sync_service_test.dart](../test/app_sync_service_test.dart) | Erweitert die vorhandenen Regressionstests sowie den Test zur gemeinsamen Nutzung eines laufenden Syncs. |

Es gibt keinen neuen Importweg und keinen zweiten Merge-Algorithmus. Das
Nachladen wurde im Store gekapselt; Widgets enthalten keine neue Geschäftslogik.
Die bestehenden Regeln zu Zeitstempeln, Löschung versus Änderung und
Remote-Backups bleiben erhalten. Das erneute Einplanen erfolgt ausschließlich,
wenn nach der Ergebnisübernahme noch lokale Änderungen ausstehen.

`Cruise`, `DocumentRecord`, `DocumentIds`, deren JSON-Strukturen sowie
SharedPreferences-Schlüssel und Schema-Versionen wurden nicht verändert.
`localCruisesAtSyncStart` ist ausschließlich ein optionales Feld des
In-Memory-Sync-Ergebnisses und wird nicht persistiert. Bestehende gespeicherte
Dokumente und Links benötigen keine Migration. Bereits zuvor verlorene
Zuordnungen werden durch diesen Fix nicht automatisch rekonstruiert.

4. Regressionstests und Prüfstatus

Die Gruppe `Cruise document references` enthält jetzt 24 parametrisierte bzw.
einzelne Testfälle: die vier vorhandenen Fälle wurden beibehalten oder
weiterentwickelt, 20 weitere Fälle kamen hinzu.

| Abdeckung | Erwartung |
| --- | --- |
| A: Section-Service verknüpft A, B und C nacheinander | Nach jedem Schritt stimmen Store, angezeigte Dokumentliste und verfügbare Dokumente. Erneutes Verknüpfen erzeugt kein Duplikat. |
| B: B aus `[A, B, C]` entfernen | Nur A/C bleiben; nur das unreferenzierte B wird soft-deleted. Wiederholtes Entfernen ist wirkungslos. Ein weiterer Link an einer Excursion schützt Bs Metadaten. |
| C: JSON-Encode/Decode und neuer Store | Alle drei IDs und Dokumentmetadaten bleiben erhalten; zusätzlich `copyWith`, fehlende Legacy-Listen und Normalisierung. |
| D: Cruise-Sync mit simuliertem WebDAV | Reales Baseline-Laden, Drei-Wege-Merge, Upload-Serialisierung, Baseline-Speichern, lokale Persistenz und erneutes Laden behalten A/B/C. Der syncende Store startet mit einer älteren In-Memory-Kopie als der persistierte Stand. |
| D: Konflikte | Vorhandene Remote-Cruise mit geändertem Titel und gleichen/fehlenden Zeitstempeln; lokales Hinzufügen und Entfernen; einseitige Änderungen in beiden Richtungen; neuere Löschung versus neuere Bearbeitung in beiden Richtungen. |
| D: Änderungen während des Syncs | Attach und Unlink in derselben sowie einer anderen Store-Instanz; Remote-Ausflug bleibt zusätzlich erhalten; A geht beim anschließenden Hinzufügen von B/C nicht verloren. |
| D: Gemeinsamer laufender Sync | Zwei Stores mit verschiedenen lokalen Ständen verwenden den ursprünglichen gemeinsamen Eingangsstand. Der bereits vorhandene AppSync-Service-Test prüft diese Grundlage ebenfalls. |
| D: Folgesync und Fehlerfall | Ein bereits während des laufenden Syncs ausgelöster Mutationstimer verschluckt den nötigen Folgesync nicht. Nach erfolgreichem Nachupload entsteht keine Schleife. Neue Links bleiben auch bei fehlgeschlagener Dokumentphase erhalten. |

Die Tests ersetzen Netzwerkzugriffe durch kontrollierte Runner bzw. einen
In-Memory-WebDAV. Die Attachment-Services, Modelle, SharedPreferences-Persistenz
und Cruise-Merge-Logik werden direkt verwendet. Neue Store-Fixtures werden
entsorgt, damit Auto-Sync-Timer nicht in andere Tests hineinlaufen.

Ausgeführt wurden die statische Code-/Diff-Prüfung und `git diff --check`.
Der aufgabenbezogene Diff wurde mit
`git apply --reverse --check --ignore-space-change docs/cruise_documents.diff`
gegen den fertigen Arbeitsstand geprüft, ohne Dateien zurückzusetzen.
Diese Prüfungen ersetzen keine Testausführung und keine Typprüfung.

Für die externe Prüfung sind die Tests in `test/app_sync_service_test.dart`
auszuführen. Zusätzlich ist der konkrete UI-Ablauf mit deaktiviertem WebDAV
und mit aktiviertem, verzögertem Sync zu prüfen: A/B/C hinzufügen, B entfernen,
Ansicht verlassen, App neu laden und alle verbleibenden Links kontrollieren.
Ein bestandener Lauf dieser Prüfungen wird hier ausdrücklich nicht behauptet.

5. Abgrenzung des Diffs

`cruise_documents.diff` beschreibt ausschließlich die Änderungen dieser Aufgabe
gegenüber dem zu Aufgabenbeginn vorhandenen Arbeitsstand, nicht gegenüber
`HEAD`. Er enthält die vier geänderten Dart-Dateien; Bericht und Diff selbst
sind nicht rekursiv im Patch enthalten.

Schon zu Beginn waren `lib/sync/cruise_sync_service.dart` und
`test/app_sync_service_test.dart` geändert. Die vorhandenen Tests wurden
weiterentwickelt. Die fachlich fehlerhafte `documentIds`-Ausnahme wurde gezielt
korrigiert. Deshalb ist gerade deren Entfernung im aufgabenbezogenen Diff
sichtbar, obwohl sie im üblichen Vergleich gegen `HEAD` nicht als Entfernung
erscheint. Andere vorhandene Änderungen wurden nicht zurückgesetzt.
