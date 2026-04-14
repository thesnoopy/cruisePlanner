
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

  SeaDayItem({
    required this.id,
    required this.date,
    this.notes,
    this.updatedAtUtc,
    this.deletedAtUtc,
  });

  SeaDayItem copyWith({
    String? id,
    DateTime? date,
    String? notes,
    Object? updatedAtUtc = _unset,
    Object? deletedAtUtc = _unset,
  }) => SeaDayItem(
        id: id ?? this.id,
        date: date ?? this.date,
        notes: notes ?? this.notes,
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
        'updatedAtUtc': RouteItem.writeSyncTimestamp(updatedAtUtc),
        'deletedAtUtc': RouteItem.writeSyncTimestamp(deletedAtUtc),
      };

  factory SeaDayItem.fromMap(Map<String, dynamic> map) =>
      SeaDayItem(
        id: map['id'],
        date: DateTime.parse(map['date']),
        notes: map['notes'],
        updatedAtUtc: RouteItem.readSyncTimestamp(map, 'updatedAtUtc'),
        deletedAtUtc: RouteItem.readSyncTimestamp(map, 'deletedAtUtc'),
      );

  @override
  List<Object?> get props => [id, type, date, notes, updatedAtUtc, deletedAtUtc];
}
