
import 'base_travel.dart';

class FlightItem extends TravelItem {
  static const Object _unset = Object();

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
  @override
  final DateTime? updatedAtUtc;
  @override
  final DateTime? deletedAtUtc;

  final String? carrier;
  final String? flightNo;


  FlightItem({
    required this.id,
    required this.start,
    this.end,
    this.from,
    this.to,
    this.notes,
    this.price,
    this.currency,
    this.carrier,
    this.flightNo,
    this.recordLocator,
    List<String> documentIds = const [],
    this.updatedAtUtc,
    this.deletedAtUtc,
  }) : documentIds = TravelItem.readDocumentIds(documentIds);

  @override
  TravelKind get kind => TravelKind.flight;

  FlightItem copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency,
    String? carrier,
    String? flightNo,
    String? recordLocator,
    List<String>? documentIds,
    Object? updatedAtUtc = _unset,
    Object? deletedAtUtc = _unset,
  }) =>
      FlightItem(
        id: id ?? this.id,
        start: start ?? this.start,
        end: end ?? this.end,
        from: from ?? this.from,
        to: to ?? this.to,
        notes: notes ?? this.notes,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        carrier: carrier ?? this.carrier,
        flightNo: flightNo ?? this.flightNo,
        recordLocator: recordLocator ?? this.recordLocator,
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
        'type': 'flight',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'from': from,
        'to': to,
        'notes': notes,
        'price': price,
        'currency': currency,
        'carrier': carrier,
        'flightNo': flightNo,
        'recordLocator': recordLocator,
        'documentIds': documentIds,
        'updatedAtUtc': TravelItem.writeSyncTimestamp(updatedAtUtc),
        'deletedAtUtc': TravelItem.writeSyncTimestamp(deletedAtUtc),
      };

  factory FlightItem.fromMap(Map<String, dynamic> map) => FlightItem(
        id: map['id'],
        start: DateTime.parse(map['start']),
        end: map['end'] != null ? DateTime.parse(map['end']) : null,
        from: map['from'],
        to: map['to'],
        notes: map['notes'],
        price: map['price'],
        currency: map['currency'],
        carrier: map['carrier'],
        flightNo: map['flightNo'],
        recordLocator: map['recordLocator'],
        documentIds: TravelItem.readDocumentIds(map['documentIds']),
        updatedAtUtc: TravelItem.readSyncTimestamp(map, 'updatedAtUtc'),
        deletedAtUtc: TravelItem.readSyncTimestamp(map, 'deletedAtUtc'),
      );

  @override
  List<Object?> get props => [
    id, kind, start, end, from, to, notes, price, currency, carrier, flightNo, recordLocator, documentIds, updatedAtUtc, deletedAtUtc
  ];
}
