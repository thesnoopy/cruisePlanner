import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../settings/ai_document_analysis_settings.dart';
import '../../settings/ai_document_analysis_settings_store.dart';

class AiDocumentAnalysisSettingsScreen extends StatefulWidget {
  const AiDocumentAnalysisSettingsScreen({super.key});

  @override
  State<AiDocumentAnalysisSettingsScreen> createState() =>
      _AiDocumentAnalysisSettingsScreenState();
}

class _AiDocumentAnalysisSettingsScreenState
    extends State<AiDocumentAnalysisSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _store = const AiDocumentAnalysisSettingsStore();

  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();

  bool _enabled = false;
  bool _sendPdfWhenOcrIsInsufficient = false;
  bool _loading = true;
  bool _saving = false;
  AiDocumentAnalysisProvider _provider = AiDocumentAnalysisProvider.openAi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _store.load() ?? const AiDocumentAnalysisSettings();

    _enabled = settings.enabled;
    _provider = settings.provider;
    _apiKeyController.text = settings.apiKey ?? '';
    _modelController.text = settings.model ?? '';
    _sendPdfWhenOcrIsInsufficient = settings.sendPdfWhenOcrIsInsufficient;

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    final settings = AiDocumentAnalysisSettings(
      enabled: _enabled,
      provider: _provider,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
      sendPdfWhenOcrIsInsufficient: _sendPdfWhenOcrIsInsufficient,
    );

    await _store.save(settings);

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.aiDocumentAnalysisSettingsSaved)));
  }

  Future<void> _clear() async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.aiDocumentAnalysisSettingsDeleteTitle),
        content: Text(loc.aiDocumentAnalysisSettingsDeleteMessage),
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

    _enabled = false;
    _provider = AiDocumentAnalysisProvider.openAi;
    _apiKeyController.clear();
    _modelController.clear();
    _sendPdfWhenOcrIsInsufficient = false;

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.aiDocumentAnalysisSettingsDeleted)),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsAiDocumentAnalysisTitle),
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
                      Card(
                        color: theme.colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      loc.aiDocumentAnalysisPrivacyTitle,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme
                                                .onErrorContainer,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                loc.aiDocumentAnalysisPrivacyCloudWarning,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                loc.aiDocumentAnalysisPrivacyPiiWarning,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                loc.aiDocumentAnalysisPrivacyLocalOcrHint,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _enabled,
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() => _enabled = value);
                              },
                        title: Text(loc.aiDocumentAnalysisEnabledLabel),
                        subtitle: Text(
                          _enabled
                              ? loc.aiDocumentAnalysisStatusEnabled
                              : loc.aiDocumentAnalysisStatusDisabled,
                        ),
                        secondary: const Icon(Icons.auto_awesome_outlined),
                      ),
                      const SizedBox(height: 8),
                      Text(loc.aiDocumentAnalysisOptionalHint),
                      if (_enabled) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<AiDocumentAnalysisProvider>(
                          initialValue: _provider,
                          decoration: InputDecoration(
                            labelText: loc.aiDocumentAnalysisProviderLabel,
                            prefixIcon: const Icon(Icons.hub_outlined),
                          ),
                          items: AiDocumentAnalysisProvider.values
                              .map(
                                (provider) => DropdownMenuItem(
                                  value: provider,
                                  child: Text(_providerLabel(loc, provider)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _saving
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() => _provider = value);
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _apiKeyController,
                          enabled: !_saving,
                          decoration: InputDecoration(
                            labelText: loc.aiDocumentAnalysisApiKeyLabel,
                            prefixIcon: const Icon(Icons.key_outlined),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _modelController,
                          enabled: !_saving,
                          decoration: InputDecoration(
                            labelText: loc.aiDocumentAnalysisModelLabel,
                            prefixIcon: const Icon(Icons.tune_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _sendPdfWhenOcrIsInsufficient,
                          onChanged: _saving
                              ? null
                              : (value) {
                                  setState(
                                    () =>
                                        _sendPdfWhenOcrIsInsufficient = value,
                                  );
                                },
                          title: Text(loc.aiDocumentAnalysisSendPdfLabel),
                        ),
                      ],
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
                        loc.aiDocumentAnalysisStorageHint,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _providerLabel(
    AppLocalizations loc,
    AiDocumentAnalysisProvider provider,
  ) {
    switch (provider) {
      case AiDocumentAnalysisProvider.openAi:
        return loc.aiDocumentAnalysisProviderOpenAi;
      case AiDocumentAnalysisProvider.gemini:
        return loc.aiDocumentAnalysisProviderGemini;
      case AiDocumentAnalysisProvider.custom:
        return loc.aiDocumentAnalysisProviderCustom;
    }
  }
}
