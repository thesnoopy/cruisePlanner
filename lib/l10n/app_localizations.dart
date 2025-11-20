import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Main application title
  ///
  /// In en, this message translates to:
  /// **'Cruise Planner'**
  String get appTitle;

  /// Title of the home screen app bar
  ///
  /// In en, this message translates to:
  /// **'Your cruises'**
  String get homeTitle;

  /// Empty state text when there are no cruises
  ///
  /// In en, this message translates to:
  /// **'No cruises yet. Tap + to add one.'**
  String get homeNoCruises;

  /// Label of the FAB to add a cruise
  ///
  /// In en, this message translates to:
  /// **'New cruise'**
  String get homeNewCruiseLabel;

  /// Tooltip for the WebDAV settings icon button
  ///
  /// In en, this message translates to:
  /// **'WebDAV settings'**
  String get homeWebdavSettingsTooltip;

  /// Tooltip for the cloud sync icon button
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get homeCloudSyncTooltip;

  /// Snack bar message when store is null during sync
  ///
  /// In en, this message translates to:
  /// **'Cruise store not available – sync not possible.'**
  String get homeCloudSyncNoStore;

  /// Snack bar message when WebDAV is not configured
  ///
  /// In en, this message translates to:
  /// **'Please save WebDAV settings first.'**
  String get homeCloudSyncNoWebdav;

  /// Snack bar when cloud sync succeeded
  ///
  /// In en, this message translates to:
  /// **'Cloud sync finished.'**
  String get homeCloudSyncDone;

  /// Snack bar when cloud sync throws an exception
  ///
  /// In en, this message translates to:
  /// **'Cloud sync failed: {error}'**
  String homeCloudSyncFailed(String error);

  /// Edit Travel
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get homeDeleteTooltip;

  /// No description provided for @cruisePlanner.
  ///
  /// In en, this message translates to:
  /// **'Cruise Planer'**
  String get cruisePlanner;

  /// No description provided for @ship.
  ///
  /// In en, this message translates to:
  /// **'Ship'**
  String get ship;

  /// No description provided for @cruise.
  ///
  /// In en, this message translates to:
  /// **'Cruise'**
  String get cruise;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @excursion.
  ///
  /// In en, this message translates to:
  /// **'Shore excursion'**
  String get excursion;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @cruiseDetails.
  ///
  /// In en, this message translates to:
  /// **'Cruise Details'**
  String get cruiseDetails;

  /// No description provided for @unknownHarbour.
  ///
  /// In en, this message translates to:
  /// **'Unknown Harbour'**
  String get unknownHarbour;

  /// No description provided for @noHarbour.
  ///
  /// In en, this message translates to:
  /// **'Keine Harbour today or in Future'**
  String get noHarbour;

  /// No description provided for @arrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrival;

  /// No description provided for @departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departure;

  /// No description provided for @allOnBoard.
  ///
  /// In en, this message translates to:
  /// **'All on Board'**
  String get allOnBoard;

  /// No description provided for @noFutureExcursions.
  ///
  /// In en, this message translates to:
  /// **'No Excursion'**
  String get noFutureExcursions;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @harbour.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get harbour;

  /// No description provided for @meetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Meeting Point'**
  String get meetingPoint;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @noTravelItem.
  ///
  /// In en, this message translates to:
  /// **'No Travel Item'**
  String get noTravelItem;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @flight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get flight;

  /// No description provided for @train.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get train;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @rentalCar.
  ///
  /// In en, this message translates to:
  /// **'Rental Car'**
  String get rentalCar;

  /// No description provided for @flightnumber.
  ///
  /// In en, this message translates to:
  /// **'Flight Number'**
  String get flightnumber;

  /// No description provided for @rentalCarCompany.
  ///
  /// In en, this message translates to:
  /// **'Rental Car Company'**
  String get rentalCarCompany;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required Field'**
  String get requiredField;

  /// No description provided for @chatterOptional.
  ///
  /// In en, this message translates to:
  /// **'Chatter (optional)'**
  String get chatterOptional;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @seaDay.
  ///
  /// In en, this message translates to:
  /// **'Sea Day'**
  String get seaDay;

  /// No description provided for @editPort.
  ///
  /// In en, this message translates to:
  /// **'Edit Port'**
  String get editPort;

  /// No description provided for @editSeaDay.
  ///
  /// In en, this message translates to:
  /// **'Edit Seaday'**
  String get editSeaDay;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @arrivalOptional.
  ///
  /// In en, this message translates to:
  /// **'Arrival (optional)'**
  String get arrivalOptional;

  /// No description provided for @departureOptional.
  ///
  /// In en, this message translates to:
  /// **'Departure (optional)'**
  String get departureOptional;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateAndTime;

  /// No description provided for @allOnBoardOptional.
  ///
  /// In en, this message translates to:
  /// **'All on Board (optional)'**
  String get allOnBoardOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @newExcursion.
  ///
  /// In en, this message translates to:
  /// **'New Excursion'**
  String get newExcursion;

  /// No description provided for @noPort.
  ///
  /// In en, this message translates to:
  /// **'No Port'**
  String get noPort;

  /// No description provided for @excursions.
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get excursions;

  /// No description provided for @editExcursion.
  ///
  /// In en, this message translates to:
  /// **'Edit Excursion'**
  String get editExcursion;

  /// No description provided for @currencyOptional.
  ///
  /// In en, this message translates to:
  /// **'Currency (optional)'**
  String get currencyOptional;

  /// No description provided for @editTravel.
  ///
  /// In en, this message translates to:
  /// **'Edit Travel'**
  String get editTravel;

  /// No description provided for @airlineOptional.
  ///
  /// In en, this message translates to:
  /// **'Airline (optional)'**
  String get airlineOptional;

  /// No description provided for @bookingNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Booking number (optional)'**
  String get bookingNumberOptional;

  /// No description provided for @modeOptional.
  ///
  /// In en, this message translates to:
  /// **'Mode (optional)'**
  String get modeOptional;

  /// No description provided for @editFlight.
  ///
  /// In en, this message translates to:
  /// **'Edit Flight'**
  String get editFlight;

  /// No description provided for @editTrain.
  ///
  /// In en, this message translates to:
  /// **'Edit Train'**
  String get editTrain;

  /// No description provided for @editRentalCar.
  ///
  /// In en, this message translates to:
  /// **'Edit Rental Car'**
  String get editRentalCar;

  /// No description provided for @editTransfer.
  ///
  /// In en, this message translates to:
  /// **'Edit Travel'**
  String get editTransfer;

  /// Cruise Check-In
  ///
  /// In en, this message translates to:
  /// **'Cruise Check-In'**
  String get cruiseCheckIn;

  /// Cruise Check-Out
  ///
  /// In en, this message translates to:
  /// **'Cruise Check-Out'**
  String get cruiseCheckOut;

  /// Hotel
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get hotel;

  /// Cabin Number
  ///
  /// In en, this message translates to:
  /// **'Cabin Number'**
  String get cabinNumber;

  /// Deck Number
  ///
  /// In en, this message translates to:
  /// **'Deck Number'**
  String get deckNumber;

  /// Deck Name
  ///
  /// In en, this message translates to:
  /// **'Deck Name'**
  String get deckname;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
