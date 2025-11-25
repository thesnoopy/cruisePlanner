import 'package:equatable/equatable.dart';
import 'excursion_payment_mode.dart';
import 'excursion_payment_part.dart';

class ExcursionPaymentPlan extends Equatable {
  final ExcursionPaymentMode mode;
  final List<ExcursionPaymentPart> parts;

  ExcursionPaymentPlan({
    required this.mode,
    required this.parts,
  });

  factory ExcursionPaymentPlan.fromMap(Map<String, dynamic> map) {
    final modeStr = map['mode'] as String? ?? 'fullOnBooking';
    final mode = ExcursionPaymentMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => ExcursionPaymentMode.fullOnBooking,
    );

    final partsList = (map['parts'] as List? ?? const [])
        .map((e) => ExcursionPaymentPart.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();

    return ExcursionPaymentPlan(
      mode: mode,
      parts: partsList,
    );
  }

  Map<String, dynamic> toMap() => {
        'mode': mode.name,
        'parts': parts.map((p) => p.toMap()).toList(),
      };

  /// Bereits bezahlter Betrag
  double get paidAmount =>
      parts.where((p) => p.isPaid).fold(0.0, (sum, p) => sum + p.amount);

  /// Noch offener Betrag
  double get openAmount =>
      parts.where((p) => !p.isPaid).fold(0.0, (sum, p) => sum + p.amount);

  /// True, wenn nichts mehr offen ist
  bool get isFullyPaid => openAmount == 0.0;

  @override
  List<Object?> get props => [mode, parts];
}
