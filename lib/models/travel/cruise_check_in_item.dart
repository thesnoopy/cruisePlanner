
import 'base_travel.dart';

class CruiseCheckIn extends TravelItem {
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

  CruiseCheckIn({
    required this.id,
    required this.start,
    this.end,
    this.from,
    this.to,
    this.notes,
    this.price,
    this.currency,
    this.recordLocator,
  });

  @override
  TravelKind get kind => TravelKind.cruiseCheckIn;

  CruiseCheckIn copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency,
    String? recordLocator,
  }) =>
      CruiseCheckIn(
        id: id ?? this.id,
        start: start ?? this.start,
        end: end ?? this.end,
        from: from ?? this.from,
        to: to ?? this.to,
        notes: notes ?? this.notes,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        recordLocator: recordLocator ?? this.recordLocator,
      );

  @override
  Map<String, dynamic> toMap() => {
        'type': 'cruisecheckin',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'from': from,
        'to': to,
        'notes': notes,
        'price': price,
        'currency': currency,
        'recordLocator': recordLocator,
      };

  factory CruiseCheckIn.fromMap(Map<String, dynamic> map) => CruiseCheckIn(
        id: map['id'],
        start: DateTime.parse(map['start']),
        end: map['end'] != null ? DateTime.parse(map['end']) : null,
        from: map['from'],
        to: map['to'],
        notes: map['notes'],
        price: map['price'],
        currency: map['currency'],
        recordLocator: map['recordLocator'],
      );

  @override
  List<Object?> get props => [id, kind, start, end, from, to, notes, price, currency];
}
