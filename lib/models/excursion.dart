
import 'identifiable.dart';
import 'documents/document_ids.dart';
import 'sync_metadata.dart';
import 'excursions/excursion_payment_plan.dart';
import 'excursions/excursion_stop.dart';

class Excursion extends Identifiable {
  static const Object _unset = Object();

  @override
  final String id;
  final String title;
  final DateTime date;
  final String? port;
  final String? meetingPoint;
  final String? notes;
  final num? price;
  final String? currency;
  final List<ExcursionStop> stops;
  final List<String> documentIds;
  final DateTime? updatedAtUtc;
  final DateTime? deletedAtUtc;

  final ExcursionPaymentPlan? paymentPlan;

  Excursion({
    required this.id,
    required this.title,
    required this.date,
    this.port,
    this.meetingPoint,
    this.notes,
    this.price,
    this.currency,
    this.stops = const [],
    List<String> documentIds = const [],
    this.updatedAtUtc,
    this.deletedAtUtc,
    this.paymentPlan,
  }) : documentIds = DocumentIds.fromJsonValue(documentIds);

  Excursion copyWith({
    String? id,
    String? title,
    DateTime? date,
    Object? port = _unset,
    Object? meetingPoint = _unset,
    Object? notes = _unset,
    Object? price = _unset,
    Object? currency = _unset,
    List<ExcursionStop>? stops,
    List<String>? documentIds,
    Object? updatedAtUtc = _unset,
    Object? deletedAtUtc = _unset,
    Object? paymentPlan = _unset,
  }) {
    return Excursion(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      port: identical(port, _unset) ? this.port : port as String?,
      meetingPoint: identical(meetingPoint, _unset)
          ? this.meetingPoint
          : meetingPoint as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      price: identical(price, _unset) ? this.price : price as num?,
      currency:
          identical(currency, _unset) ? this.currency : currency as String?,
      stops: stops ?? this.stops,
      documentIds: documentIds ?? this.documentIds,
      updatedAtUtc: identical(updatedAtUtc, _unset)
          ? this.updatedAtUtc
          : updatedAtUtc as DateTime?,
      deletedAtUtc: identical(deletedAtUtc, _unset)
          ? this.deletedAtUtc
          : deletedAtUtc as DateTime?,
      paymentPlan: identical(paymentPlan, _unset)
          ? this.paymentPlan
          : paymentPlan as ExcursionPaymentPlan?,
    );
  }

  factory Excursion.fromMap(Map<String, dynamic> map) {
    return Excursion(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      port: map['port'],
      meetingPoint: map['meetingPoint'],
      notes: map['notes'],
      price: map['price'],
      currency: map['currency'],
      stops: (map['stops'] as List? ?? const [])
          .map((e) => ExcursionStop.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      documentIds: DocumentIds.fromJsonValue(map['documentIds']),
      updatedAtUtc: readNullableUtcDateTime(map, 'updatedAtUtc'),
      deletedAtUtc: readNullableUtcDateTime(map, 'deletedAtUtc'),
      paymentPlan: map['paymentPlan'] != null
          ? ExcursionPaymentPlan.fromMap(Map<String, dynamic>.from(map['paymentPlan']))
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'port': port,
        'meetingPoint': meetingPoint,
        'notes': notes,
        'price': price,
        'currency': currency,
        'stops': stops.map((stop) => stop.toMap()).toList(growable: false),
        'documentIds': documentIds,
        'updatedAtUtc': writeNullableUtcDateTime(updatedAtUtc),
        'deletedAtUtc': writeNullableUtcDateTime(deletedAtUtc),
        'paymentPlan': paymentPlan?.toMap(),
      };

  @override
  List<Object?> get props => [
        id,
        title,
        date,
        port,
        meetingPoint,
        notes,
        price,
        currency,
        stops,
        documentIds,
        updatedAtUtc,
        deletedAtUtc,
        paymentPlan,
      ];
}
