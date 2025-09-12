// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class Period extends Equatable {
  final DateTime start;
  final DateTime end;

  Period({
    required this.start,
    required this.end,
  }) : assert(!end.isBefore(start), 'end must be >= start');

  Duration get length => end.difference(start);

  Period copyWith({
    DateTime? start,
    DateTime? end,
  }) {
    return Period(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
    };
  }

  factory Period.fromMap(Map<String, dynamic> map) {
    return Period(
      start: DateTime.fromMillisecondsSinceEpoch(map['start'] as int),
      end: DateTime.fromMillisecondsSinceEpoch(map['end'] as int),
    );
  }

  @override
  List<Object> get props => [start, end];

  String toJson() => json.encode(toMap());

  factory Period.fromJson(String source) => Period.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
