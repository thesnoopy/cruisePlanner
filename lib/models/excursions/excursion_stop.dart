import 'package:equatable/equatable.dart';

class ExcursionStop extends Equatable {
  final String id;
  final String name;
  final String? address;
  final bool visited;

  const ExcursionStop({
    required this.id,
    required this.name,
    this.address,
    this.visited = false,
  });

  ExcursionStop copyWith({
    String? id,
    String? name,
    String? address,
    bool? visited,
  }) {
    return ExcursionStop(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      visited: visited ?? this.visited,
    );
  }

  factory ExcursionStop.fromMap(Map<String, dynamic> map) {
    return ExcursionStop(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      visited: map['visited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'visited': visited,
      };

  @override
  List<Object?> get props => [id, name, address, visited];
}
