
import '../identifiable.dart';

enum TravelKind { flight, train, transfer, rentalCar }

abstract class TravelItem extends Identifiable {
  @override
  String get id;
  TravelKind get kind;
  DateTime get start;
  DateTime? get end;
  String? get from;
  String? get to;
  String? get notes;
  num? get price;
  String? get currency;

  Map<String, dynamic> toMap();
}
