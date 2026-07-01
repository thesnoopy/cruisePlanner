import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/documents/url_document_target.dart';
import '../../services/documents/url_document_service.dart';
import '../../services/documents/url_snapshot_webview_controller.dart';
import '../../widgets/documents/url_snapshot_webview.dart';

class UrlSnapshotCaptureScreen extends StatefulWidget {
  const UrlSnapshotCaptureScreen({
    super.key,
    required this.target,
    this.initialUrl,
    this.documentService,
    this.webViewController,
  });

  final UrlDocumentTarget target;
  final String? initialUrl;
  final UrlDocumentService? documentService;
  final UrlSnapshotWebViewController? webViewController;

  @override
  State<UrlSnapshotCaptureScreen> createState() =>
      _UrlSnapshotCaptureScreenState();
}

class _UrlSnapshotCaptureScreenState extends State<UrlSnapshotCaptureScreen> {
  late final UrlDocumentService _documentService;
  late final UrlSnapshotWebViewController _webViewController;
  late final TextEditingController _urlController;
  bool _isSaving = false;

  UrlSnapshotWebViewController get _controller => _webViewController;

  @override
  void initState() {
    super.initState();
    _documentService = widget.documentService ?? UrlDocumentService();
    _webViewController =
        widget.webViewController ?? UrlSnapshotWebViewController();
    _urlController = TextEditingController(text: widget.initialUrl?.trim() ?? '');
    _controller.addListener(_handleControllerChanged);

    final initialUrl = _urlController.text.trim();
    if (initialUrl.isNotEmpty && _controller.isSupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _loadUrl();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (widget.webViewController == null) {
      _controller.dispose();
    }
    _urlController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _loadUrl() async {
    final loc = AppLocalizations.of(context)!;
    if (!_controller.isSupported) {
      _showSnackBar(loc.urlSnapshotUnsupportedPlatform);
      return;
    }

    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      _showSnackBar(loc.urlSnapshotMissingUrl);
      return;
    }

    try {
      final normalizedUrl = _documentService.normalizeSourceUrl(rawUrl);
      _urlController.text = normalizedUrl;
      await _controller.loadUrl(normalizedUrl);
    } on ArgumentError {
      _showSnackBar(loc.urlSnapshotMissingUrl);
    } on PlatformException catch (error) {
      _showSnackBar(_loadErrorMessage(loc, error.message));
    } catch (_) {
      _showSnackBar(loc.urlSnapshotLoadFailed);
    }
  }

  Future<void> _saveSnapshot() async {
    final loc = AppLocalizations.of(context)!;
    if (!_controller.isSupported) {
      _showSnackBar(loc.urlSnapshotUnsupportedPlatform);
      return;
    }

    final state = _controller.state;
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      _showSnackBar(loc.urlSnapshotMissingUrl);
      return;
    }
    if (!state.canCapture || state.isLoading) {
      _showSnackBar(loc.urlSnapshotPageNotLoaded);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final normalizedUrl = _documentService.normalizeSourceUrl(rawUrl);
      final capture = await _controller.capturePdf(sourceUrl: normalizedUrl);
      final result = await _documentService.saveSnapshot(
        target: widget.target,
        snapshot: capture,
      );
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(result);
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_saveErrorMessage(loc, error.message));
    } on ArgumentError {
      if (!mounted) {
        return;
      }
      _showSnackBar(loc.urlSnapshotMissingUrl);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar(loc.urlSnapshotSaveFailed);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = _controller.state;
    final isBusy = _isSaving || state.isLoading;
    final canSaveSnapshot =
        !_isSaving &&
        state.isSupported &&
        state.hasLoadedPage &&
        state.canCapture &&
        !state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.urlSnapshotTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.urlSnapshotHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _loadUrl(),
              decoration: InputDecoration(
                labelText: loc.urlSnapshotUrlLabel,
                hintText: 'https://example.com',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isBusy ? null : _loadUrl,
                  icon: const Icon(Icons.open_in_browser_outlined),
                  label: Text(loc.urlSnapshotOpen),
                ),
                OutlinedButton.icon(
                  onPressed:
                      (isBusy || !state.hasLoadedPage) ? null : _controller.reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(loc.urlSnapshotReload),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.pageTitle?.trim().isNotEmpty == true)
              Text(
                state.pageTitle!.trim(),
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (state.currentUrl?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                state.currentUrl!.trim(),
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (state.errorMessage?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!.trim(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: state.isSupported
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            UrlSnapshotWebView(controller: _controller),
                            if (state.isLoading)
                              const ColoredBox(
                                color: Color(0x33000000),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              loc.urlSnapshotUnsupportedPlatform,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSaveSnapshot ? _saveSnapshot : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(loc.urlSnapshotSaveAsPdf),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _loadErrorMessage(AppLocalizations loc, String? platformMessage) {
    final message = platformMessage?.trim();
    if (message != null && message.isNotEmpty) {
      return '${loc.urlSnapshotLoadFailed} $message';
    }
    return loc.urlSnapshotLoadFailed;
  }

  String _saveErrorMessage(AppLocalizations loc, String? platformMessage) {
    final message = platformMessage?.trim();
    if (message != null && message.isNotEmpty) {
      return '${loc.urlSnapshotSaveFailed} $message';
    }
    return loc.urlSnapshotSaveFailed;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
