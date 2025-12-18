import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shows a generic confirmation dialog and returns `true` if the user confirms.
///
/// If [title], [message], [okText] or [cancelText] are not provided, localized
/// default texts are used.
///
/// If [icon] is provided, it is displayed next to the title.
/// Set [destructive] to true to style the confirm button as a destructive action
/// (e.g., delete).
Future<bool> showConfirmationDialog({
  required BuildContext context,
  String? title,
  String? message,
  String? okText,
  String? cancelText,
  IconData? icon,
  bool destructive = false,
  bool barrierDismissible = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      final loc = AppLocalizations.of(ctx)!;

      final effectiveTitle = title ?? loc.confirmDefaultTitle;
      final effectiveMessage = message ?? loc.confirmDefaultMessage;
      final effectiveOk = okText ?? loc.confirmOk;
      final effectiveCancel = cancelText ?? loc.confirmCancel;

      final colorScheme = Theme.of(ctx).colorScheme;

      final Widget titleWidget = icon == null
          ? Text(effectiveTitle)
          : Row(
              children: [
                Icon(
                  icon,
                  color: destructive ? colorScheme.error : colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(effectiveTitle)),
              ],
            );

      final ButtonStyle? confirmStyle = destructive
          ? FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            )
          : null;

      return AlertDialog(
        title: titleWidget,
        content: Text(effectiveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(effectiveCancel),
          ),
          FilledButton(
            style: confirmStyle,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(effectiveOk),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
