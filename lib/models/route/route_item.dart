
import '../identifiable.dart';
import '../sync_metadata.dart';

abstract class RouteItem extends Identifiable {
  @override
  String get id;
  DateTime get date;
  String get type; // 'sea' | 'port'
  DateTime? get updatedAtUtc;
  DateTime? get deletedAtUtc;
  Map<String, dynamic> toMap();

  static DateTime? readSyncTimestamp(Map<String, dynamic> map, String key) {
    return readNullableUtcDateTime(map, key);
  }

  static String? writeSyncTimestamp(DateTime? value) {
    return writeNullableUtcDateTime(value);
  }
}
