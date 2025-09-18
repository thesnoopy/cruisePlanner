// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cruise App';

  @override
  String get menuExcursions => 'Excursions';

  @override
  String get menuSettings => 'Settings';

  @override
  String get cruises => 'Cruises';

  @override
  String get webDavConfigured => 'WebDAV configured';

  @override
  String get couldNotLoadData => 'Could not load data: ';

  @override
  String get pleaseEnterWebdavCredentials => 'Please enter WebDAV credentials';

  @override
  String get uploadOk => 'Upload (new) OK';

  @override
  String get downloadOk => 'Download OK';

  @override
  String get remoteWasNewerEtag => 'Remote was newer (ETag) → Download';

  @override
  String get localWasNewerUpload => 'Local was newer → Upload';

  @override
  String get alreadyUpToDate => 'Already up to date';

  @override
  String get remoteWasNewerDownload => 'Remote was newer → Download';

  @override
  String get syncError => 'SYNC ERROR: ';

  @override
  String get syncFailed => 'Sync failed: ';

  @override
  String get stored => 'Saved: ';

  @override
  String get storingFailed => 'Save failed: ';

  @override
  String get syncWithWebdav => 'Sync with WebDAV';

  @override
  String get settings => 'Settings';

  @override
  String get noCruiseYet => 'No cruises yet. Tap +';

  @override
  String get noTitle => '(no title)';

  @override
  String get pleaseCheckEntries => 'Please check your entries';

  @override
  String get finished => 'Done';

  @override
  String get next => 'Next';

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get wizardTitleNewCruise => 'New Cruise';

  @override
  String get cruiseTitleLabel => 'Title';

  @override
  String get cruiseTitleHintText => 'e.g., Mediterranean 2026';

  @override
  String get titleMustNotBeEmpty => 'Title must not be empty';

  @override
  String get shipLabel => 'Ship';

  @override
  String get shipName => 'Ship name';

  @override
  String get shipNameHintText => 'e.g., AIDAcosma';

  @override
  String get pleaseEnterShipName => 'Please enter the ship name';

  @override
  String get cruiseCompany => 'Cruise line';

  @override
  String get cruiseCompanyHintText => 'e.g., AIDA Cruises';

  @override
  String get pleaseEnterCruiseCompany => 'Please enter the cruise line';

  @override
  String get periodLabel => 'Period';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get endMustAfterStart => 'End date must be after start date';

  @override
  String excursionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count excursions',
      one: '1 excursion',
      zero: 'No excursions',
    );
    return '$_temp0';
  }

  @override
  String get createExcursion => 'Create new excursion';

  @override
  String get noExcursions => 'No excursions yet';

  @override
  String get deleteExcursion => 'Delete excursion?';

  @override
  String get reallyDelete => 'Really delete?';

  @override
  String get delete => 'Delete';

  @override
  String get changeExcursion => 'Edit excursion';

  @override
  String get titleStar => 'Title *';

  @override
  String get titelStarHintText => 'e.g., Halifax city tour';

  @override
  String get titleMustNotBEEmpty => 'Title must not be empty.';

  @override
  String get mustBeBetween => 'Must be between ';

  @override
  String get and => ' and ';

  @override
  String get lie => '';

  @override
  String get harbourOptional => 'Port (optional)';

  @override
  String get harbourOptionalHintText => 'e.g., Halifax';

  @override
  String get meetingPoint => 'Meeting point';

  @override
  String get meetingPointHintText => 'e.g., port exit';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get priceOptional => 'Price (optional)';

  @override
  String get priceOptionalHintText => 'e.g., 49.90';

  @override
  String get currencyOptional => 'Currency (optional)';

  @override
  String get currencyOptionalHintText => 'e.g., EUR, USD, CAD';

  @override
  String get store => 'Store';

  @override
  String get create => 'Create';

  @override
  String get connectionOk => 'Connection OK';

  @override
  String get connectionFailed => 'Connection failed: ';

  @override
  String get webdavSettings => 'WebDAV Settings';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get baseUrlHintText => 'https://server/remote.php/dav/files/USERNAME/';

  @override
  String get pleaseEnterBaseUrl => 'Please enter the Base URL';

  @override
  String get urlMustStartWithHttp => 'URL must start with http/https';

  @override
  String get username => 'Username';

  @override
  String get pleaseEnterUsername => 'Please enter the username';

  @override
  String get password => 'Password';

  @override
  String get pleaseEnterPassword => 'Please enter the password';

  @override
  String get remotePath => 'Remote path';

  @override
  String get pleaseEnterPath => 'Please enter the path';

  @override
  String get testConnection => 'Test connection';

  @override
  String get excursionTitleLabel => 'Title';

  @override
  String get dateLabel => 'Date';

  @override
  String get portLabel => 'Port';

  @override
  String get notesLabel => 'Notes';

  @override
  String get priceLabel => 'Price';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get tapToAddExcursion => 'Tap to add an excursion';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String excursionOn(String date) {
    return 'Excursion on $date';
  }

  @override
  String get cruiseDetailsTitle => 'Cruise details';

  @override
  String get excursionsCountLabel => 'excursions planned';

  @override
  String get seeDetailsCta => 'See details';

  @override
  String get nextExcursionTitle => 'Next excursion';

  @override
  String get nonePlanned => 'No excursion planned';

  @override
  String get dash => '—';

  @override
  String get totalLabel => 'total';

  @override
  String get upcomingLabel => 'upcoming';

  @override
  String get seeAllExcursionsCta => 'All excursions';

  @override
  String get excursionsTitle => 'Excursions';

  @override
  String get addNew => 'Add new';

  @override
  String get noExcursionsYet => 'No excursions yet.';

  @override
  String get excursionDetailsTitle => 'Excursion details';

  @override
  String get meetingPointLabel => 'Meeting point';

  @override
  String get edit => 'Edit';

  @override
  String get deleteCruiseTitle => 'Delete trip?';

  @override
  String deleteCruiseMessage(String title) {
    return 'Really delete “$title”?';
  }

  @override
  String get deleteConfirm => 'Delete';

  @override
  String get deleteCancel => 'Cancel';

  @override
  String deletedCruiseSnack(String title) {
    return '“$title” deleted';
  }

  @override
  String get undo => 'Undo';

  @override
  String get travelSectionTitle => 'Arrival & departure';

  @override
  String get travelEmptyHint =>
      'No travel segments yet. Add your first segment.';

  @override
  String get travelShowAll => 'Show all';

  @override
  String get travelAddNew => 'New segment';

  @override
  String get travelChooseTypeTitle => 'Choose type';

  @override
  String get travelOverviewTitle => 'Travel plan';

  @override
  String travelOverviewSubtitle(String cruiseTitle) {
    return 'for $cruiseTitle';
  }

  @override
  String get travelKind_flight => 'Flight';

  @override
  String get travelKind_train => 'Train';

  @override
  String get travelKind_transfer => 'Transfer';

  @override
  String get travelKind_rentalCar => 'Rental car';

  @override
  String get transferMode_shuttle => 'Shuttle';

  @override
  String get transferMode_taxi => 'Taxi';

  @override
  String get transferMode_privateDriver => 'Private driver';

  @override
  String get transferMode_rideshare => 'Rideshare';

  @override
  String get label_from => 'From';

  @override
  String get label_to => 'To';

  @override
  String get label_pickup => 'Pickup';

  @override
  String get label_dropoff => 'Drop-off';

  @override
  String get label_start => 'Start';

  @override
  String get label_end => 'End';

  @override
  String label_timeRange(String start, String end) {
    return '$start → $end';
  }

  @override
  String get label_price => 'Price';

  @override
  String get label_currency => 'Currency';

  @override
  String get flight_airline => 'Airline';

  @override
  String get flight_number => 'Flight No.';

  @override
  String get flight_bookingRef => 'Booking ref.';

  @override
  String get flight_bookingClass => 'Class';

  @override
  String get flight_seat => 'Seat';

  @override
  String get flight_terminalDep => 'Terminal (dep.)';

  @override
  String get flight_terminalArr => 'Terminal (arr.)';

  @override
  String get flight_baggagePieces => 'Baggage pieces';

  @override
  String get train_operator => 'Operator';

  @override
  String get train_number => 'Train No.';

  @override
  String get train_coach => 'Coach';

  @override
  String get train_seat => 'Seat';

  @override
  String get transfer_provider => 'Provider';

  @override
  String get transfer_confirmation => 'Confirmation';

  @override
  String get transfer_pax => 'Pax';

  @override
  String get rental_company => 'Company';

  @override
  String get rental_reservation => 'Reservation';

  @override
  String get rental_vehicleClass => 'Vehicle class';

  @override
  String get rental_pickupLocation => 'Pickup location';

  @override
  String get rental_dropoffLocation => 'Drop-off location';

  @override
  String travel_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# segments',
      one: '# segment',
      zero: 'No segments',
    );
    return '$_temp0';
  }

  @override
  String get action_save => 'Save';

  @override
  String get action_cancel => 'Cancel';

  @override
  String get action_delete => 'Delete';

  @override
  String get error_required => 'This field is required.';

  @override
  String get error_endBeforeStart => 'End must be after start.';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get routeSectionTitle => 'Route';

  @override
  String get routeTitle => 'Route';

  @override
  String get routeShowAll => 'Show all';

  @override
  String get routeToday => 'Today';

  @override
  String get routeTomorrow => 'Tomorrow';

  @override
  String get routeSeaDayLabel => 'Sea day (all day)';

  @override
  String get routePortCallLabel => 'Port call';

  @override
  String get routeChipToday => 'Today';

  @override
  String get routeChipTomorrow => 'Tomorrow';

  @override
  String get routeEmptyHint => 'No route entries yet.';

  @override
  String get routeAddFirstPortCta => 'Add first port call';

  @override
  String get routeAddTooltip => 'Add port call';

  @override
  String get routeWizardNewTitle => 'New port call';

  @override
  String get routeWizardEditTitle => 'Edit port call';

  @override
  String get routeWizardSwitchSeaDay => 'Sea day instead of port?';

  @override
  String get routeDateLabel => 'Date';

  @override
  String get routeArrivalTimeLabel => 'Arrival';

  @override
  String get routeDepartureTimeLabel => 'Departure';

  @override
  String get routePortNameLabel => 'Port name';

  @override
  String get routeCityLabel => 'City';

  @override
  String get routeCountryLabel => 'Country';

  @override
  String get routeTerminalLabel => 'Terminal / Pier';

  @override
  String get routeDescriptionLabel => 'Description';

  @override
  String get routeNotesLabel => 'Notes';

  @override
  String get routeSave => 'Save';

  @override
  String get routeCancel => 'Cancel';

  @override
  String get routeErrorRequired => 'This field is required.';

  @override
  String get routeErrorCityOrPort => 'Enter at least a city or a port name.';

  @override
  String get confirmDeleteTitle => 'Confirm delete';

  @override
  String get confirmDeleteMessage => 'Do you want to delete this Object?';
}
