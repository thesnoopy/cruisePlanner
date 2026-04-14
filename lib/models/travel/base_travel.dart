
import '../identifiable.dart';
import '../documents/document_ids.dart';
import '../sync_metadata.dart';

enum TravelKind { flight, train, transfer, rentalCar, hotel, cruiseCheckIn, cruiseCheckOut }

abstract class TravelItem extends Identifiable {
  @override
  String get id;
  TravelKind get kind;
  DateTime get start;
  DateTime? get end;
  String? get from;
  String? get to;
  String? get notes;
  num? get price;
  String? get currency;
  String? get recordLocator;
  List<String> get documentIds;
  DateTime? get updatedAtUtc;
  DateTime? get deletedAtUtc;

  Map<String, dynamic> toMap();

  static List<String> readDocumentIds(Object? value) {
    return DocumentIds.fromJsonValue(value);
  }

  static DateTime? readSyncTimestamp(Map<String, dynamic> map, String key) {
    return readNullableUtcDateTime(map, key);
  }

  static String? writeSyncTimestamp(DateTime? value) {
    return writeNullableUtcDateTime(value);
  }
}
