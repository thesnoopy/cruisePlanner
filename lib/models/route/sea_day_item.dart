
import 'route_item.dart';

class SeaDayItem extends RouteItem {
  @override
  final String id;
  @override
  final DateTime date;
  @override
  final String type = 'sea';

  final String? notes;

  SeaDayItem({required this.id, required this.date, this.notes});

  SeaDayItem copyWith({String? id, DateTime? date, String? notes}) =>
      SeaDayItem(id: id ?? this.id, date: date ?? this.date, notes: notes ?? this.notes);

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'id': id,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory SeaDayItem.fromMap(Map<String, dynamic> map) =>
      SeaDayItem(id: map['id'], date: DateTime.parse(map['date']), notes: map['notes']);

  @override
  List<Object?> get props => [id, type, date, notes];
}
