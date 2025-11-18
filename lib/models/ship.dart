
import 'package:equatable/equatable.dart';

class Ship extends Equatable {
  final String name;
  final String? operatorName;

  const Ship({required this.name, this.operatorName});

  Ship copyWith({String? name, String? operatorName}) =>
      Ship(name: name ?? this.name, operatorName: operatorName ?? this.operatorName);

  Map<String, dynamic> toMap() => {'name': name, 'operatorName': operatorName};

  factory Ship.fromMap(Map<String, dynamic> map) =>
      Ship(name: map['name'], operatorName: map['operatorName']);

  @override
  List<Object?> get props => [name, operatorName];
}
