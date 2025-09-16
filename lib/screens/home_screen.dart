// lib/screens/home_screen.dart
import 'package:cruise_app/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import '../models/cruise.dart';
import '../models/ship.dart';
import '../models/period.dart';
import '../utils/date_fmt.dart';
import 'cruise_wizard_page.dart';
import '../data/cruise_repository.dart';
import '../sync/webdav_sync.dart';
import '../settings/webdav_settings_store.dart';
import '../settings/webdav_settings.dart';

import 'webdav_settings_page.dart';
import 'cruise_detail_page.dart';
import 'package:cruise_app/gen/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final CruiseRepository repo;
  const HomeScreen({
    super.key,
    required this.repo,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ❌ final _repo = CruiseRepository();  // weg!
  final _settingsStore = const WebDavSettingsStore();
  WebDavSettings? _wdSettings;
  WebDavSync? _sync;
  Cruise? _lastDeleted;
  int? _lastDeletedIndex;

  List<Cruise> _cruises = <Cruise>[];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _openSettings() async {
    final translations = context.t;
    final result = await Navigator.push<WebDavSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => WebDavSettingsPage(initial: _wdSettings),
      ),
    );
    if (result != null) {
      setState(() {
        _wdSettings = result;
        _sync = WebDavSync(result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translations.webDavConfigured)),
      );
    }
  }

  Future<void> _initSettings() async {
    final s = await _settingsStore.load();
    if (!mounted) return;

    if (s == null) {
      return;
    }

    setState(() {
      _wdSettings = s;
      _sync = WebDavSync(s);
    });
  }

  Future<void> _loadSettings() async {
    final s = await _settingsStore.load();
    if (!mounted) return;
    setState(() {
      _wdSettings = s;
      _sync = s == null ? null : WebDavSync(s);
    });
  }

  Future<void> _load() async {
    try {
      final items = await widget.repo.load(); // <— übergebenes Repo verwenden
      if (!mounted) return;
      setState(() {
        _cruises = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final translations = context.t;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translations.couldNotLoadData + ' $e')),
      );
    }
  }

  Future<void> _syncNow() async {
    final translations = context.t;
    final sync = _sync;
    if (sync == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translations.pleaseEnterWebdavCredentials)),
      );
      return;
    }

    setState(() => _syncing = true);
    const tolerance = Duration(seconds: 2);

    bool isAfterWithTol(DateTime a, DateTime b, Duration tol) {
      return a.isAfter(b.add(tol));
    }

    // Helper: Sekunden-runden (wie im Repo)
    DateTime roundSec(DateTime dt) {
      final u = dt.toUtc();
      return DateTime.utc(u.year, u.month, u.day, u.hour, u.minute, u.second);
    }

    try {
      final remote = await sync.statRemote(); // mTime & eTag (oder null, wenn Datei fehlt)
      final localAt = await widget.repo.localModifiedAt(); // lokale mTime
      final storedETag = await widget.repo.remoteETag();

      // 1) Datei existiert remote nicht → hochladen
      if (remote == null || remote.mTimeUtc == null) {
        await sync.uploadCruises(_cruises); // kein If-Match nötig
        final r2 = await sync.statRemote();
        await widget.repo.save(
          _cruises,
          modifiedAtUtc: r2?.mTimeUtc != null ? roundSec(r2!.mTimeUtc!) : DateTime.now().toUtc(),
          remoteETag: r2?.eTag,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translations.uploadOk)));
        }
        return;
      }

      // 2) Lokal noch nie gespeichert → remote gewinnt
      if (localAt == null) {
        final remoteList = await sync.downloadCruises();
        await widget.repo.save(
          remoteList,
          modifiedAtUtc: roundSec(remote.mTimeUtc!),
          remoteETag: remote.eTag,
        );
        if (mounted) setState(() => _cruises = remoteList);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translations.downloadOk)));
        }
        return;
      }

      // 3) ETag-Logik vorrangig verwenden, falls verfügbar
      if (remote.eTag != null && storedETag != null) {
        if (remote.eTag != storedETag) {
          // Remote wurde geändert → Download
          final remoteList = await sync.downloadCruises();
          await widget.repo.save(
            remoteList,
            modifiedAtUtc: roundSec(remote.mTimeUtc!),
            remoteETag: remote.eTag,
          );
          if (mounted) setState(() => _cruises = remoteList);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translations.remoteWasNewerEtag)));
          }
          return;
        } else {
          // ETag unverändert → wenn lokal seitdem geändert → Upload mit If-Match
          final remoteM = roundSec(remote.mTimeUtc!);
          final localM  = roundSec(localAt);
          final localNewer = isAfterWithTol(localM, remoteM, tolerance);

          if (localNewer) {
            await sync.uploadCruises(_cruises, ifMatchETag: remote.eTag);
            final r2 = await sync.statRemote();
            await widget.repo.save(
              _cruises,
              modifiedAtUtc: r2?.mTimeUtc != null ? roundSec(r2!.mTimeUtc!) : DateTime.now().toUtc(),
              remoteETag: r2?.eTag ?? remote.eTag, // neuen ETag übernehmen (oder alten)
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translations.localWasNewerUpload)));
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translations.alreadyUpToDate)));
            }
          }
          return;
        }
      }

      // 4) Fallback: nur Zeitvergleich (falls ETag fehlt)
      final remoteM = roundSec(remote.mTimeUtc!);
      final localM  = roundSec(localAt);

      final remoteNewer = isAfterWithTol(remoteM, localM, tolerance);
      final localNewer  = isAfterWithTol(localM, remoteM, tolerance);

      if (remoteNewer) {
        final remoteList = await sync.downloadCruises();
        await widget.repo.save(
          remoteList,
          modifiedAtUtc: remoteM,
          remoteETag: remote.eTag,
        );
        if (mounted) setState(() => _cruises = remoteList);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translations.remoteWasNewerDownload)));
        }
      } else if (localNewer) {
        await sync.uploadCruises(_cruises, ifMatchETag: remote.eTag);
        final r2 = await sync.statRemote();
        await widget.repo.save(
          _cruises,
          modifiedAtUtc: r2?.mTimeUtc != null ? roundSec(r2!.mTimeUtc!) : DateTime.now().toUtc(),
          remoteETag: r2?.eTag,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translations.localWasNewerUpload)));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translations.alreadyUpToDate)));
        }
      }
    } catch (e, st) {
      debugPrint(translations.syncError + '$e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translations.syncFailed + '$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _openWizard() async {
    final translations = context.t;
    final now = DateTime.now();
    final draft = Cruise(
      id: Cruise.newId(),
      title: '',
      ship: const Ship(name: '', shippingLine: ''),
      period: Period(
        start: DateTime(now.year, now.month, now.day),
        end:   DateTime(now.year, now.month, now.day),
      ),
    );

    final created = await Navigator.push<Cruise>(
      context,
      MaterialPageRoute(
        builder: (_) => CruiseWizardPage(initial: draft),
        fullscreenDialog: true,
      ),
    );

    if (created != null) {
      setState(() => _cruises = [..._cruises, created]);
      try {
        await widget.repo.save(_cruises); // <— hier speichern
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(translations.stored + ' „${created.title}“')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(translations.storingFailed + '$e')),
          );
        }
      }
    }
  }

  Future<bool> _confirmDelete(BuildContext context, Cruise c) async {
  final t = AppLocalizations.of(context)!;
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(t.deleteCruiseTitle),
          content: Text(
                      t.deleteCruiseMessage(c.title.isEmpty ? t.noTitle : c.title),
                    ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.deleteCancel)),
            FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: Text(t.deleteConfirm)),
          ],
        ),
      ) ??
      false;
  }

  Future<void> _deleteCruise(int index) async {
    final t = AppLocalizations.of(context)!;
    final c = _cruises[index];

    setState(() {
      _lastDeleted = c;
      _lastDeletedIndex = index;
      _cruises = List.of(_cruises)..removeAt(index);
    });

    // Sofort speichern; bei Undo speichern wir erneut.
    await widget.repo.save(_cruises);

    final snack = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.deletedCruiseSnack(c.title.isEmpty ? t.noTitle : c.title)),
        action: SnackBarAction(
          label: t.undo,
          onPressed: () async {
            if (_lastDeleted != null && _lastDeletedIndex != null) {
              setState(() {
                _cruises = List.of(_cruises)..insert(_lastDeletedIndex!, _lastDeleted!);
              });
              await widget.repo.save(_cruises);
            }
          },
        ),
      ),
    );

    await snack.closed;
    _lastDeleted = null;
    _lastDeletedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return Scaffold(
      appBar: AppBar(
        // ✅ HomeScreen zeigt die Gesamtliste – kein Zugriff auf eine einzelne cruise hier
        title: Text(translations.cruises),
        actions: [
          IconButton(
            onPressed: _syncing ? null : _syncNow,
            icon: _syncing ? const Icon(Icons.sync) : const Icon(Icons.cloud_sync),
            tooltip: translations.syncWithWebdav,
          ),
          IconButton(
            tooltip: translations.settings,
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openWizard,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cruises.isEmpty
              ? Center(child: Text(translations.noCruiseYet))
              : RefreshIndicator(
                  onRefresh: _load, // Pull-to-refresh lädt lokal neu
                  child: ListView.separated(
                    itemCount: _cruises.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final c = _cruises[index];
                      return Dismissible(
                        key: ValueKey(c.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(context, c),
                        onDismissed: (_) async {
                          // Index kann sich verschoben haben; suche aktuelle Position
                          final idx = _cruises.indexWhere((x) => x.id == c.id);
                          if (idx >= 0) await _deleteCruise(idx);
                        },
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                        child: ListTile(
                          onTap: () async {
                            final updated = await Navigator.push<Cruise>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CruiseDetailPage(
                                  cruise: c,
                                  repo: widget.repo,
                                ),
                              ),
                            );
                            if (updated != null && updated != c) {
                              setState(() => _cruises[index] = updated);
                              await widget.repo.save(_cruises);
                            }
                          },
                          title: Text(c.title.isEmpty ? translations.noTitle : c.title),
                          subtitle: Text(
                            '${c.ship.name.isEmpty ? '—' : c.ship.name} · '
                            '${c.ship.shippingLine.isEmpty ? '—' : c.ship.shippingLine}\n'
                            '${ymd(c.period.start)} → ${ymd(c.period.end)}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final ok = await _confirmDelete(context, c);
                                if (ok) {
                                  final idx = _cruises.indexWhere((x) => x.id == c.id);
                                  if (idx >= 0) await _deleteCruise(idx);
                                }
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete),
                                    const SizedBox(width: 8),
                                    Text(translations.delete),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
