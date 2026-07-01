import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/documents/url_document_target.dart';
import '../../models/share/share_intake_payload.dart';
import '../../screens/documents/url_snapshot_capture_screen.dart';
import '../../services/documents/url_document_service.dart';
import '../../services/share/pending_share_assignment_service.dart';
import '../../widgets/documents/document_title_prompt_dialog.dart';

class PendingShareAssignmentScreen extends StatefulWidget {
  const PendingShareAssignmentScreen({
    super.key,
    required this.batchId,
    required this.itemIndex,
    this.service,
  });

  final String batchId;
  final int itemIndex;
  final PendingShareAssignmentService? service;

  @override
  State<PendingShareAssignmentScreen> createState() =>
      _PendingShareAssignmentScreenState();
}

String _itemTitle(ShareIntakeItem item) {
  final candidate = switch (item.kind) {
    ShareIntakeItemKind.file || ShareIntakeItemKind.image =>
      item.fileName?.trim(),
    ShareIntakeItemKind.text || ShareIntakeItemKind.url => item.value.trim(),
  };

  if (candidate != null && candidate.isNotEmpty) {
    return candidate;
  }

  return item.value.trim();
}

String? _itemSubtitle(ShareIntakeItem item) {
  final details = <String>[];
  final rawValue = item.value.trim();
  final fileName = item.fileName?.trim();
  final message = item.message?.trim();
  final mimeType = item.mimeType?.trim();

  if (fileName != null && fileName.isNotEmpty && fileName != rawValue) {
    details.add(rawValue);
  }
  if (message != null && message.isNotEmpty) {
    details.add(message);
  }
  if (mimeType != null && mimeType.isNotEmpty) {
    details.add(mimeType);
  }

  if (details.isEmpty) {
    return null;
  }

  return details.join(' | ');
}

