import 'package:flutter/services.dart';

import '../../models/share/share_intake_payload.dart';

class ShareIntakeNativeBridge {
  const ShareIntakeNativeBridge();

  static const MethodChannel _methodChannel = MethodChannel(
    'de.mailsmart.cruiseplanner/share_intake',
  );
  static const EventChannel _eventChannel = EventChannel(
    'de.mailsmart.cruiseplanner/share_intake/events',
  );

  Future<List<ShareIntakeItem>> getInitialSharedItems() async {
    final rawItems = await _methodChannel.invokeMethod<List<dynamic>>(
      'getInitialSharedItems',
    );
    return _parseItems(rawItems);
  }

  Stream<List<ShareIntakeItem>> get sharedItemsStream {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is List) {
        return _parseItems(event);
      }
      return const <ShareIntakeItem>[];
    });
  }

  List<ShareIntakeItem> _parseItems(List<dynamic>? rawItems) {
    if (rawItems == null || rawItems.isEmpty) {
      return const <ShareIntakeItem>[];
    }

    return rawItems
        .whereType<Map<Object?, Object?>>()
        .map(
          (item) => ShareIntakeItem.fromJson(
            item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .whereType<ShareIntakeItem>()
        .toList(growable: false);
  }
}
