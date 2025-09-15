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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cruise App'**
  String get appTitle;

  /// No description provided for @menuExcursions.
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get menuExcursions;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @cruises.
  ///
  /// In en, this message translates to:
  /// **'Cruises'**
  String get cruises;

  /// No description provided for @webDavConfigured.
  ///
  /// In en, this message translates to:
  /// **'WebDAV configured'**
  String get webDavConfigured;

  /// No description provided for @couldNotLoadData.
  ///
  /// In en, this message translates to:
  /// **'Could not load data: '**
  String get couldNotLoadData;

  /// No description provided for @pleaseEnterWebdavCredentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter WebDAV credentials'**
  String get pleaseEnterWebdavCredentials;

  /// No description provided for @uploadOk.
  ///
  /// In en, this message translates to:
  /// **'Upload (new) OK'**
  String get uploadOk;

  /// No description provided for @downloadOk.
  ///
  /// In en, this message translates to:
  /// **'Download OK'**
  String get downloadOk;

  /// No description provided for @remoteWasNewerEtag.
  ///
  /// In en, this message translates to:
  /// **'Remote was newer (ETag) → Download'**
  String get remoteWasNewerEtag;

  /// No description provided for @localWasNewerUpload.
  ///
  /// In en, this message translates to:
  /// **'Local was newer → Upload'**
  String get localWasNewerUpload;

  /// No description provided for @alreadyUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get alreadyUpToDate;

  /// No description provided for @remoteWasNewerDownload.
  ///
  /// In en, this message translates to:
  /// **'Remote was newer → Download'**
  String get remoteWasNewerDownload;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'SYNC ERROR: '**
  String get syncError;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: '**
  String get syncFailed;

  /// No description provided for @stored.
  ///
  /// In en, this message translates to:
  /// **'Saved: '**
  String get stored;

  /// No description provided for @storingFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: '**
  String get storingFailed;

  /// No description provided for @syncWithWebdav.
  ///
  /// In en, this message translates to:
  /// **'Sync with WebDAV'**
  String get syncWithWebdav;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @noCruiseYet.
  ///
  /// In en, this message translates to:
  /// **'No cruises yet. Tap +'**
  String get noCruiseYet;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'(no title)'**
  String get noTitle;

  /// No description provided for @pleaseCheckEntries.
  ///
  /// In en, this message translates to:
  /// **'Please check your entries'**
  String get pleaseCheckEntries;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get finished;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @wizardTitleNewCruise.
  ///
  /// In en, this message translates to:
  /// **'New Cruise'**
  String get wizardTitleNewCruise;

  /// No description provided for @cruiseTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get cruiseTitleLabel;

  /// No description provided for @cruiseTitleHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., Mediterranean 2026'**
  String get cruiseTitleHintText;

  /// No description provided for @titleMustNotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Title must not be empty'**
  String get titleMustNotBeEmpty;

  /// No description provided for @shipLabel.
  ///
  /// In en, this message translates to:
  /// **'Ship'**
  String get shipLabel;

  /// No description provided for @shipName.
  ///
  /// In en, this message translates to:
  /// **'Ship name'**
  String get shipName;

  /// No description provided for @shipNameHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., AIDAcosma'**
  String get shipNameHintText;

  /// No description provided for @pleaseEnterShipName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the ship name'**
  String get pleaseEnterShipName;

  /// No description provided for @cruiseCompany.
  ///
  /// In en, this message translates to:
  /// **'Cruise line'**
  String get cruiseCompany;

  /// No description provided for @cruiseCompanyHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., AIDA Cruises'**
  String get cruiseCompanyHintText;

  /// No description provided for @pleaseEnterCruiseCompany.
  ///
  /// In en, this message translates to:
  /// **'Please enter the cruise line'**
  String get pleaseEnterCruiseCompany;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get periodLabel;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @endMustAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date'**
  String get endMustAfterStart;

  /// Pluralized count label for excursions
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No excursions} =1{1 excursion} other{{count} excursions}}'**
  String excursionsCount(int count);

  /// No description provided for @createExcursion.
  ///
  /// In en, this message translates to:
  /// **'Create new excursion'**
  String get createExcursion;

  /// No description provided for @noExcursions.
  ///
  /// In en, this message translates to:
  /// **'No excursions yet'**
  String get noExcursions;

  /// No description provided for @deleteExcursion.
  ///
  /// In en, this message translates to:
  /// **'Delete excursion?'**
  String get deleteExcursion;

  /// No description provided for @reallyDelete.
  ///
  /// In en, this message translates to:
  /// **'Really delete?'**
  String get reallyDelete;

  /// Generic delete label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @changeExcursion.
  ///
  /// In en, this message translates to:
  /// **'Edit excursion'**
  String get changeExcursion;

  /// No description provided for @titleStar.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleStar;

  /// No description provided for @titelStarHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., Halifax city tour'**
  String get titelStarHintText;

  /// No description provided for @titleMustNotBEEmpty.
  ///
  /// In en, this message translates to:
  /// **'Title must not be empty.'**
  String get titleMustNotBEEmpty;

  /// No description provided for @mustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'Must be between '**
  String get mustBeBetween;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @lie.
  ///
  /// In en, this message translates to:
  /// **''**
  String get lie;

  /// No description provided for @harbourOptional.
  ///
  /// In en, this message translates to:
  /// **'Port (optional)'**
  String get harbourOptional;

  /// No description provided for @harbourOptionalHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., Halifax'**
  String get harbourOptionalHintText;

  /// No description provided for @meetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get meetingPoint;

  /// No description provided for @meetingPointHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., port exit'**
  String get meetingPointHintText;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @priceOptional.
  ///
  /// In en, this message translates to:
  /// **'Price (optional)'**
  String get priceOptional;

  /// No description provided for @priceOptionalHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., 49.90'**
  String get priceOptionalHintText;

  /// No description provided for @currencyOptional.
  ///
  /// In en, this message translates to:
  /// **'Currency (optional)'**
  String get currencyOptional;

  /// No description provided for @currencyOptionalHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., EUR, USD, CAD'**
  String get currencyOptionalHintText;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @connectionOk.
  ///
  /// In en, this message translates to:
  /// **'Connection OK'**
  String get connectionOk;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: '**
  String get connectionFailed;

  /// No description provided for @webdavSettings.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Settings'**
  String get webdavSettings;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @baseUrlHintText.
  ///
  /// In en, this message translates to:
  /// **'https://server/remote.php/dav/files/USERNAME/'**
  String get baseUrlHintText;

  /// No description provided for @pleaseEnterBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter the Base URL'**
  String get pleaseEnterBaseUrl;

  /// No description provided for @urlMustStartWithHttp.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http/https'**
  String get urlMustStartWithHttp;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter the username'**
  String get pleaseEnterUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter the password'**
  String get pleaseEnterPassword;

  /// No description provided for @remotePath.
  ///
  /// In en, this message translates to:
  /// **'Remote path'**
  String get remotePath;

  /// No description provided for @pleaseEnterPath.
  ///
  /// In en, this message translates to:
  /// **'Please enter the path'**
  String get pleaseEnterPath;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @excursionTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get excursionTitleLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @portLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// Label for notes/comments of an excursion
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// Label for the price of an excursion
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @tapToAddExcursion.
  ///
  /// In en, this message translates to:
  /// **'Tap to add an excursion'**
  String get tapToAddExcursion;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// Label with a formatted date injected by the UI
  ///
  /// In en, this message translates to:
  /// **'Excursion on {date}'**
  String excursionOn(String date);

  /// Card title for cruise details on the overview
  ///
  /// In en, this message translates to:
  /// **'Cruise details'**
  String get cruiseDetailsTitle;

  /// Static suffix after a number, e.g. '3 excursions planned'
  ///
  /// In en, this message translates to:
  /// **'excursions planned'**
  String get excursionsCountLabel;

  /// CTA text at the end of the cruise details card
  ///
  /// In en, this message translates to:
  /// **'See details'**
  String get seeDetailsCta;

  /// Card title for the next upcoming excursion
  ///
  /// In en, this message translates to:
  /// **'Next excursion'**
  String get nextExcursionTitle;

  /// Shown when there is no upcoming excursion
  ///
  /// In en, this message translates to:
  /// **'No excursion planned'**
  String get nonePlanned;

  /// Placeholder for missing/optional fields
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get dash;

  /// Chip label: total count (e.g., excursions total)
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get totalLabel;

  /// Chip label: count of future items
  ///
  /// In en, this message translates to:
  /// **'upcoming'**
  String get upcomingLabel;

  /// CTA text to open the excursion list
  ///
  /// In en, this message translates to:
  /// **'All excursions'**
  String get seeAllExcursionsCta;

  /// AppBar title of the excursion list
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get excursionsTitle;

  /// Generic label for create actions
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get addNew;

  /// Empty state text in the excursion list
  ///
  /// In en, this message translates to:
  /// **'No excursions yet.'**
  String get noExcursionsYet;

  /// AppBar title of the read-only excursion detail page
  ///
  /// In en, this message translates to:
  /// **'Excursion details'**
  String get excursionDetailsTitle;

  /// Label for the excursion meeting point
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get meetingPointLabel;

  /// Generic label for an edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Title of the delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete trip?'**
  String get deleteCruiseTitle;

  /// Question in the confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Really delete “{title}”?'**
  String deleteCruiseMessage(String title);

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirm;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteCancel;

  /// Snackbar after deletion
  ///
  /// In en, this message translates to:
  /// **'“{title}” deleted'**
  String deletedCruiseSnack(String title);

  /// Undo label in snackbars
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @travelSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrival & departure'**
  String get travelSectionTitle;

  /// No description provided for @travelEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No travel segments yet. Add your first segment.'**
  String get travelEmptyHint;

  /// No description provided for @travelShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get travelShowAll;

  /// No description provided for @travelAddNew.
  ///
  /// In en, this message translates to:
  /// **'New segment'**
  String get travelAddNew;

  /// No description provided for @travelChooseTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose type'**
  String get travelChooseTypeTitle;

  /// No description provided for @travelOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel plan'**
  String get travelOverviewTitle;

  /// No description provided for @travelOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'for {cruiseTitle}'**
  String travelOverviewSubtitle(String cruiseTitle);

  /// No description provided for @travelKind_flight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get travelKind_flight;

  /// No description provided for @travelKind_train.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get travelKind_train;

  /// No description provided for @travelKind_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get travelKind_transfer;

  /// No description provided for @travelKind_rentalCar.
  ///
  /// In en, this message translates to:
  /// **'Rental car'**
  String get travelKind_rentalCar;

  /// No description provided for @transferMode_shuttle.
  ///
  /// In en, this message translates to:
  /// **'Shuttle'**
  String get transferMode_shuttle;

  /// No description provided for @transferMode_taxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get transferMode_taxi;

  /// No description provided for @transferMode_privateDriver.
  ///
  /// In en, this message translates to:
  /// **'Private driver'**
  String get transferMode_privateDriver;

  /// No description provided for @transferMode_rideshare.
  ///
  /// In en, this message translates to:
  /// **'Rideshare'**
  String get transferMode_rideshare;

  /// No description provided for @label_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get label_from;

  /// No description provided for @label_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get label_to;

  /// No description provided for @label_pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get label_pickup;

  /// No description provided for @label_dropoff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get label_dropoff;

  /// No description provided for @label_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get label_start;

  /// No description provided for @label_end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get label_end;

  /// No description provided for @label_timeRange.
  ///
  /// In en, this message translates to:
  /// **'{start} → {end}'**
  String label_timeRange(String start, String end);

  /// No description provided for @label_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get label_price;

  /// No description provided for @label_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get label_currency;

  /// No description provided for @flight_airline.
  ///
  /// In en, this message translates to:
  /// **'Airline'**
  String get flight_airline;

  /// No description provided for @flight_number.
  ///
  /// In en, this message translates to:
  /// **'Flight No.'**
  String get flight_number;

  /// No description provided for @flight_bookingRef.
  ///
  /// In en, this message translates to:
  /// **'Booking ref.'**
  String get flight_bookingRef;

  /// No description provided for @flight_bookingClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get flight_bookingClass;

  /// No description provided for @flight_seat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get flight_seat;

  /// No description provided for @flight_terminalDep.
  ///
  /// In en, this message translates to:
  /// **'Terminal (dep.)'**
  String get flight_terminalDep;

  /// No description provided for @flight_terminalArr.
  ///
  /// In en, this message translates to:
  /// **'Terminal (arr.)'**
  String get flight_terminalArr;

  /// No description provided for @flight_baggagePieces.
  ///
  /// In en, this message translates to:
  /// **'Baggage pieces'**
  String get flight_baggagePieces;

  /// No description provided for @train_operator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get train_operator;

  /// No description provided for @train_number.
  ///
  /// In en, this message translates to:
  /// **'Train No.'**
  String get train_number;

  /// No description provided for @train_coach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get train_coach;

  /// No description provided for @train_seat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get train_seat;

  /// No description provided for @transfer_provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get transfer_provider;

  /// No description provided for @transfer_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get transfer_confirmation;

  /// No description provided for @transfer_pax.
  ///
  /// In en, this message translates to:
  /// **'Pax'**
  String get transfer_pax;

  /// No description provided for @rental_company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get rental_company;

  /// No description provided for @rental_reservation.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get rental_reservation;

  /// No description provided for @rental_vehicleClass.
  ///
  /// In en, this message translates to:
  /// **'Vehicle class'**
  String get rental_vehicleClass;

  /// No description provided for @rental_pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get rental_pickupLocation;

  /// No description provided for @rental_dropoffLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop-off location'**
  String get rental_dropoffLocation;

  /// No description provided for @travel_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No segments} one{# segment} other{# segments}}'**
  String travel_count(int count);

  /// No description provided for @action_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get action_save;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get action_delete;

  /// No description provided for @error_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get error_required;

  /// No description provided for @error_endBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End must be after start.'**
  String get error_endBeforeStart;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// Section header on Cruise Detail page for the itinerary route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeSectionTitle;

  /// AppBar title for the route detail page.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeTitle;

  /// Trailing action to open the full route list.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get routeShowAll;

  /// Label for today's route item.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get routeToday;

  /// Label for tomorrow's route item.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get routeTomorrow;

  /// Label used for a sea day entry.
  ///
  /// In en, this message translates to:
  /// **'Sea day (all day)'**
  String get routeSeaDayLabel;

  /// Generic label for a port call when no city/port is available.
  ///
  /// In en, this message translates to:
  /// **'Port call'**
  String get routePortCallLabel;

  /// Chip/badge text marking today's entry in the list.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get routeChipToday;

  /// Chip/badge text marking tomorrow's entry in the list.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get routeChipTomorrow;

  /// Placeholder text when the route list is empty.
  ///
  /// In en, this message translates to:
  /// **'No route entries yet.'**
  String get routeEmptyHint;

  /// Call-to-action button when the route list is empty.
  ///
  /// In en, this message translates to:
  /// **'Add first port call'**
  String get routeAddFirstPortCta;

  /// FAB tooltip on the route detail page.
  ///
  /// In en, this message translates to:
  /// **'Add port call'**
  String get routeAddTooltip;

  /// AppBar title for creating a new port call.
  ///
  /// In en, this message translates to:
  /// **'New port call'**
  String get routeWizardNewTitle;

  /// AppBar title for editing an existing port call.
  ///
  /// In en, this message translates to:
  /// **'Edit port call'**
  String get routeWizardEditTitle;

  /// Toggle to switch the form to a sea day entry.
  ///
  /// In en, this message translates to:
  /// **'Sea day instead of port?'**
  String get routeWizardSwitchSeaDay;

  /// Form label for the calendar date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get routeDateLabel;

  /// Form label for arrival time.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get routeArrivalTimeLabel;

  /// Form label for departure time.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get routeDepartureTimeLabel;

  /// Form label for the port name.
  ///
  /// In en, this message translates to:
  /// **'Port name'**
  String get routePortNameLabel;

  /// Form label for the city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get routeCityLabel;

  /// Form label for the country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get routeCountryLabel;

  /// Form label for the cruise terminal or pier.
  ///
  /// In en, this message translates to:
  /// **'Terminal / Pier'**
  String get routeTerminalLabel;

  /// Form label for a free-text description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get routeDescriptionLabel;

  /// Form label for optional notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get routeNotesLabel;

  /// Primary action to save the route item.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get routeSave;

  /// Secondary action to cancel the wizard.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get routeCancel;

  /// Generic required-field validation message.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get routeErrorRequired;

  /// Validation when both city and port name are empty.
  ///
  /// In en, this message translates to:
  /// **'Enter at least a city or a port name.'**
  String get routeErrorCityOrPort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
