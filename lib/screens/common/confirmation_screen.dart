import 'package:flutter/material.dart';

/// A small, reusable confirmation page that returns a boolean via Navigator.
///
/// You can pass [message], [okText], and [cancelText]. If not provided, sensible
/// defaults are shown.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    this.title,
    this.message,
    this.okText,
    this.cancelText,
  });

  final String? title;
  final String? message;
  final String? okText;
  final String? cancelText;

  @override
  Widget build(BuildContext context) {
    final materialLoc = MaterialLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    final defaultTitle = lang == 'de' ? 'Bestätigung' : 'Confirmation';
    final defaultMessage = lang == 'de'
        ? 'Möchtest du fortfahren?'
        : 'Do you want to continue?';

    final effectiveTitle = title?.trim().isNotEmpty == true ? title! : defaultTitle;
    final effectiveMessage =
        message?.trim().isNotEmpty == true ? message! : defaultMessage;
    final effectiveOk = okText?.trim().isNotEmpty == true
        ? okText!
        : materialLoc.okButtonLabel;
    final effectiveCancel = cancelText?.trim().isNotEmpty == true
        ? cancelText!
        : materialLoc.cancelButtonLabel;

    return Scaffold(
      appBar: AppBar(title: Text(effectiveTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              effectiveMessage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(effectiveCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(effectiveOk),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
