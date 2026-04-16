import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../l10n/app_localizations.dart';

String suggestedDocumentTitleFromFileName(String fileName) {
  final trimmedFileName = fileName.trim();
  if (trimmedFileName.isEmpty) {
    return '';
  }

  final baseName = p.basenameWithoutExtension(trimmedFileName).trim();
  return baseName.isEmpty ? trimmedFileName : baseName;
}

String suggestedDocumentTitleFromUrl(String rawUrl) {
  final normalizedUrl = rawUrl.trim();
  if (normalizedUrl.isEmpty) {
    return '';
  }

  final uri = Uri.tryParse(normalizedUrl);
  if (uri == null) {
    return normalizedUrl;
  }

  final pathSegments = uri.pathSegments
      .map((segment) => Uri.decodeComponent(segment).trim())
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (pathSegments.isNotEmpty) {
    final baseName = p.basenameWithoutExtension(pathSegments.last).trim();
    if (baseName.isNotEmpty) {
      return baseName;
    }
  }

  final host = uri.host.trim();
  if (host.isNotEmpty) {
    return host;
  }

  return normalizedUrl;
}

Future<String?> showDocumentTitlePromptDialog({
  required BuildContext context,
  required String initialTitle,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _DocumentTitlePromptDialog(initialTitle: initialTitle),
  );
}

class _DocumentTitlePromptDialog extends StatefulWidget {
  const _DocumentTitlePromptDialog({
    required this.initialTitle,
  });

  final String initialTitle;

  @override
  State<_DocumentTitlePromptDialog> createState() =>
      _DocumentTitlePromptDialogState();
}

class _DocumentTitlePromptDialogState
    extends State<_DocumentTitlePromptDialog> {
  late final TextEditingController _controller;

  String get _normalizedTitle => _controller.text.trim();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _normalizedTitle;
    if (title.isEmpty) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.importDocument),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: loc.title,
          errorText: _normalizedTitle.isEmpty ? loc.requiredField : null,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.confirmCancel),
        ),
        FilledButton(
          onPressed: _normalizedTitle.isEmpty ? null : _submit,
          child: Text(loc.importDocument),
        ),
      ],
    );
  }
}
