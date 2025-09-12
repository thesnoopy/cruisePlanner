import 'package:equatable/equatable.dart';

class Ship extends Equatable {
  final String name;
  final String shippingLine;

  const Ship({
    required this.name,
    required this.shippingLine,
  });

  Ship copyWith({String? name, String? shippingLine}) {
    return Ship(
      name: name ?? this.name,
      shippingLine: shippingLine ?? this.shippingLine,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'shippingLine': shippingLine,
      };

  factory Ship.fromMap(Map<String, dynamic> map) {
    return Ship(
      name: (map['name'] as String).trim(),
      shippingLine: (map['shippingLine'] as String).trim(),
    );
  }

  @override
  List<Object?> get props => [name, shippingLine];
}
