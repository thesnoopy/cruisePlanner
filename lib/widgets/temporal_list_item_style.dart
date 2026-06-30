import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/temporal_list_item.dart';

Color? temporalListItemContentColor(
  BuildContext context,
  TemporalListItemStatus status,
) {
  if (status != TemporalListItemStatus.past) {
    return null;
  }
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

Widget buildTemporalListItemStatusIcon(
  BuildContext context,
  TemporalListItemStatus status,
) {
  if (status != TemporalListItemStatus.past) {
    return const SizedBox.shrink();
  }

  final color = Theme.of(context).colorScheme.onSurfaceVariant;
  final loc = AppLocalizations.of(context)!;
  return Semantics(
    label: loc.pastStatusIconSemanticLabel,
    child: Icon(
      Icons.history,
      size: 18,
      color: color,
    ),
  );
}
