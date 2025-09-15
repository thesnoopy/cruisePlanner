// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

/// Abstrakter Routen-Eintrag. Discriminator: [type] = 'sea' | 'port'
abstract class RouteItem extends Equatable {
  final String id;         // UUID
  final DateTime date;     // Kalendertag (lokal, Tagesanker)
  final String type;       // 'sea' | 'port'

  const RouteItem({
    required this.id,
    required this.date,
    required this.type,
  });

  /// Fabrik zum polymorphen Deserialisieren
  factory RouteItem.fromMap(Map<String, dynamic> map) {
    final type = map['type'];
    if (type == 'sea') return SeaDayItem.fromMap(map);
    if (type == 'port') return PortCallItem.fromMap(map);
    throw ArgumentError('Unknown RouteItem type: $type');
  }

  Map<String, dynamic> toMap();

  bool get isSea => type == 'sea';
  bool get isPort => type == 'port';
}

/// Seetag: ganztägig, keine weiteren Details
class SeaDayItem extends RouteItem {
  const SeaDayItem({
    required super.id,
    required super.date,
  }) : super(type: 'sea');

  SeaDayItem copyWith({
    String? id,
    DateTime? date,
  }) =>
      SeaDayItem(
        id: id ?? this.id,
        date: date ?? this.date,
      );

  factory SeaDayItem.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    final id = (rawId is String) ? rawId : (rawId == null ? '' : rawId.toString());

    final rawDate = map['date'];
    final date = (rawDate is String) ? DateTime.parse(rawDate) : DateTime.now();

    return SeaDayItem(id: id, date: date);
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'date': date.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, date, type];
}

/// Hafen-Aufenthalt mit Zeiten und optionalen Details
class PortCallItem extends RouteItem {
  final String portName;        // z.B. "Port of Halifax"
  final String? city;           // "Halifax"
  final String? country;        // "Canada"
  final DateTime arrival;       // lokal
  final DateTime departure;     // lokal
  final String? description;    // optional
  final String? terminal;       // optional
  final String? notes;          // optional

  const PortCallItem({
    required super.id,
    required super.date,
    required this.portName,
    this.city,
    this.country,
    required this.arrival,
    required this.departure,
    this.description,
    this.terminal,
    this.notes,
  }) : super(type: 'port');

  PortCallItem copyWith({
    String? id,
    DateTime? date,
    String? portName,
    String? city,
    String? country,
    DateTime? arrival,
    DateTime? departure,
    String? description,
    String? terminal,
    String? notes,
  }) =>
      PortCallItem(
        id: id ?? this.id,
        date: date ?? this.date,
        portName: portName ?? this.portName,
        city: city ?? this.city,
        country: country ?? this.country,
        arrival: arrival ?? this.arrival,
        departure: departure ?? this.departure,
        description: description ?? this.description,
        terminal: terminal ?? this.terminal,
        notes: notes ?? this.notes,
      );

  factory PortCallItem.fromMap(Map<String, dynamic> map) {
    String readStr(dynamic v) => (v is String) ? v : (v == null ? '' : v.toString());

    final rawId = map['id'];
    final id = (rawId is String) ? rawId : (rawId == null ? '' : rawId.toString());

    final rawDate = map['date'];
    final date = (rawDate is String) ? DateTime.parse(rawDate) : DateTime.now();

    final portName = readStr(map['portName']);
    final city = (map['city'] == null) ? null : readStr(map['city']);
    final country = (map['country'] == null) ? null : readStr(map['country']);

    final rawArrival = map['arrival'];
    final arrival = (rawArrival is String) ? DateTime.parse(rawArrival) : date;

    final rawDeparture = map['departure'];
    final departure = (rawDeparture is String) ? DateTime.parse(rawDeparture) : date;

    final description = (map['description'] == null) ? null : readStr(map['description']);
    final terminal = (map['terminal'] == null) ? null : readStr(map['terminal']);
    final notes = (map['notes'] == null) ? null : readStr(map['notes']);

    return PortCallItem(
      id: id,
      date: date,
      portName: portName,
      city: city?.isEmpty == true ? null : city,
      country: country?.isEmpty == true ? null : country,
      arrival: arrival,
      departure: departure,
      description: description?.isEmpty == true ? null : description,
      terminal: terminal?.isEmpty == true ? null : terminal,
      notes: notes?.isEmpty == true ? null : notes,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'date': date.toIso8601String(),
        'portName': portName,
        'city': city,
        'country': country,
        'arrival': arrival.toIso8601String(),
        'departure': departure.toIso8601String(),
        'description': description,
        'terminal': terminal,
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id,
        date,
        type,
        portName,
        city,
        country,
        arrival,
        departure,
        description,
        terminal,
        notes,
      ];
}
