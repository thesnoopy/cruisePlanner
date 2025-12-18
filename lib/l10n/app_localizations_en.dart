// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cruise Planner';

  @override
  String get homeTitle => 'Your cruises';

  @override
  String get homeNoCruises => 'No cruises yet. Tap + to add one.';

  @override
  String get homeNewCruiseLabel => 'New cruise';

  @override
  String get homeWebdavSettingsTooltip => 'WebDAV settings';

  @override
  String get homeCloudSyncTooltip => 'Cloud sync';

  @override
  String get homeCloudSyncNoStore => 'Cruise store not available – sync not possible.';

  @override
  String get homeCloudSyncNoWebdav => 'Please save WebDAV settings first.';

  @override
  String get homeCloudSyncDone => 'Cloud sync finished.';

  @override
  String homeCloudSyncFailed(String error) {
    return 'Cloud sync failed: $error';
  }

  @override
  String get homeDeleteTooltip => 'Delete';

  @override
  String get cruisePlanner => 'Cruise Planer';

  @override
  String get ship => 'Ship';

  @override
  String get cruise => 'Cruise';

  @override
  String get route => 'Itinerary';

  @override
  String get excursion => 'Shore excursion';

  @override
  String get travel => 'Travel';

  @override
  String get cruiseDetails => 'Cruise Details';

  @override
  String get unknownHarbour => 'Unknown Harbour';

  @override
  String get noHarbour => 'No Harbour today or in Future';

  @override
  String get arrival => 'Arrival';

  @override
  String get departure => 'Departure';

  @override
  String get allOnBoard => 'All on Board';

  @override
  String get noFutureExcursions => 'No Excursion';

  @override
  String get today => 'Today';

  @override
  String get harbour => 'Port';

  @override
  String get meetingPoint => 'Meeting Point';

  @override
  String get price => 'Price';

  @override
  String get noTravelItem => 'No Travel Item';

  @override
  String get start => 'Departure';

  @override
  String get end => 'End';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get flight => 'Flight';

  @override
  String get train => 'Train';

  @override
  String get transfer => 'Transfer service';

  @override
  String get rentalCar => 'Rental Car';

  @override
  String get flightnumber => 'Flight Number';

  @override
  String get rentalCarCompany => 'Rental Car Company';

  @override
  String get title => 'Title';

  @override
  String get requiredField => 'Required Field';

  @override
  String get chatterOptional => 'Chatter (optional)';

  @override
  String get save => 'Save';

  @override
  String get seaDay => 'Sea Day';

  @override
  String get editPort => 'Edit Port';

  @override
  String get editSeaDay => 'Edit Seaday';

  @override
  String get date => 'Date';

  @override
  String get arrivalOptional => 'Arrival (optional)';

  @override
  String get departureOptional => 'Departure (optional)';

  @override
  String get dateAndTime => 'Date & Time';

  @override
  String get allOnBoardOptional => 'All on Board (optional)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get newExcursion => 'New Excursion';

  @override
  String get noPort => 'No Port';

  @override
  String get excursions => 'Excursions';

  @override
  String get editExcursion => 'Edit Excursion';

  @override
  String get currencyOptional => 'Currency (optional)';

  @override
  String get editTravel => 'Edit Travel';

  @override
  String get airlineOptional => 'Airline (optional)';

  @override
  String get bookingNumberOptional => 'Booking number (optional)';

  @override
  String get modeOptional => 'Mode (optional)';

  @override
  String get editFlight => 'Edit Flight';

  @override
  String get editTrain => 'Edit Train';

  @override
  String get editRentalCar => 'Edit Rental Car';

  @override
  String get editTransfer => 'Edit Travel';

  @override
  String get cruiseCheckIn => 'Cruise Check-In';

  @override
  String get cruiseCheckOut => 'Cruise Check-Out';

  @override
  String get hotel => 'Hotel';

  @override
  String get cabinNumber => 'Cabin Number';

  @override
  String get deckNumber => 'Deck Number';

  @override
  String get deckname => 'Deck name';

  @override
  String get deposit => 'Deposit';

  @override
  String get finalPayment => 'Final Payment';

  @override
  String get noPaymentInformation => 'No payment information';

  @override
  String get fullyPayed => 'Fully paied';

  @override
  String get payOnBooking => 'Pay on Booking';

  @override
  String get stillOpen => 'still open';

  @override
  String get withoutDate => 'without Date';

  @override
  String get payed => 'payed';

  @override
  String get open => 'open';

  @override
  String get onSide => 'on side';

  @override
  String get amountPayableOnSide => 'The total amount is payable on-site';

  @override
  String get amountOnSide => 'The total amount is on-site';

  @override
  String get payment => 'Payment';

  @override
  String get paymentType => 'Payment Type';

  @override
  String get finalPaymentOnDate => 'Final Payment on Date';

  @override
  String get finalPaymentOnSide => 'Final Payment on Side';

  @override
  String get amountAlreadyPayed => 'Amount already paied';

  @override
  String get depositAlreadyPayed => 'Deposit already paied';

  @override
  String get remainingAmountOptional => 'Remaining amount (optional)';

  @override
  String get leaveEmptyForAutomaticCalculation => 'Leave empty for automatic calculation';

  @override
  String get remainingAmountDueUntill => 'remaining amount due untill';

  @override
  String get noDateSelected => 'No date selected';

  @override
  String get remainingAmountAlreadyPaied => 'remaining amount already paied';

  @override
  String get remainingAmountOnSide => 'Remaining amount on side';

  @override
  String get paymentTypesOnSide => 'Payment types on side';

  @override
  String get cash => 'Cash';

  @override
  String get credit => 'Credit';

  @override
  String get cashCurrency => 'Cash-currency';

  @override
  String get onlyLocalCurrency => 'Only local currency';

  @override
  String get localCurrencyOrOwnCurrency => 'Local currency or own currency';

  @override
  String get finalPaymentAlreadyPayed => 'Final payment already paied';

  @override
  String get fullPaymentOnSide => 'Full payment on side';

  @override
  String get confirmDefaultTitle => 'Confirm';

  @override
  String get confirmDefaultMessage => 'Do you want to proceed?';

  @override
  String get confirmOk => 'OK';

  @override
  String get confirmCancel => 'Cancel';

  @override
  String get deleteExcursionTitle => 'Delete Excursion';

  @override
  String get deleteExcursionQuestionmark => 'Really delete excursion?';

  @override
  String get delete => 'delete';

  @override
  String get deleteCruiseTitle => 'Delete Cruise';

  @override
  String get deleteCruiseQuestionmark => 'Really delete this cruise?';

  @override
  String get deleteRouteItemTitle => 'Delete Port / Seeday';

  @override
  String get deleteRouteItemQuestionmark => 'Really delete this Port / Seeday?';

  @override
  String get deleteTravelItemTitle => 'Delete travel item';

  @override
  String get deleteTravelItemQuestionmark => 'Really delete this travel item?';

  @override
  String get location => 'Address';
}
