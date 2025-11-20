
import 'base_travel.dart';

class HotelItem extends TravelItem {
  @override
  final String id;
  @override
  final DateTime start;
  @override
  final DateTime? end;
  @override
  final String? from;
  @override
  final String? to;
  @override
  final String? notes;
  @override
  final num? price;
  @override
  final String? currency;
  @override
  final String? recordLocator;

  final String? company;
  final String name;
  final String? location;

  HotelItem({
    required this.id,
    required this.start,
    this.end,
    this.from,
    this.to,
    this.notes,
    this.price,
    this.currency,
    this.company,
    required this.name,
    this.location,
    this.recordLocator,
  });

  @override
  TravelKind get kind => TravelKind.hotel;

  HotelItem copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency,
    String? company,
    String? name,
    String? location,
    String? recordLocator,
  }) =>
      HotelItem(
        id: id ?? this.id,
        start: start ?? this.start,
        end: end ?? this.end,
        from: from ?? this.from,
        to: to ?? this.to,
        notes: notes ?? this.notes,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        company: company ?? this.company,
        name: name ?? this.name,
        location: location ?? this.location,
        recordLocator: recordLocator ?? this.location,
      );

  @override
  Map<String, dynamic> toMap() => {
        'type': 'hotel',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'from': from,
        'to': to,
        'notes': notes,
        'price': price,
        'currency': currency,
        'company': company,
        'name': name,
        'location': location,
        'recordLocator': recordLocator,
      };

  factory HotelItem.fromMap(Map<String, dynamic> map) => HotelItem(
        id: map['id'],
        start: DateTime.parse(map['start']),
        end: map['end'] != null ? DateTime.parse(map['end']) : null,
        from: map['from'],
        to: map['to'],
        notes: map['notes'],
        price: map['price'],
        currency: map['currency'],
        company: map['company'],
        name: map['name'],
        location: map['location'],
        recordLocator: map['recordLocator'],
      );

  @override
  List<Object?> get props => [id, kind, start, end, from, to, notes, price, currency, company, name, location];
}
