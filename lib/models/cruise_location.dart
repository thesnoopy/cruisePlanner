import 'identifiable.dart';
import 'sync_metadata.dart';

enum CruiseLocationType { port, stopPoint }

class CruiseLocation extends Identifiable {
  static const Object _unset = Object();

  @override
  final String id;
  final String name;
  final CruiseLocationType type;
  final DateTime? updatedAtUtc;
  final DateTime? deletedAtUtc;

  CruiseLocation({
    required this.id,
    required this.name,
    required this.type,
    this.updatedAtUtc,
    this.deletedAtUtc,
  });

  CruiseLocation copyWith({
    String? name,
    CruiseLocationType? type,
    Object? updatedAtUtc = _unset,
    Object? deletedAtUtc = _unset,
  }) => CruiseLocation(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    updatedAtUtc: identical(updatedAtUtc, _unset)
        ? this.updatedAtUtc : updatedAtUtc as DateTime?,
    deletedAtUtc: identical(deletedAtUtc, _unset)
        ? this.deletedAtUtc : deletedAtUtc as DateTime?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'updatedAtUtc': writeNullableUtcDateTime(updatedAtUtc),
    'deletedAtUtc': writeNullableUtcDateTime(deletedAtUtc),
  };

  factory CruiseLocation.fromMap(Map<String, dynamic> map) => CruiseLocation(
    id: map['id'] as String,
    name: map['name'] as String,
    type: CruiseLocationType.values.byName(map['type'] as String),
    updatedAtUtc: readNullableUtcDateTime(map, 'updatedAtUtc'),
    deletedAtUtc: readNullableUtcDateTime(map, 'deletedAtUtc'),
  );

  @override
  List<Object?> get props => [id, name, type, updatedAtUtc, deletedAtUtc];
}
