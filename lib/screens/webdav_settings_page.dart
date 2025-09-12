import 'package:flutter/material.dart';
import '../settings/webdav_settings.dart';
import '../settings/webdav_settings_store.dart';
import '../sync/webdav_sync.dart';
import 'package:cruise_app/gen/l10n/app_localizations.dart';

class WebDavSettingsPage extends StatefulWidget {
  final WebDavSettings? initial;
  const WebDavSettingsPage({super.key, this.initial});

  @override
  State<WebDavSettingsPage> createState() => _WebDavSettingsPageState();
}

class _WebDavSettingsPageState extends State<WebDavSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _store = const WebDavSettingsStore();

  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _pathCtrl;

  bool _obscure = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _baseUrlCtrl = TextEditingController(text: s?.baseUrl ?? '');
    _userCtrl    = TextEditingController(text: s?.username ?? '');
    _passCtrl    = TextEditingController(text: s?.password ?? '');
    _pathCtrl    = TextEditingController(text: s?.remotePath ?? '/CruiseApp/cruises.json');
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  String _normBaseUrl(String v) {
    final t = v.trim();
    if (t.isEmpty) return t;
    return t.endsWith('/') ? t : '$t/';
  }

  String _normPath(String v) {
    final t = v.trim();
    if (t.isEmpty) return t;
    return t.startsWith('/') ? t : '/$t';
  }

  WebDavSettings _collect() {
    return WebDavSettings(
      baseUrl: _normBaseUrl(_baseUrlCtrl.text),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      remotePath: _normPath(_pathCtrl.text),
    );
  }

  Future<void> _testConnection() async {
    final translations = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final settings = _collect();
    setState(() => _busy = true);
    try {
      final sync = WebDavSync(settings);
      await sync.ping(); // prüft Basis-URL/Auth
      // Optional: exakt die Datei prüfen
      // final info = await sync.statRemote(); // existiert evtl. noch nicht
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translations.connectionOk)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translations.connectionFailed + ' $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final settings = _collect();
    final translations = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await _store.save(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translations.stored)),
        );
        Navigator.pop(context, settings); // an Aufrufer zurückgeben
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translations.storingFailed + ' $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(translations.webdavSettings)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _baseUrlCtrl,
                  decoration: InputDecoration(
                    labelText: translations.baseUrl,
                    hintText: translations.baseUrlHintText,
                  ),
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return translations.pleaseEnterBaseUrl;
                    if (!t.startsWith('http')) return translations.urlMustStartWithHttp;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _userCtrl,
                  decoration: InputDecoration(
                    labelText: translations.username,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? translations.pleaseEnterUsername : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  decoration: InputDecoration(
                    labelText: translations.password,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? translations.pleaseEnterPassword : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pathCtrl,
                  decoration: InputDecoration(
                    labelText: translations.remotePath,
                    hintText: '/CruiseApp/cruises.json',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? translations.pleaseEnterPath : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _testConnection,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(translations.testConnection),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _save,
                        icon: const Icon(Icons.save),
                        label: Text(translations.store),
                      ),
                    ),
                  ],
                ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
