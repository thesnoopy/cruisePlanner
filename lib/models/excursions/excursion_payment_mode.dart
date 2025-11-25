enum ExcursionPaymentMode {
  fullOnBooking,
  depositAndRestDate,
  depositAndRestOnSite,
  fullOnSite,
}

String excursionPaymentModeToString(ExcursionPaymentMode mode) {
  switch (mode) {
    case ExcursionPaymentMode.fullOnBooking:
      return 'fullOnBooking';
    case ExcursionPaymentMode.depositAndRestDate:
      return 'depositAndRestDate';
    case ExcursionPaymentMode.depositAndRestOnSite:
      return 'depositAndRestOnSite';
    case ExcursionPaymentMode.fullOnSite:
      return 'fullOnSite';
  }
}

ExcursionPaymentMode excursionPaymentModeFromString(String? value) {
  switch (value) {
    case 'depositAndRestDate':
      return ExcursionPaymentMode.depositAndRestDate;
    case 'depositAndRestOnSite':
      return ExcursionPaymentMode.depositAndRestOnSite;
    case 'fullOnSite':
      return ExcursionPaymentMode.fullOnSite;
    case 'fullOnBooking':
    default:
      return ExcursionPaymentMode.fullOnBooking;
  }
}
