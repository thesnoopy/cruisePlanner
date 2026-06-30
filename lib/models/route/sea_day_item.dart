
import '../documents/document_ids.dart';
import 'route_item.dart';

class SeaDayItem extends RouteItem {
  static const Object _unset = Object();

  @override
  final String id;
  @override
  final DateTime date;
  @override
  final String type = 'sea';
  @override
  final DateTime? updatedAtUtc;
  @override
  final DateTime? deletedAtUtc;

  final String? notes;
  final List<String> documentIds;

  SeaDayItem({
    required this.id,
    required this.date,
    this.notes,
    List<String> documentIds = const [],
    this.updatedAtUtc,
    this.deletedAtUtc,
  }) : documentIds = DocumentIds.fromJsonValue(documentIds);

  SeaDayItem copyWith({
    String? id,
    DateTime? date,
    String? notes,
    List<String>? documentIds,
    Object? updatedAtUtc = _unset,
    Object? deletedAtUtc = _unset,
  }) => SeaDayItem(
        id: id ?? this.id,
        date: date ?? this.date,
        notes: notes ?? this.notes,
        documentIds: documentIds ?? this.documentIds,
        updatedAtUtc: identical(updatedAtUtc, _unset)
            ? this.updatedAtUtc
            : updatedAtUtc as DateTime?,
        deletedAtUtc: identical(deletedAtUtc, _unset)
            ? this.deletedAtUtc
            : deletedAtUtc as DateTime?,
      );

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'id': id,
        'date': date.toIso8601String(),
        'notes': notes,
        'documentIds': documentIds,
        'updatedAtUtc': RouteItem.writeSyncTimestamp(updatedAtUtc),
        'deletedAtUtc': RouteItem.writeSyncTimestamp(deletedAtUtc),
      };

  factory SeaDayItem.fromMap(Map<String, dynamic> map) =>
      SeaDayItem(
        id: map['id'],
        date: DateTime.parse(map['date']),
        notes: map['notes'],
        documentIds: DocumentIds.fromJsonValue(map['documentIds']),
        updatedAtUtc: RouteItem.readSyncTimestamp(map, 'updatedAtUtc'),
        deletedAtUtc: RouteItem.readSyncTimestamp(map, 'deletedAtUtc'),
      );

  @override
  List<Object?> get props => [
        id,
        type,
        date,
        notes,
        documentIds,
        updatedAtUtc,
        deletedAtUtc,
      ];
}
