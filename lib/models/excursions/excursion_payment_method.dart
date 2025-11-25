
enum ExcursionPaymentMethod {
  cash,
  creditCard,
}

String excursionPaymentMethodToString(ExcursionPaymentMethod m) {
  switch (m) {
    case ExcursionPaymentMethod.cash:
      return 'cash';
    case ExcursionPaymentMethod.creditCard:
      return 'creditCard';
  }
}

ExcursionPaymentMethod excursionPaymentMethodFromString(String value) {
  switch (value) {
    case 'creditCard':
      return ExcursionPaymentMethod.creditCard;
    case 'cash':
    default:
      return ExcursionPaymentMethod.cash;
  }
}
