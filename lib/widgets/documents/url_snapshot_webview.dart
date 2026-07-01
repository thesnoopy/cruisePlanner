import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/documents/url_snapshot_webview_controller.dart';

class UrlSnapshotWebView extends StatelessWidget {
  const UrlSnapshotWebView({
    super.key,
    required this.controller,
  });

  final UrlSnapshotWebViewController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.isSupported || kIsWeb) {
      return const SizedBox.shrink();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: UrlSnapshotWebViewController.viewType,
          layoutDirection: TextDirection.ltr,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: controller.attachToPlatformView,
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: UrlSnapshotWebViewController.viewType,
          layoutDirection: TextDirection.ltr,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: controller.attachToPlatformView,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return const SizedBox.shrink();
    }
  }
}
