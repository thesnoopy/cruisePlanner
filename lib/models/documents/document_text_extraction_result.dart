import 'package:equatable/equatable.dart';

class DocumentTextExtractionResult extends Equatable {
  static const Object _unset = Object();

  final String extractedText;
  final bool usedOcr;
  final double? confidenceScore;
  final String? diagnosticReason;

  const DocumentTextExtractionResult({
    required this.extractedText,
    this.usedOcr = false,
    this.confidenceScore,
    this.diagnosticReason,
  });

  bool get hasText => extractedText.trim().isNotEmpty;

  DocumentTextExtractionResult copyWith({
    String? extractedText,
    bool? usedOcr,
    Object? confidenceScore = _unset,
    Object? diagnosticReason = _unset,
  }) {
    return DocumentTextExtractionResult(
      extractedText: extractedText ?? this.extractedText,
      usedOcr: usedOcr ?? this.usedOcr,
      confidenceScore: identical(confidenceScore, _unset)
          ? this.confidenceScore
          : confidenceScore as double?,
      diagnosticReason: identical(diagnosticReason, _unset)
          ? this.diagnosticReason
          : diagnosticReason as String?,
    );
  }

  @override
  List<Object?> get props => [
        extractedText,
        usedOcr,
        confidenceScore,
        diagnosticReason,
      ];
}
