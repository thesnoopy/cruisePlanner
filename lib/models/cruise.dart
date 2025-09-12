// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'excursion.dart';
import 'period.dart';
import 'ship.dart';
import 'travel.dart';

class Cruise extends Equatable {
  /// UUID als String
  final String id;
  final String title;
  final Ship ship;
  final Period period;
  final List<Excursion> excursions;

  /// An-/Abreise-Elemente (Flug/Bahn/Transfer/Mietwagen)
  final List<TravelItem> travel;

  const Cruise({
    required this.id,
    required this.title,
    required this.ship,
    required this.period,
    List<Excursion>? excursions,
    List<TravelItem>? travel,
  })  : excursions = excursions ?? const [],
        travel = travel ?? const [];

  Cruise copyWith({
    String? id,
    String? title,
    Ship? ship,
    Period? period,
    List<Excursion>? excursions,
    List<TravelItem>? travel,
  }) {
    return Cruise(
      id: id ?? this.id,
      title: title ?? this.title,
      ship: ship ?? this.ship,
      period: period ?? this.period,
      excursions: excursions ?? this.excursions,
      travel: travel ?? this.travel,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'ship': ship.toMap(),
      'period': period.toMap(),
      'excursions': excursions.map((e) => e.toMap()).toList(growable: false),
      'travel': travel.map((t) => t.toMap()).toList(growable: false),
    };
  }

  factory Cruise.fromMap(Map<String, dynamic> map) {
    // id & title robust lesen
    final rawId = map['id'];
    final rawTitle = map['title'];

    final id = (rawId is String)
        ? rawId
        : (rawId == null ? '' : rawId.toString());

    final title = (rawTitle is String)
        ? rawTitle
        : (rawTitle == null ? '' : rawTitle.toString());

    // ship robust lesen
    final shipMap = (map['ship'] is Map)
        ? Map<String, dynamic>.from(map['ship'] as Map)
        : <String, dynamic>{};
    final ship = shipMap.isEmpty
        ? const Ship(name: '', shippingLine: '')
        : Ship.fromMap(shipMap);

    // period robust lesen (Fallback: heute)
    final periodMap = (map['period'] is Map)
        ? Map<String, dynamic>.from(map['period'] as Map)
        : <String, dynamic>{};
    final now = DateTime.now();
    final period = periodMap.isEmpty
        ? Period(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day),
          )
        : Period.fromMap(periodMap);

    // excursions robust lesen (alles andere -> [])
    List<Excursion> excursions = const [];
    final rawExc = map['excursions'];
    if (rawExc is List) {
      excursions = rawExc
          .where((e) => e is Map)
          .map((e) => Excursion.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    }

    // travel robust lesen (alles andere -> [])
    List<TravelItem> travel = const [];
    final rawTravel = map['travel'];
    if (rawTravel is List) {
      travel = rawTravel
          .where((e) => e is Map)
          .map((e) => TravelItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    }

    return Cruise(
      id: id,
      title: title,
      ship: ship,
      period: period,
      excursions: excursions,
      travel: travel,
    );
  }

  String toJson() => json.encode(toMap());

  factory Cruise.fromJson(String source) =>
      Cruise.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Nächstes Travel-Item ab [now] (oder `null`, wenn keins).
  TravelItem? nextTravelItem(DateTime now) {
    final upcoming = travel.where((t) => !t.start.isBefore(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Helfer zum Erzeugen einer neuen UUID v4
  static String newId() => const Uuid().v4();

  @override
  List<Object?> get props => [id, title, ship, period, excursions, travel];

  @override
  bool get stringify => true;
}
