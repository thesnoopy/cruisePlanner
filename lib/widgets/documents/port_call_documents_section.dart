import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/documents/document_kind.dart';
import '../../models/documents/document_record.dart';
import '../../services/documents/document_open_service.dart';
import '../../services/documents/port_call_document_section_service.dart';
import 'document_title_prompt_dialog.dart';

class PortCallDocumentsSection extends StatefulWidget {
  const PortCallDocumentsSection({
    super.key,
    required this.portCallId,
    this.isReadOnly = false,
    this.service,
  });

  final String portCallId;
  final bool isReadOnly;
  final PortCallDocumentSectionService? service;

  @override
  State<PortCallDocumentsSection> createState() =>
      _PortCallDocumentsSectionState();
}

class _PortCallDocumentsSectionState extends State<PortCallDocumentsSection> {
  late final PortCallDocumentSectionService _service;
  late final DocumentOpenService _openService;
  PortCallDocumentSectionData? _data;
  bool _isLoading = true;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PortCallDocumentSectionService();
    _openService = DocumentOpenService();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final data = await _service.loadForPortCall(widget.portCallId);
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
      portCallId: widget.portCallId,
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
      portCallId: widget.portCallId,
      documentId: document.id,
    );
    await _reload();
    if (!mounted) {
      return;
    }
    setState(() => _isMutating = false);
  }

  Future<void> _openDocument(DocumentRecord document) async {
    final loc = AppLocalizations.of(context)!;

    try {
      await _openService.openDocument(document);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.documentOpenFailed)),
      );
    }
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
                          _subtitleForDocument(
                            bottomSheetLoc,
                            availableDocument,
                          ),
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

  Future<void> _importDocument() async {
    final loc = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final selectedFile = result.files.single;
    final sourcePath = selectedFile.path?.trim() ?? '';
    if (sourcePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.documentImportFailed)),
      );
      return;
    }

    final title = await showDocumentTitlePromptDialog(
      context: context,
      initialTitle: suggestedDocumentTitleFromFileName(selectedFile.name),
    );
    if (title == null || !mounted) {
      return;
    }

    setState(() => _isMutating = true);

    try {
      final importResult = await _service.importDocument(
        portCallId: widget.portCallId,
        sourcePath: sourcePath,
        title: title,
      );
      await _reload();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            importResult.attached
                ? loc.documentImported
                : loc.documentImportFailed,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.documentImportFailed)),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() => _isMutating = false);
    }
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
                if (!widget.isReadOnly)
                  Flexible(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed:
                              (_isLoading || _isMutating) ? null : _importDocument,
                          icon: const Icon(Icons.file_upload_outlined),
                          label: Text(loc.importDocument),
                        ),
                        TextButton.icon(
                          onPressed:
                              (_isLoading || _isMutating) ? null : _showAttachSheet,
                          icon: const Icon(Icons.attach_file),
                          label: Text(loc.attachExistingDocument),
                        ),
                      ],
                    ),
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
                child: Text(loc.noLinkedDocuments),
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
                      onTap: () => _openDocument(document),
                      trailing: widget.isReadOnly
                          ? null
                          : IconButton(
                              tooltip: loc.detachDocument,
                              onPressed: _isMutating
                                  ? null
                                  : () => _detachDocument(document),
                              icon: const Icon(Icons.link_off_outlined),
                            ),
                    ),
                ],
              ),
            if (!widget.isReadOnly &&
                !_isLoading &&
                data != null &&
                !data.hasAvailableDocuments) ...[
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
