
import 'package:equatable/equatable.dart';

class Period extends Equatable {
  final DateTime start;
  final DateTime end;

  const Period({required this.start, required this.end});

  Period copyWith({DateTime? start, DateTime? end}) =>
      Period(start: start ?? this.start, end: end ?? this.end);

  Map<String, dynamic> toMap() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  factory Period.fromMap(Map<String, dynamic> map) =>
      Period(start: DateTime.parse(map['start']), end: DateTime.parse(map['end']));

  @override
  List<Object?> get props => [start, end];
}
