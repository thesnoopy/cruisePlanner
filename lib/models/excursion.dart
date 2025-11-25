
import 'identifiable.dart';
import 'excursions/excursion_payment_plan.dart';

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
    this.paymentPlan,
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
        paymentPlan,
      ];
}
