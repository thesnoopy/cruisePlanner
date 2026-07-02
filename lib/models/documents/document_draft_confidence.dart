import 'package:equatable/equatable.dart';

class DocumentDraftConfidence extends Equatable {
  static const Object _unset = Object();

  final double? score;
  final String? reason;

  const DocumentDraftConfidence({
    this.score,
    this.reason,
  });

  DocumentDraftConfidence copyWith({
    Object? score = _unset,
    Object? reason = _unset,
  }) {
    return DocumentDraftConfidence(
      score: identical(score, _unset) ? this.score : score as double?,
      reason: identical(reason, _unset) ? this.reason : reason as String?,
    );
  }

  @override
  List<Object?> get props => [score, reason];
}
