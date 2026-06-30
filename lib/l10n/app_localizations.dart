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
  /// **'Itinerary'**
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
  /// **'No Harbour today or in Future'**
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

  /// No description provided for @pastStatusIconSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Past item'**
  String get pastStatusIconSemanticLabel;

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
  /// **'Departure'**
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
  /// **'Transfer service'**
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

  /// Label for a single excursion stop
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Section title for the editable excursion stops list
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get stops;

  /// Button label to add a new excursion stop
  ///
  /// In en, this message translates to:
  /// **'Add stop'**
  String get addStop;

  /// Input label for the excursion stop name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get stopName;

  /// Checkbox label indicating whether an excursion stop was visited
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get visited;

  /// Message shown when the requested excursion could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Excursion not found'**
  String get excursionNotFound;

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

  /// No description provided for @editCruise.
  ///
  /// In en, this message translates to:
  /// **'Edit Cruise'**
  String get editCruise;

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

  /// Label for a company associated with a travel item in read-only detail view
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get travelCompany;

  /// Label for a detailed address shown for a travel item in read-only detail view
  ///
  /// In en, this message translates to:
  /// **'Address details'**
  String get travelAddressDetails;

  /// Read-only label for transfer mode shuttle
  ///
  /// In en, this message translates to:
  /// **'Shuttle'**
  String get transferModeShuttle;

  /// Read-only label for transfer mode taxi
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get transferModeTaxi;

  /// Read-only label for transfer mode private driver
  ///
  /// In en, this message translates to:
  /// **'Private Driver'**
  String get transferModePrivateDriver;

  /// Read-only label for transfer mode rideshare
  ///
  /// In en, this message translates to:
  /// **'Rideshare'**
  String get transferModeRideshare;

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
  /// **'Deck name'**
  String get deckname;

  /// Final Payment
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @finalPayment.
  ///
  /// In en, this message translates to:
  /// **'Final Payment'**
  String get finalPayment;

  /// No payment information
  ///
  /// In en, this message translates to:
  /// **'No payment information'**
  String get noPaymentInformation;

  /// Pay on Booking
  ///
  /// In en, this message translates to:
  /// **'Fully paied'**
  String get fullyPayed;

  /// No description provided for @payOnBooking.
  ///
  /// In en, this message translates to:
  /// **'Pay on Booking'**
  String get payOnBooking;

  /// still open
  ///
  /// In en, this message translates to:
  /// **'still open'**
  String get stillOpen;

  /// without Date
  ///
  /// In en, this message translates to:
  /// **'without Date'**
  String get withoutDate;

  /// payed
  ///
  /// In en, this message translates to:
  /// **'payed'**
  String get payed;

  /// open
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get open;

  /// on side
  ///
  /// In en, this message translates to:
  /// **'on side'**
  String get onSide;

  /// The total amount is payable on-site
  ///
  /// In en, this message translates to:
  /// **'The total amount is payable on-site'**
  String get amountPayableOnSide;

  /// The total amount is on-site
  ///
  /// In en, this message translates to:
  /// **'The total amount is on-site'**
  String get amountOnSide;

  /// Payment
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// Payment Type
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get paymentType;

  /// Final Payment on Date
  ///
  /// In en, this message translates to:
  /// **'Final Payment on Date'**
  String get finalPaymentOnDate;

  /// Final Payment on Side
  ///
  /// In en, this message translates to:
  /// **'Final Payment on Side'**
  String get finalPaymentOnSide;

  /// Remaining amount (optional)
  ///
  /// In en, this message translates to:
  /// **'Amount already paied'**
  String get amountAlreadyPayed;

  /// No description provided for @depositAlreadyPayed.
  ///
  /// In en, this message translates to:
  /// **'Deposit already paied'**
  String get depositAlreadyPayed;

  /// No description provided for @remainingAmountOptional.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount (optional)'**
  String get remainingAmountOptional;

  /// Leave empty for automatic calculation
  ///
  /// In en, this message translates to:
  /// **'Leave empty for automatic calculation'**
  String get leaveEmptyForAutomaticCalculation;

  /// remaining amount due untill
  ///
  /// In en, this message translates to:
  /// **'remaining amount due untill'**
  String get remainingAmountDueUntill;

  /// No date selected
  ///
  /// In en, this message translates to:
  /// **'No date selected'**
  String get noDateSelected;

  /// remaining amount already paied
  ///
  /// In en, this message translates to:
  /// **'remaining amount already paied'**
  String get remainingAmountAlreadyPaied;

  /// Remaining amount on side
  ///
  /// In en, this message translates to:
  /// **'Remaining amount on side'**
  String get remainingAmountOnSide;

  /// Payment types on side
  ///
  /// In en, this message translates to:
  /// **'Payment types on side'**
  String get paymentTypesOnSide;

  /// Cash
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Credit
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// Cash-currency
  ///
  /// In en, this message translates to:
  /// **'Cash-currency'**
  String get cashCurrency;

  /// Only local currency
  ///
  /// In en, this message translates to:
  /// **'Only local currency'**
  String get onlyLocalCurrency;

  /// Final payment already paied
  ///
  /// In en, this message translates to:
  /// **'Local currency or own currency'**
  String get localCurrencyOrOwnCurrency;

  /// No description provided for @finalPaymentAlreadyPayed.
  ///
  /// In en, this message translates to:
  /// **'Final payment already paied'**
  String get finalPaymentAlreadyPayed;

  /// Full payment on side
  ///
  /// In en, this message translates to:
  /// **'Full payment on side'**
  String get fullPaymentOnSide;

  /// Default title for generic confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmDefaultTitle;

  /// Default message for generic confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'Do you want to proceed?'**
  String get confirmDefaultMessage;

  /// Default OK/confirm button label for generic dialogs
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirmOk;

  /// Default cancel button label for generic dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get confirmCancel;

  /// No description provided for @deleteExcursionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Excursion'**
  String get deleteExcursionTitle;

  /// No description provided for @deleteExcursionQuestionmark.
  ///
  /// In en, this message translates to:
  /// **'Really delete excursion?'**
  String get deleteExcursionQuestionmark;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get delete;

  /// No description provided for @deleteCruiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Cruise'**
  String get deleteCruiseTitle;

  /// No description provided for @deleteCruiseQuestionmark.
  ///
  /// In en, this message translates to:
  /// **'Really delete this cruise?'**
  String get deleteCruiseQuestionmark;

  /// No description provided for @deleteRouteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Port / Seeday'**
  String get deleteRouteItemTitle;

  /// No description provided for @deleteRouteItemQuestionmark.
  ///
  /// In en, this message translates to:
  /// **'Really delete this Port / Seeday?'**
  String get deleteRouteItemQuestionmark;

  /// No description provided for @deleteTravelItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete travel item'**
  String get deleteTravelItemTitle;

  /// No description provided for @deleteTravelItemQuestionmark.
  ///
  /// In en, this message translates to:
  /// **'Really delete this travel item?'**
  String get deleteTravelItemQuestionmark;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get location;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get startNavigation;

  /// Section title for linked documents
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// Action label to attach an existing document
  ///
  /// In en, this message translates to:
  /// **'Attach existing document'**
  String get attachExistingDocument;

  /// Action label to import a new document for the current cruise
  ///
  /// In en, this message translates to:
  /// **'Import document'**
  String get importDocument;

  /// Generic empty state when no documents are linked
  ///
  /// In en, this message translates to:
  /// **'No linked documents.'**
  String get noLinkedDocuments;

  /// Empty state when no documents are linked to the cruise
  ///
  /// In en, this message translates to:
  /// **'No documents linked to this cruise yet.'**
  String get noLinkedDocumentsForCruise;

  /// Empty state when no documents are linked to the excursion in edit mode
  ///
  /// In en, this message translates to:
  /// **'No documents linked to this excursion yet.'**
  String get noLinkedDocumentsForExcursion;

  /// Empty state when there are no unattached documents available
  ///
  /// In en, this message translates to:
  /// **'No existing documents are available to attach.'**
  String get noAvailableDocumentsToAttach;

  /// Tooltip for detaching a linked document
  ///
  /// In en, this message translates to:
  /// **'Detach document'**
  String get detachDocument;

  /// Snack bar shown after attaching a document
  ///
  /// In en, this message translates to:
  /// **'Document attached.'**
  String get documentAttached;

  /// Snack bar shown after importing and attaching a document
  ///
  /// In en, this message translates to:
  /// **'Document imported.'**
  String get documentImported;

  /// Snack bar shown after linking an existing matching document instead of importing again
  ///
  /// In en, this message translates to:
  /// **'Existing document linked.'**
  String get documentLinkedExisting;

  /// Snack bar shown when the matching document is already linked to the current target
  ///
  /// In en, this message translates to:
  /// **'Document already linked.'**
  String get documentAlreadyLinked;

  /// Snack bar shown when importing or attaching a document fails
  ///
  /// In en, this message translates to:
  /// **'Document import failed.'**
  String get documentImportFailed;

  /// Snack bar shown when opening a linked document fails
  ///
  /// In en, this message translates to:
  /// **'Document could not be opened.'**
  String get documentOpenFailed;

  /// Label for PDF documents
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get documentKindPdf;

  /// Label for email documents
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get documentKindEmail;

  /// Label for image documents
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get documentKindImage;

  /// Fallback label for unknown document kinds
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentKindUnknown;

  /// Title for the lightweight pending share handoff card
  ///
  /// In en, this message translates to:
  /// **'Pending shared items'**
  String get sharePendingTitle;

  /// Summary of pending share batches and items
  ///
  /// In en, this message translates to:
  /// **'{batchCount} batches waiting with {itemCount} items.'**
  String sharePendingSummary(int batchCount, int itemCount);

  /// Summary of the latest pending shared content
  ///
  /// In en, this message translates to:
  /// **'Latest: {summary}'**
  String sharePendingLatest(String summary);

  /// Action to open the pending share review screen
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get sharePendingReviewAction;

  /// Action to clear all pending shared items
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get sharePendingClearAllAction;

  /// Summary for a batch with more than one item
  ///
  /// In en, this message translates to:
  /// **'{label} and {count} more'**
  String sharePendingAdditionalItems(String label, int count);

  /// Title of the pending share review screen
  ///
  /// In en, this message translates to:
  /// **'Shared items'**
  String get shareReviewTitle;

  /// Empty state for the pending share review screen
  ///
  /// In en, this message translates to:
  /// **'No pending shared items right now.'**
  String get shareReviewEmpty;

  /// Title for a single batch in the pending share review screen
  ///
  /// In en, this message translates to:
  /// **'{itemCount} shared items'**
  String shareReviewBatchTitle(int itemCount);

  /// Timestamp label for a received shared batch
  ///
  /// In en, this message translates to:
  /// **'Received {receivedAt}'**
  String shareReviewReceivedAt(String receivedAt);

  /// Action to clear a single pending share batch
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get shareReviewClearBatchAction;

  /// Action to start assigning a pending shared item to an existing target
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get shareAssignAction;

  /// Title of the pending share assignment screen
  ///
  /// In en, this message translates to:
  /// **'Assign shared item'**
  String get shareAssignTitle;

  /// Helper text above the list of assignment targets
  ///
  /// In en, this message translates to:
  /// **'Choose where this shared item should go.'**
  String get shareAssignSelectTarget;

  /// Message shown when a pending shared item is not yet supported by the assignment flow
  ///
  /// In en, this message translates to:
  /// **'This shared item type cannot be assigned yet.'**
  String get shareAssignUnsupported;

  /// Short disabled action label for unsupported pending shared item types
  ///
  /// In en, this message translates to:
  /// **'Not yet supported'**
  String get shareAssignUnsupportedShort;

  /// Message shown when a pending shared item cannot be found anymore during assignment
  ///
  /// In en, this message translates to:
  /// **'This shared item is no longer available.'**
  String get shareAssignItemUnavailable;

  /// Message shown when there are no existing cruise targets to assign a shared item to
  ///
  /// In en, this message translates to:
  /// **'No assignable targets are available yet.'**
  String get shareAssignNoTargets;

  /// Title of the dedicated sync progress screen
  ///
  /// In en, this message translates to:
  /// **'Sync progress'**
  String get syncProgressTitle;

  /// Headline while a sync is still running
  ///
  /// In en, this message translates to:
  /// **'Synchronization in progress'**
  String get syncProgressRunning;

  /// Short helper text while sync is active
  ///
  /// In en, this message translates to:
  /// **'The current synchronization is continuing in the background.'**
  String get syncProgressRunningDescription;

  /// Headline after sync finished successfully
  ///
  /// In en, this message translates to:
  /// **'Synchronization completed'**
  String get syncProgressCompleted;

  /// Short helper text after successful sync
  ///
  /// In en, this message translates to:
  /// **'All synchronization steps completed successfully.'**
  String get syncProgressCompletedDescription;

  /// Headline after sync was skipped
  ///
  /// In en, this message translates to:
  /// **'Synchronization skipped'**
  String get syncProgressSkipped;

  /// Short helper text when sync was skipped because settings are not usable
  ///
  /// In en, this message translates to:
  /// **'WebDAV settings are missing or incomplete.'**
  String get syncProgressSkippedDescription;

  /// Headline after sync finished with failures
  ///
  /// In en, this message translates to:
  /// **'Synchronization failed'**
  String get syncProgressFailed;

  /// Short helper text after failed sync
  ///
  /// In en, this message translates to:
  /// **'Synchronization ended with errors.'**
  String get syncProgressFailedDescription;

  /// Sync stage for preparing and validating settings
  ///
  /// In en, this message translates to:
  /// **'Checking settings'**
  String get syncProgressPreparing;

  /// Sync stage for cruise JSON synchronization
  ///
  /// In en, this message translates to:
  /// **'Synchronizing cruise data'**
  String get syncProgressCruiseDataSync;

  /// Sync stage for document analysis and metadata reconciliation
  ///
  /// In en, this message translates to:
  /// **'Analyzing document metadata'**
  String get syncProgressDocumentMetadataAnalysis;

  /// Sync stage for document uploads
  ///
  /// In en, this message translates to:
  /// **'Uploading documents'**
  String get syncProgressDocumentUploads;

  /// Sync stage for document downloads
  ///
  /// In en, this message translates to:
  /// **'Downloading documents'**
  String get syncProgressDocumentDownloads;

  /// Sync stage for local document recovery
  ///
  /// In en, this message translates to:
  /// **'Recovering local document files'**
  String get syncProgressLocalDocumentRecovery;

  /// Sync stage for deletion propagation
  ///
  /// In en, this message translates to:
  /// **'Propagating deletions'**
  String get syncProgressDeletionPropagation;

  /// Sync stage for cleanup
  ///
  /// In en, this message translates to:
  /// **'Cleaning up deleted documents'**
  String get syncProgressCleanup;

  /// Optional item count shown next to a sync stage
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String syncProgressItemCount(int count);

  /// Close button label on the sync progress screen
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get syncProgressClose;
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
