import 'route_item.dart';
import '../documents/document_ids.dart';

class PortCallItem extends RouteItem {
  static const Object _unset = Object();

  @override
  final String id;
  @override
  final DateTime date;
  @override
  final String type = 'port';
  @override
  final DateTime? updatedAtUtc;
  @override
  final DateTime? deletedAtUtc;

  final String portName;
  final DateTime? arrival;
  final DateTime? departure;
  /// Neue Zusatzzeit: Alle Mann an Bord
  final DateTime? allAboard;
  final String? notes;
  final List<String> documentIds;

  PortCallItem({
    required this.id,
    required this.date,
    required this.portName,
    this.arrival,
    this.departure,
    this.allAboard,
    this.notes,
    List<String> documentIds = const [],
    this.updatedAtUtc,
    this.deletedAtUtc,
  }) : documentIds = DocumentIds.fromJsonValue(documentIds);

  PortCallItem copyWith({
    String? id,
    DateTime? date,
    String? portName,
    DateTime? arrival,
    DateTime? departure,
    DateTime? allAboard,
    String? notes,
    List<String>? documentIds,
    Object? updatedAtUtc = _unset,
    Object? deletedAtUtc = _unset,
  }) =>
      PortCallItem(
        id: id ?? this.id,
        date: date ?? this.date,
        portName: portName ?? this.portName,
        arrival: arrival ?? this.arrival,
        departure: departure ?? this.departure,
        allAboard: allAboard ?? this.allAboard,
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
        'portName': portName,
        'arrival': arrival?.toIso8601String(),
        'departure': departure?.toIso8601String(),
        'allAboard': allAboard?.toIso8601String(),
        'notes': notes,
        'documentIds': documentIds,
        'updatedAtUtc': RouteItem.writeSyncTimestamp(updatedAtUtc),
        'deletedAtUtc': RouteItem.writeSyncTimestamp(deletedAtUtc),
      };

  factory PortCallItem.fromMap(Map<String, dynamic> map) => PortCallItem(
        id: map['id'],
        date: DateTime.parse(map['date']),
        portName: map['portName'],
        arrival: map['arrival'] != null ? DateTime.parse(map['arrival']) : null,
        departure: map['departure'] != null ? DateTime.parse(map['departure']) : null,
        allAboard: map['allAboard'] != null ? DateTime.parse(map['allAboard']) : null,
        notes: map['notes'],
        documentIds: DocumentIds.fromJsonValue(map['documentIds']),
        updatedAtUtc: RouteItem.readSyncTimestamp(map, 'updatedAtUtc'),
        deletedAtUtc: RouteItem.readSyncTimestamp(map, 'deletedAtUtc'),
      );

  @override
  List<Object?> get props => [id, type, date, portName, arrival, departure, allAboard, notes, documentIds, updatedAtUtc, deletedAtUtc];
}
