import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/documents/document_kind.dart';
import '../../models/documents/document_record.dart';
import '../../services/documents/cruise_document_section_service.dart';

class CruiseDocumentsSection extends StatefulWidget {
  const CruiseDocumentsSection({
    super.key,
    required this.cruiseId,
    this.service,
  });

  final String cruiseId;
  final CruiseDocumentSectionService? service;

  @override
  State<CruiseDocumentsSection> createState() => _CruiseDocumentsSectionState();
}

class _CruiseDocumentsSectionState extends State<CruiseDocumentsSection> {
  late final CruiseDocumentSectionService _service;
  CruiseDocumentSectionData? _data;
  bool _isLoading = true;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CruiseDocumentSectionService();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final data = await _service.loadForCruise(widget.cruiseId);
    if (!mounted) {
      return;
    }
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  Future<void> _attachDocument(DocumentRecord document) async {
    setState(() => _isMutating = true);
    await _service.attachExistingDocument(
      cruiseId: widget.cruiseId,
      documentId: document.id,
    );
    await _reload();
    if (!mounted) {
      return;
    }
    setState(() => _isMutating = false);
  }

  Future<void> _detachDocument(DocumentRecord document) async {
    setState(() => _isMutating = true);
    await _service.detachLinkedDocument(
      cruiseId: widget.cruiseId,
      documentId: document.id,
    );
    await _reload();
    if (!mounted) {
      return;
    }
    setState(() => _isMutating = false);
  }

  Future<void> _showAttachSheet() async {
    final loc = AppLocalizations.of(context)!;
    final data = _data;
    if (data == null) {
      return;
    }

    final document = await showModalBottomSheet<DocumentRecord>(
      context: context,
      builder: (ctx) {
        final bottomSheetLoc = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: data.availableDocuments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Text(bottomSheetLoc.noAvailableDocumentsToAttach),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Text(
                        bottomSheetLoc.attachExistingDocument,
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                    ),
                    for (final availableDocument in data.availableDocuments)
                      ListTile(
                        leading: Icon(_iconForKind(availableDocument.kind)),
                        title: Text(
                          availableDocument.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _subtitleForDocument(bottomSheetLoc, availableDocument),
                        ),
                        onTap: () => Navigator.of(ctx).pop(availableDocument),
                      ),
                  ],
                ),
        );
      },
    );

    if (document == null || !mounted) {
      return;
    }

    await _attachDocument(document);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.documentAttached)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final data = _data;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.documents,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: (_isLoading || _isMutating) ? null : _showAttachSheet,
                  icon: const Icon(Icons.attach_file),
                  label: Text(loc.attachExistingDocument),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (data == null || data.linkedDocuments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(loc.noLinkedDocumentsForCruise),
              )
            else
              Column(
                children: [
                  for (final document in data.linkedDocuments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_iconForKind(document.kind)),
                      title: Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_subtitleForDocument(loc, document)),
                      trailing: IconButton(
                        tooltip: loc.detachDocument,
                        onPressed: _isMutating ? null : () => _detachDocument(document),
                        icon: const Icon(Icons.link_off_outlined),
                      ),
                    ),
                ],
              ),
            if (!_isLoading && data != null && !data.hasAvailableDocuments) ...[
              const SizedBox(height: 8),
              Text(
                loc.noAvailableDocumentsToAttach,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitleForDocument(AppLocalizations loc, DocumentRecord document) {
    final extension = document.fileExtension.trim().isEmpty
        ? ''
        : '.${document.fileExtension.toLowerCase()}';
    final parts = <String>[
      _labelForKind(loc, document.kind),
      if (extension.isNotEmpty) extension,
    ];
    return parts.join(' - ');
  }

  String _labelForKind(AppLocalizations loc, DocumentKind kind) {
    switch (kind) {
      case DocumentKind.pdf:
        return loc.documentKindPdf;
      case DocumentKind.email:
        return loc.documentKindEmail;
      case DocumentKind.image:
        return loc.documentKindImage;
      case DocumentKind.unknown:
        return loc.documentKindUnknown;
    }
  }

  IconData _iconForKind(DocumentKind kind) {
    switch (kind) {
      case DocumentKind.pdf:
        return Icons.picture_as_pdf_outlined;
      case DocumentKind.email:
        return Icons.email_outlined;
      case DocumentKind.image:
        return Icons.image_outlined;
      case DocumentKind.unknown:
        return Icons.insert_drive_file_outlined;
    }
  }
}
