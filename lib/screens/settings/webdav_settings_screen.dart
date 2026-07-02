import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../settings/webdav_settings.dart';
import '../../settings/webdav_settings_store.dart';

class WebDavSettingsScreen extends StatefulWidget {
  const WebDavSettingsScreen({super.key});

  @override
  State<WebDavSettingsScreen> createState() => _WebDavSettingsScreenState();
}

class _WebDavSettingsScreenState extends State<WebDavSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _store = const WebDavSettingsStore();

  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _store.load();

    if (settings != null) {
      _baseUrlController.text = settings.baseUrl;
      _usernameController.text = settings.username;
      _passwordController.text = settings.password;
      _remotePathController.text = settings.remotePath;
    } else {
      _remotePathController.text = '/CruiseApp/cruises.json';
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final loc = AppLocalizations.of(context)!;

    setState(() => _saving = true);

    final settings = WebDavSettings(
      baseUrl: _baseUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      remotePath: _remotePathController.text.trim(),
    );

    await _store.save(settings);

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.webdavSettingsSaved)));
  }

  Future<void> _clear() async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.webdavSettingsDeleteTitle),
        content: Text(loc.webdavSettingsDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.confirmCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    await _store.clear();

    _baseUrlController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _remotePathController.clear();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.webdavSettingsDeleted)));
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.webdavSettingsTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _baseUrlController,
                        decoration: InputDecoration(
                          labelText: loc.webdavSettingsBaseUrlLabel,
                          hintText: loc.webdavSettingsBaseUrlHint,
                          prefixIcon: const Icon(Icons.cloud_outlined),
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.webdavSettingsBaseUrlRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: loc.webdavSettingsUsernameLabel,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.webdavSettingsUsernameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: loc.webdavSettingsPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return loc.webdavSettingsPasswordRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _remotePathController,
                        decoration: InputDecoration(
                          labelText: loc.webdavSettingsRemotePathLabel,
                          hintText: loc.webdavSettingsRemotePathHint,
                          prefixIcon: const Icon(Icons.folder_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.webdavSettingsRemotePathRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(loc.save),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _clear,
                            icon: const Icon(Icons.delete_outline),
                            label: Text(loc.delete),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.webdavSettingsStorageHint,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
