import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AiDocumentAnalysisSettingsScreen extends StatelessWidget {
  const AiDocumentAnalysisSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsAiDocumentAnalysisTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.aiDocumentAnalysisStatusDisabled,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(loc.aiDocumentAnalysisOptionalHint),
                    const SizedBox(height: 8),
                    Text(loc.aiDocumentAnalysisNotConfiguredHint),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