class _PendingShareAssignmentScreenState
    extends State<PendingShareAssignmentScreen> {
  late final PendingShareAssignmentService _service;
  PendingShareAssignmentSelectionData? _data;
  bool _hasLoaded = false;
  bool _isLoading = true;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PendingShareAssignmentService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoaded) {
      return;
    }

    _hasLoaded = true;
    _load();
  }

  Future<void> _load() async {
    final loc = AppLocalizations.of(context)!;
    final data = await _service.loadSelectionData(
      batchId: widget.batchId,
      itemIndex: widget.itemIndex,
      loc: loc,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  Future<void> _assign(
    ShareIntakeItem item,
    PendingShareAssignmentTarget target,
  ) async {
    final loc = AppLocalizations.of(context)!;
    if (!_service.canAssignItem(
      batchId: widget.batchId,
      itemIndex: widget.itemIndex,
      item: item,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.shareAssignUnsupported)),
      );
      return;
    }

    if (item.kind == ShareIntakeItemKind.url) {
      await _assignUrlItem(item, target, loc);
      return;
    }

    String? title;
    if (item.isFileBased) {
      title = await showDocumentTitlePromptDialog(
        context: context,
        initialTitle: _initialDocumentTitle(item),
      );
      if (title == null || !mounted) {
        return;
      }
    }

    setState(() => _isMutating = true);

    try {
      final outcome = await _service.assignPendingItem(
        batchId: widget.batchId,
        itemIndex: widget.itemIndex,
        target: target,
        title: title,
      );
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<String>(_messageForOutcome(loc, outcome));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.documentImportFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _assignUrlItem(
    ShareIntakeItem item,
    PendingShareAssignmentTarget target,
    AppLocalizations loc,
  ) async {
    final action = await _showUrlAssignmentOptions(loc);
    if (action == null || !mounted) {
      return;
    }

    if (action == _PendingShareUrlAssignmentAction.linkOnly) {
      setState(() => _isMutating = true);
      try {
        final result = await _service.assignPendingUrlAsLinkDocument(
          batchId: widget.batchId,
          itemIndex: widget.itemIndex,
          target: target,
        );
        if (!mounted) {
          return;
        }

        Navigator.of(context).pop<String>(
          _messageForUrlOutcome(loc, result.outcome),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.documentImportFailed)),
        );
      } finally {
        if (mounted) {
          setState(() => _isMutating = false);
        }
      }
      return;
    }

    final captureResult = await Navigator.of(context).push<UrlDocumentSaveResult>(
      MaterialPageRoute(
        builder: (_) => UrlSnapshotCaptureScreen(
          target: UrlDocumentTarget(
            type: _mapUrlTargetType(target.type),
            id: target.id,
          ),
          initialUrl: item.value,
        ),
      ),
    );
    if (captureResult == null || !mounted) {
      return;
    }

    setState(() => _isMutating = true);
    try {
      await _service.assignPendingUrlAsLinkDocument(
        batchId: widget.batchId,
        itemIndex: widget.itemIndex,
        target: target,
        removePendingItem: false,
      );
      await _service.completePendingUrlAssignment(
        batchId: widget.batchId,
        itemIndex: widget.itemIndex,
      );
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<String>(loc.shareAssignUrlAndPdfSaved);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.documentImportFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.shareAssignTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, loc),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations loc) {
    final data = _data;
    final item = data?.item;
    if (data == null || item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            loc.shareAssignItemUnavailable,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_service.canAssignItem(
      batchId: widget.batchId,
      itemIndex: widget.itemIndex,
      item: item,
    )) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            loc.shareAssignUnsupported,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itemTitle(item),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  loc.shareAssignSelectTarget,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_itemSubtitle(item) case final subtitle?) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!data.hasTargets)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(loc.shareAssignNoTargets),
          )
        else
          for (final group in data.cruiseGroups) ...[
            _CruiseTargetGroup(
              group: group,
              isMutating: _isMutating,
              onSelect: (target) => _assign(item, target),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  String _messageForOutcome(
    AppLocalizations loc,
    PendingShareAssignmentOutcome outcome,
  ) {
    switch (outcome) {
      case PendingShareAssignmentOutcome.importedAndLinked:
        return loc.documentImported;
      case PendingShareAssignmentOutcome.existingLinked:
        return loc.documentLinkedExisting;
      case PendingShareAssignmentOutcome.alreadyLinked:
        return loc.documentAlreadyLinked;
    }
  }

  String _messageForUrlOutcome(
    AppLocalizations loc,
    UrlDocumentSaveOutcome outcome,
  ) {
    switch (outcome) {
      case UrlDocumentSaveOutcome.importedAndLinked:
        return loc.documentImported;
      case UrlDocumentSaveOutcome.existingLinked:
        return loc.documentLinkedExisting;
      case UrlDocumentSaveOutcome.alreadyLinked:
        return loc.documentAlreadyLinked;
    }
  }

  UrlDocumentTargetType _mapUrlTargetType(
    PendingShareAssignmentTargetType type,
  ) {
    switch (type) {
      case PendingShareAssignmentTargetType.cruise:
        return UrlDocumentTargetType.cruise;
      case PendingShareAssignmentTargetType.excursion:
        return UrlDocumentTargetType.excursion;
      case PendingShareAssignmentTargetType.travelItem:
        return UrlDocumentTargetType.travelItem;
      case PendingShareAssignmentTargetType.portCall:
        return UrlDocumentTargetType.portCall;
      case PendingShareAssignmentTargetType.seaDay:
        return UrlDocumentTargetType.seaDay;
    }
  }

  String _initialDocumentTitle(ShareIntakeItem item) {
    switch (item.kind) {
      case ShareIntakeItemKind.file:
      case ShareIntakeItemKind.image:
        return suggestedDocumentTitleFromFileName(item.fileName?.trim() ?? '');
      case ShareIntakeItemKind.url:
        return suggestedDocumentTitleFromUrl(item.value);
      case ShareIntakeItemKind.text:
        return item.value.trim();
    }
  }

  Future<_PendingShareUrlAssignmentAction?> _showUrlAssignmentOptions(
    AppLocalizations loc,
  ) {
    return showModalBottomSheet<_PendingShareUrlAssignmentAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.shareAssignUrlOptionsTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                loc.shareAssignUrlOptionsHint,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_outlined),
                title: Text(loc.shareAssignAddLinkOnly),
                onTap: () => Navigator.of(ctx).pop(
                  _PendingShareUrlAssignmentAction.linkOnly,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(loc.shareAssignAddLinkAndSavePdf),
                subtitle: Text(loc.shareAssignUrlOpenBeforeSaveHint),
                onTap: () => Navigator.of(ctx).pop(
                  _PendingShareUrlAssignmentAction.linkAndSavePdf,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PendingShareUrlAssignmentAction {
  linkOnly,
  linkAndSavePdf,
}

class _CruiseTargetGroup extends StatelessWidget {
  const _CruiseTargetGroup({
    required this.group,
    required this.isMutating,
    required this.onSelect,
  });

  final PendingShareAssignmentCruiseGroup group;
  final bool isMutating;
  final ValueChanged<PendingShareAssignmentTarget> onSelect;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.cruiseTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _TargetTile(
              target: group.cruiseTarget,
              icon: Icons.directions_boat_outlined,
              enabled: !isMutating,
              onTap: onSelect,
            ),
            if (group.excursions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                loc.excursions,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final target in group.excursions)
                _TargetTile(
                  target: target,
                  icon: Icons.directions_walk_outlined,
                  enabled: !isMutating,
                  onTap: onSelect,
                ),
            ],
            if (group.travelItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                loc.travel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final target in group.travelItems)
                _TargetTile(
                  target: target,
                  icon: Icons.card_travel,
                  enabled: !isMutating,
                  onTap: onSelect,
                ),
            ],
            if (group.portCalls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                loc.harbour,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final target in group.portCalls)
                _TargetTile(
                  target: target,
                  icon: Icons.place_outlined,
                  enabled: !isMutating,
                  onTap: onSelect,
                ),
            ],
            if (group.seaDays.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                loc.seaDay,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final target in group.seaDays)
                _TargetTile(
                  target: target,
                  icon: Icons.waves_outlined,
                  enabled: !isMutating,
                  onTap: onSelect,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.target,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final PendingShareAssignmentTarget target;
  final IconData icon;
  final bool enabled;
  final ValueChanged<PendingShareAssignmentTarget> onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      leading: Icon(icon),
      title: Text(target.title),
      subtitle: target.subtitle == null ? null : Text(target.subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: enabled ? () => onTap(target) : null,
    );
  }
}
