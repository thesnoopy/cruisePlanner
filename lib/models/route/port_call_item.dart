
import 'route_item.dart';

class PortCallItem extends RouteItem {
  @override
  final String id;
  @override
  final DateTime date;
  @override
  final String type = 'port';

  final String portName;
  final DateTime? arrival;
  final DateTime? departure;
  final String? notes;

  PortCallItem({
    required this.id,
    required this.date,
    required this.portName,
    this.arrival,
    this.departure,
    this.notes,
  });

  PortCallItem copyWith({
    String? id,
    DateTime? date,
    String? portName,
    DateTime? arrival,
    DateTime? departure,
    String? notes,
  }) =>
      PortCallItem(
        id: id ?? this.id,
        date: date ?? this.date,
        portName: portName ?? this.portName,
        arrival: arrival ?? this.arrival,
        departure: departure ?? this.departure,
        notes: notes ?? this.notes,
      );

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'id': id,
        'date': date.toIso8601String(),
        'portName': portName,
        'arrival': arrival?.toIso8601String(),
        'departure': departure?.toIso8601String(),
        'notes': notes,
      };

  factory PortCallItem.fromMap(Map<String, dynamic> map) => PortCallItem(
        id: map['id'],
        date: DateTime.parse(map['date']),
        portName: map['portName'],
        arrival: map['arrival'] != null ? DateTime.parse(map['arrival']) : null,
        departure: map['departure'] != null ? DateTime.parse(map['departure']) : null,
        notes: map['notes'],
      );

  @override
  List<Object?> get props => [id, type, date, portName, arrival, departure, notes];
}
