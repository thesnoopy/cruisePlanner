enum ExcursionPaymentTrigger {
  onBooking,
  beforeDate,
  onSite,
}

String excursionPaymentTriggerToString(ExcursionPaymentTrigger t) {
  switch (t) {
    case ExcursionPaymentTrigger.onBooking:
      return 'onBooking';
    case ExcursionPaymentTrigger.beforeDate:
      return 'beforeDate';
    case ExcursionPaymentTrigger.onSite:
      return 'onSite';
  }
}

ExcursionPaymentTrigger excursionPaymentTriggerFromString(String? value) {
  switch (value) {
    case 'beforeDate':
      return ExcursionPaymentTrigger.beforeDate;
    case 'onSite':
      return ExcursionPaymentTrigger.onSite;
    case 'onBooking':
    default:
      return ExcursionPaymentTrigger.onBooking;
  }
}
