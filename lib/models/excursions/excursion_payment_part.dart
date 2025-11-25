
import 'package:equatable/equatable.dart';
import 'excursion_payment_trigger.dart';
import 'excursion_payment_method.dart';
import 'cash_currency_preference.dart';

class ExcursionPaymentPart extends Equatable {
  final ExcursionPaymentTrigger trigger;
  final double amount;

  final DateTime? dueDate;
  final bool isPaid;
  final DateTime? paidOn;

  final Set<ExcursionPaymentMethod> paymentMethods;
  final CashCurrencyPreference? cashCurrencyPreference;

  ExcursionPaymentPart({
    required this.trigger,
    required this.amount,
    this.dueDate,
    this.isPaid = false,
    this.paidOn,
    Set<ExcursionPaymentMethod>? paymentMethods,
    this.cashCurrencyPreference,
  }) : paymentMethods = paymentMethods ?? const {};

  factory ExcursionPaymentPart.fromMap(Map<String, dynamic> map) {
    return ExcursionPaymentPart(
      trigger: excursionPaymentTriggerFromString(map['trigger'] as String?),
      amount: (map['amount'] as num).toDouble(),
      dueDate:
          map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isPaid: map['isPaid'] ?? false,
      paidOn:
          map['paidOn'] != null ? DateTime.parse(map['paidOn']) : null,
      paymentMethods: map['paymentMethods'] != null
          ? (map['paymentMethods'] as List<dynamic>)
              .map((e) =>
                  excursionPaymentMethodFromString(e as String))
              .toSet()
          : <ExcursionPaymentMethod>{},
      cashCurrencyPreference: map['cashCurrencyPreference'] != null
          ? cashCurrencyPreferenceFromString(
              map['cashCurrencyPreference'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trigger': excursionPaymentTriggerToString(trigger),
      'amount': amount,
      'dueDate': dueDate?.toIso8601String(),
      'isPaid': isPaid,
      'paidOn': paidOn?.toIso8601String(),
      'paymentMethods':
          paymentMethods.map(excursionPaymentMethodToString).toList(),
      'cashCurrencyPreference': cashCurrencyPreference != null
          ? cashCurrencyPreferenceToString(cashCurrencyPreference!)
          : null,
    };
  }

  @override
  List<Object?> get props => [
        trigger,
        amount,
        dueDate,
        isPaid,
        paidOn,
        paymentMethods.toList(),
        cashCurrencyPreference,
      ];
}
