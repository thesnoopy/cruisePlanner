import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/temporal_list_item.dart';

const BorderRadius temporalListItemCardBorderRadius = BorderRadius.all(
  Radius.circular(16),
);

class TemporalListItemCardStyle {
  const TemporalListItemCardStyle({
    this.backgroundColor,
    required this.shape,
    this.contentColor,
  });

  final Color? backgroundColor;
  final ShapeBorder shape;
  final Color? contentColor;
}

TemporalListItemCardStyle temporalListItemCardStyle(
  BuildContext context,
  TemporalListItemStatus status,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final pastItemFill = Color.alphaBlend(
    Colors.grey.shade200.withValues(alpha: 0.8),
    colorScheme.surface,
  );
  final pastItemBorder = Colors.grey.shade400.withValues(alpha: 0.45);
  final currentItemFill = Color.alphaBlend(
    Colors.green.shade100.withValues(alpha: 0.65),
    colorScheme.surface,
  );
  final currentItemBorder = Colors.green.shade400.withValues(alpha: 0.55);

  switch (status) {
    case TemporalListItemStatus.past:
      return TemporalListItemCardStyle(
        backgroundColor: pastItemFill,
        contentColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: temporalListItemCardBorderRadius,
          side: BorderSide(
            color: pastItemBorder,
          ),
        ),
      );
    case TemporalListItemStatus.current:
      return TemporalListItemCardStyle(
        backgroundColor: currentItemFill,
        shape: RoundedRectangleBorder(
          borderRadius: temporalListItemCardBorderRadius,
          side: BorderSide(
            color: currentItemBorder,
            width: 1.2,
          ),
        ),
      );
    case TemporalListItemStatus.upcoming:
      return const TemporalListItemCardStyle(
        shape: RoundedRectangleBorder(
          borderRadius: temporalListItemCardBorderRadius,
        ),
      );
  }
}

Color? temporalListItemContentColor(
  BuildContext context,
  TemporalListItemStatus status,
) {
  return temporalListItemCardStyle(context, status).contentColor;
}

Color? temporalListItemCardColor(
  BuildContext context,
  TemporalListItemStatus status,
) {
  return temporalListItemCardStyle(context, status).backgroundColor;
}

ShapeBorder temporalListItemCardShape(
  BuildContext context,
  TemporalListItemStatus status,
) {
  return temporalListItemCardStyle(context, status).shape;
}

Widget buildTemporalListItemStatusIcon(
  BuildContext context,
  TemporalListItemStatus status,
) {
  if (status != TemporalListItemStatus.past) {
    return const SizedBox.shrink();
  }

  final color =
      temporalListItemCardStyle(context, status).contentColor ??
      Theme.of(context).colorScheme.onSurfaceVariant;
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
