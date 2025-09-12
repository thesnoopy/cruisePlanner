// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class Excursion extends Equatable {
  final String id;            // UUID
  final String title;         // Pflicht
  final DateTime date;        // Pflicht
  final String? port;         // optional
  final String? meetingPoint; // optional
  final String? notes;        // optional
  final num? price;           // optional
  final String? currency;     // optional

  const Excursion({
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
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'port': port,
      'meetingPoint': meetingPoint,
      'notes': notes,
      'price': price,
      'currency': currency,
    };
  }

  factory Excursion.fromMap(Map<String, dynamic> map) {
    return Excursion(
      id: map['id'] as String,
      title: map['title'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      port: map['port'] != null ? map['port'] as String : null,
      meetingPoint: map['meetingPoint'] != null ? map['meetingPoint'] as String : null,
      notes: map['notes'] != null ? map['notes'] as String : null,
      price: map['price'] != null ? map['price'] as num : null,
      currency: map['currency'] != null ? map['currency'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Excursion.fromJson(String source) =>
      Excursion.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props {
    return [
      id,
      title,
      date,
      port,
      meetingPoint,
      notes,
      price,
      currency,
    ];
  }

  @override
  bool get stringify => true;
}
