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
  String get route => 'Route';

  @override
  String get excursion => 'Shore excursion';

  @override
  String get travel => 'Travel';

  @override
  String get cruiseDetails => 'Cruise Details';

  @override
  String get unknownHarbour => 'Unknown Harbour';

  @override
  String get noHarbour => 'Keine Harbour today or in Future';

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
  String get start => 'Start';

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
  String get transfer => 'Transfer';

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
}
