
import 'base_travel.dart';

class RentalCarItem extends TravelItem {
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
  @override
  final List<String> documentIds;

  final String? company;

  RentalCarItem({
    required this.id,
    required this.start,
    this.end,
    this.from,
    this.to,
    this.notes,
    this.price,
    this.currency,
    this.company,
    this.recordLocator,
    List<String> documentIds = const [],
  }) : documentIds = TravelItem.readDocumentIds(documentIds);

  @override
  TravelKind get kind => TravelKind.rentalCar;

  RentalCarItem copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency,
    String? company,
    String? recordLocator,
    List<String>? documentIds,
  }) =>
      RentalCarItem(
        id: id ?? this.id,
        start: start ?? this.start,
        end: end ?? this.end,
        from: from ?? this.from,
        to: to ?? this.to,
        notes: notes ?? this.notes,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        company: company ?? this.company,
        recordLocator: recordLocator ?? this.recordLocator,
        documentIds: documentIds ?? this.documentIds,
      );

  @override
  Map<String, dynamic> toMap() => {
        'type': 'rentalCar',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'from': from,
        'to': to,
        'notes': notes,
        'price': price,
        'currency': currency,
        'company': company,
        'recordLocator': recordLocator,
        'documentIds': documentIds,
      };

  factory RentalCarItem.fromMap(Map<String, dynamic> map) => RentalCarItem(
        id: map['id'],
        start: DateTime.parse(map['start']),
        end: map['end'] != null ? DateTime.parse(map['end']) : null,
        from: map['from'],
        to: map['to'],
        notes: map['notes'],
        price: map['price'],
        currency: map['currency'],
        company: map['company'],
        recordLocator: map['recordLocator'],
        documentIds: TravelItem.readDocumentIds(map['documentIds']),
      );

  @override
  List<Object?> get props => [id, kind, start, end, from, to, notes, price, currency, company, recordLocator, documentIds];
}
