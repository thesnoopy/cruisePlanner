import 'identifiable.dart';
import 'period.dart';
import 'ship.dart';
import 'excursion.dart';
import 'travel/base_travel.dart';
import 'travel/factory.dart';
import 'route/route_item.dart';
import 'route/factory.dart' as rf;

class Cruise extends Identifiable {
  @override
  final String id;
  final String title;
  final Ship ship;
  final Period period;
  final String? cabinNumber;
  final String? deckNumber;
  final String? deckname;
  final List<Excursion> excursions;
  final List<TravelItem> travel;
  final List<RouteItem> route;

  Cruise({
    required this.id,
    required this.title,
    required this.ship,
    required this.period,
    this.cabinNumber,
    this.deckNumber,
    this.deckname,
    this.excursions = const [],
    this.travel = const [],
    this.route = const [],
  });

  Cruise copyWith({
    String? id,
    String? title,
    Ship? ship,
    Period? period,
    String? cabinNumber,
    String? deckNumber,
    String? deckname,
    List<Excursion>? excursions,
    List<TravelItem>? travel,
    List<RouteItem>? route,
  }) =>
      Cruise(
        id: id ?? this.id,
        title: title ?? this.title,
        ship: ship ?? this.ship,
        period: period ?? this.period,
        cabinNumber: cabinNumber ?? this.cabinNumber,
        deckNumber: deckNumber ?? this.deckNumber,
        deckname: deckname ?? this.deckname,
        excursions: excursions ?? this.excursions,
        travel: travel ?? this.travel,
        route: route ?? this.route,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'ship': ship.toMap(),
        'period': period.toMap(),
        'cabinNumber': cabinNumber,
        'deckNumber': deckNumber,
        'deckname': deckname,
        'excursions': excursions.map((e) => e.toMap()).toList(),
        'travel': travel.map((t) => t.toMap()).toList(),
        'route': route.map((r) => r.toMap()).toList(),
      };

  factory Cruise.fromMap(Map<String, dynamic> map) => Cruise(
        id: map['id'],
        title: map['title'],
        ship: Ship.fromMap(Map<String, dynamic>.from(map['ship'])),
        period: Period.fromMap(Map<String, dynamic>.from(map['period'])),
        cabinNumber: map['cabinNumber'],
        deckNumber: map['deckNumber'],
        deckname: map['deckname'],
        excursions: (map['excursions'] as List? ?? const [])
            .map((e) => Excursion.fromMap(Map<String, dynamic>.from(e)))
            .toList(growable: false),
        travel: (map['travel'] as List? ?? const [])
            .map((e) => travelItemFromMap(Map<String, dynamic>.from(e)))
            .toList(growable: false),
        route: (map['route'] as List? ?? const [])
            .map((e) => rf.routeItemFromMap(Map<String, dynamic>.from(e)))
            .toList(growable: false),
      );

  @override
  List<Object?> get props => [id, title, ship, period, excursions, travel, route];
}
