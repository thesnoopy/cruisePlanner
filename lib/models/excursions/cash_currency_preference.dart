
enum CashCurrencyPreference {
  localOnly,
  localOrHome,
}

String cashCurrencyPreferenceToString(CashCurrencyPreference c) {
  switch (c) {
    case CashCurrencyPreference.localOnly:
      return 'localOnly';
    case CashCurrencyPreference.localOrHome:
      return 'localOrHome';
  }
}

CashCurrencyPreference cashCurrencyPreferenceFromString(String value) {
  switch (value) {
    case 'localOrHome':
      return CashCurrencyPreference.localOrHome;
    case 'localOnly':
    default:
      return CashCurrencyPreference.localOnly;
  }
}
