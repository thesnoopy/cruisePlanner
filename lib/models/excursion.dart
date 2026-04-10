
import 'identifiable.dart';
import 'documents/document_ids.dart';
import 'excursions/excursion_payment_plan.dart';
import 'excursions/excursion_stop.dart';

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
  final List<ExcursionStop> stops;
  final List<String> documentIds;

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
    this.paymentPlan,
  }) : documentIds = DocumentIds.fromJsonValue(documentIds);

  Excursion copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? port,
    String? meetingPoint,
    String? notes,
    num? price,
    String? currency,
    List<ExcursionStop>? stops,
    List<String>? documentIds,
    ExcursionPaymentPlan? paymentPlan,
  }) {
    return Excursion(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      port: port ?? this.port,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      notes: notes ?? this.notes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      stops: stops ?? this.stops,
      documentIds: documentIds ?? this.documentIds,
      paymentPlan: paymentPlan ?? this.paymentPlan,
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
        paymentPlan,
      ];
}
