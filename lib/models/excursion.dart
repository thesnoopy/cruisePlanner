
import 'identifiable.dart';

class Excursion extends Identifiable {
  @override
  final String id;
  final String title;
  final DateTime date;
  final String? port;
  final String? meetingPoint;
  final String? notes;
  final num? price;
  final String? currency;

  Excursion({
    required this.id,
    required this.title,
    required this.date,
    this.port,
    this.meetingPoint,
    this.notes,
    this.price,
    this.currency,
  });

  Excursion copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? port,
    String? meetingPoint,
    String? notes,
    num? price,
    String? currency,
  }) =>
      Excursion(
        id: id ?? this.id,
        title: title ?? this.title,
        date: date ?? this.date,
        port: port ?? this.port,
        meetingPoint: meetingPoint ?? this.meetingPoint,
        notes: notes ?? this.notes,
        price: price ?? this.price,
        currency: currency ?? this.currency,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'port': port,
        'meetingPoint': meetingPoint,
        'notes': notes,
        'price': price,
        'currency': currency,
      };

  factory Excursion.fromMap(Map<String, dynamic> map) => Excursion(
        id: map['id'],
        title: map['title'],
        date: DateTime.parse(map['date']),
        port: map['port'],
        meetingPoint: map['meetingPoint'],
        notes: map['notes'],
        price: map['price'],
        currency: map['currency'],
      );

  @override
  List<Object?> get props => [id, title, date, port, meetingPoint, notes, price, currency];
}
