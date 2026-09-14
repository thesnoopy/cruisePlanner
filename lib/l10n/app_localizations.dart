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

  /// Meldung bei fehlender oder gelöschter Kreuzfahrt
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrt nicht gefunden'**
  String get cruiseNotFound;

  /// Meldung bei einem Fehler beim Lesen der lokalen Kreuzfahrtdaten
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrt konnte nicht geladen werden. Bitte versuche es später erneut.'**
  String get cruiseLoadFailed;

  /// Haupttitel der App
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrtplaner'**
  String get appTitle;

  /// Titel der Home-Seite in der AppBar
  ///
  /// In de, this message translates to:
  /// **'Deine Reisen'**
  String get homeTitle;

  /// Text für den Leeres-Zustand auf dem Home Screen
  ///
  /// In de, this message translates to:
  /// **'Noch keine Reisen. Tippe auf +, um eine anzulegen.'**
  String get homeNoCruises;

  /// Label des FAB zum Anlegen einer neuen Reise
  ///
  /// In de, this message translates to:
  /// **'Neue Kreuzfahrt'**
  String get homeNewCruiseLabel;

  /// Tooltip für den WebDAV-Settings-Button
  ///
  /// In de, this message translates to:
  /// **'WebDAV-Einstellungen'**
  String get homeWebdavSettingsTooltip;

  /// Tooltip für den Cloud-Sync-Button
  ///
  /// In de, this message translates to:
  /// **'Cloud-Sync'**
  String get homeCloudSyncTooltip;

  /// SnackBar-Meldung, wenn der Store null ist
  ///
  /// In de, this message translates to:
  /// **'Kein CruiseStore verfügbar – Sync nicht möglich.'**
  String get homeCloudSyncNoStore;

  /// SnackBar-Meldung, wenn WebDAV noch nicht konfiguriert ist
  ///
  /// In de, this message translates to:
  /// **'Bitte zuerst WebDAV-Einstellungen speichern.'**
  String get homeCloudSyncNoWebdav;

  /// SnackBar-Meldung bei erfolgreichem Sync
  ///
  /// In de, this message translates to:
  /// **'Cloud-Sync abgeschlossen.'**
  String get homeCloudSyncDone;

  /// SnackBar-Meldung bei fehlerhaftem Sync
  ///
  /// In de, this message translates to:
  /// **'Cloud-Sync fehlgeschlagen: {error}'**
  String homeCloudSyncFailed(String error);

  /// An- Abreise bearbeiten
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get homeDeleteTooltip;

  /// No description provided for @ship.
  ///
  /// In de, this message translates to:
  /// **'Schiff'**
  String get ship;

  /// No description provided for @cruise.
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrt'**
  String get cruise;

  /// No description provided for @route.
  ///
  /// In de, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @excursion.
  ///
  /// In de, this message translates to:
  /// **'Ausflug'**
  String get excursion;

  /// No description provided for @travel.
  ///
  /// In de, this message translates to:
  /// **'An- Abreise'**
  String get travel;

  /// No description provided for @cruiseDetails.
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrtdetails'**
  String get cruiseDetails;

  /// No description provided for @unknownHarbour.
  ///
  /// In de, this message translates to:
  /// **'Unbekannter Hafen'**
  String get unknownHarbour;

  /// No description provided for @noHarbour.
  ///
  /// In de, this message translates to:
  /// **'Keine Häfen für heute oder zukünftig'**
  String get noHarbour;

  /// No description provided for @arrival.
  ///
  /// In de, this message translates to:
  /// **'Ankunft'**
  String get arrival;

  /// No description provided for @departure.
  ///
  /// In de, this message translates to:
  /// **'Abfahrt'**
  String get departure;

  /// No description provided for @allOnBoard.
  ///
  /// In de, this message translates to:
  /// **'Alle an Bord'**
  String get allOnBoard;

  /// No description provided for @noFutureExcursions.
  ///
  /// In de, this message translates to:
  /// **'Keine kommenden Ausflüge'**
  String get noFutureExcursions;

  /// No description provided for @noExcursions.
  ///
  /// In de, this message translates to:
  /// **'Keine Ausflüge'**
  String get noExcursions;

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @pastStatusIconSemanticLabel.
  ///
  /// In de, this message translates to:
  /// **'Vergangener Eintrag'**
  String get pastStatusIconSemanticLabel;

  /// No description provided for @harbour.
  ///
  /// In de, this message translates to:
  /// **'Hafen'**
  String get harbour;

  /// No description provided for @meetingPoint.
  ///
  /// In de, this message translates to:
  /// **'Treffpunkt'**
  String get meetingPoint;

  /// No description provided for @price.
  ///
  /// In de, this message translates to:
  /// **'Preis'**
  String get price;

  /// No description provided for @noTravelItem.
  ///
  /// In de, this message translates to:
  /// **'Keine An- Abreise Teile'**
  String get noTravelItem;

  /// No description provided for @start.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In de, this message translates to:
  /// **'Ende'**
  String get end;

  /// No description provided for @from.
  ///
  /// In de, this message translates to:
  /// **'Von'**
  String get from;

  /// No description provided for @to.
  ///
  /// In de, this message translates to:
  /// **'Nach'**
  String get to;

  /// No description provided for @flight.
  ///
  /// In de, this message translates to:
  /// **'Flug'**
  String get flight;

  /// No description provided for @train.
  ///
  /// In de, this message translates to:
  /// **'Zug'**
  String get train;

  /// No description provided for @transfer.
  ///
  /// In de, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @rentalCar.
  ///
  /// In de, this message translates to:
  /// **'Mietwagen'**
  String get rentalCar;

  /// No description provided for @flightnumber.
  ///
  /// In de, this message translates to:
  /// **'Flugnummer'**
  String get flightnumber;

  /// No description provided for @rentalCarCompany.
  ///
  /// In de, this message translates to:
  /// **'Vermieter'**
  String get rentalCarCompany;

  /// No description provided for @title.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get title;

  /// No description provided for @requiredField.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld'**
  String get requiredField;

  /// No description provided for @chatterOptional.
  ///
  /// In de, this message translates to:
  /// **'Reederei (optional)'**
  String get chatterOptional;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @seaDay.
  ///
  /// In de, this message translates to:
  /// **'Seetag'**
  String get seaDay;

  /// No description provided for @editPort.
  ///
  /// In de, this message translates to:
  /// **'Hafen bearbeiten'**
  String get editPort;

  /// No description provided for @editSeaDay.
  ///
  /// In de, this message translates to:
  /// **'Seetag bearbeiten'**
  String get editSeaDay;

  /// No description provided for @date.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get date;

  /// No description provided for @arrivalOptional.
  ///
  /// In de, this message translates to:
  /// **'Ankunft (optional)'**
  String get arrivalOptional;

  /// No description provided for @departureOptional.
  ///
  /// In de, this message translates to:
  /// **'Abfahrt (optional)'**
  String get departureOptional;

  /// No description provided for @dateAndTime.
  ///
  /// In de, this message translates to:
  /// **'Datum & Uhrzeit'**
  String get dateAndTime;

  /// No description provided for @allOnBoardOptional.
  ///
  /// In de, this message translates to:
  /// **'Alle an Bord (optional)'**
  String get allOnBoardOptional;

  /// No description provided for @notesOptional.
  ///
  /// In de, this message translates to:
  /// **'Notizen (optional)'**
  String get notesOptional;

  /// No description provided for @newExcursion.
  ///
  /// In de, this message translates to:
  /// **'Neuer Ausflug'**
  String get newExcursion;

  /// Hinweistext, wenn kein Hafen gesetzt ist
  ///
  /// In de, this message translates to:
  /// **'Kein Hafen'**
  String get noPort;

  /// Bezeichnung für einen einzelnen Ausflugsstopp
  ///
  /// In de, this message translates to:
  /// **'Stopp'**
  String get stop;

  /// Abschnittstitel für die bearbeitbare Liste der Ausflugsstopps
  ///
  /// In de, this message translates to:
  /// **'Stopps'**
  String get stops;

  /// Beschriftung für die Aktion zum Hinzufügen eines Ausflugsstopps
  ///
  /// In de, this message translates to:
  /// **'Stopp hinzufügen'**
  String get addStop;

  /// Eingabefeld für den Namen eines Ausflugsstopps
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get stopName;

  /// Checkbox für den Besuchsstatus eines Ausflugsstopps
  ///
  /// In de, this message translates to:
  /// **'Besucht'**
  String get visited;

  /// Hinweis, wenn der angeforderte Ausflug nicht geladen werden konnte
  ///
  /// In de, this message translates to:
  /// **'Ausflug nicht gefunden'**
  String get excursionNotFound;

  /// No description provided for @excursions.
  ///
  /// In de, this message translates to:
  /// **'Ausflüge'**
  String get excursions;

  /// No description provided for @editExcursion.
  ///
  /// In de, this message translates to:
  /// **'Ausflug bearbeiten'**
  String get editExcursion;

  /// No description provided for @currencyOptional.
  ///
  /// In de, this message translates to:
  /// **'Währung (optional)'**
  String get currencyOptional;

  /// No description provided for @editTravel.
  ///
  /// In de, this message translates to:
  /// **'Reise bearbeiten'**
  String get editTravel;

  /// Aktion zum Bearbeiten der Kreuzfahrt
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrt bearbeiten'**
  String get editCruise;

  /// No description provided for @airlineOptional.
  ///
  /// In de, this message translates to:
  /// **'Fluggesellschaft (optional)'**
  String get airlineOptional;

  /// No description provided for @modeOptional.
  ///
  /// In de, this message translates to:
  /// **'Modus (optional)'**
  String get modeOptional;

  /// Label für ein Unternehmen in der schreibgeschützten Reise-Detailansicht
  ///
  /// In de, this message translates to:
  /// **'Unternehmen'**
  String get travelCompany;

  /// Label für eine detaillierte Adresse in der schreibgeschützten Reise-Detailansicht
  ///
  /// In de, this message translates to:
  /// **'Adressdetails'**
  String get travelAddressDetails;

  /// Schreibgeschützte Bezeichnung für Transfermodus Shuttle
  ///
  /// In de, this message translates to:
  /// **'Shuttle'**
  String get transferModeShuttle;

  /// Schreibgeschützte Bezeichnung für Transfermodus Taxi
  ///
  /// In de, this message translates to:
  /// **'Taxi'**
  String get transferModeTaxi;

  /// Schreibgeschützte Bezeichnung für Transfermodus Privatfahrer
  ///
  /// In de, this message translates to:
  /// **'Privatfahrer'**
  String get transferModePrivateDriver;

  /// Schreibgeschützte Bezeichnung für Transfermodus Mitfahrdienst
  ///
  /// In de, this message translates to:
  /// **'Mitfahrdienst'**
  String get transferModeRideshare;

  /// No description provided for @bookingNumberOptional.
  ///
  /// In de, this message translates to:
  /// **'Buchungsnummer (optional)'**
  String get bookingNumberOptional;

  /// No description provided for @editFlight.
  ///
  /// In de, this message translates to:
  /// **'Flug bearbeiten'**
  String get editFlight;

  /// No description provided for @editTrain.
  ///
  /// In de, this message translates to:
  /// **'Zugfahrt bearbeiten'**
  String get editTrain;

  /// No description provided for @editRentalCar.
  ///
  /// In de, this message translates to:
  /// **'Mietwagen bearbeiten'**
  String get editRentalCar;

  /// No description provided for @editTransfer.
  ///
  /// In de, this message translates to:
  /// **'An- Abreise bearbeiten'**
  String get editTransfer;

  /// Kreuzfahrt Check-In
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrt Check-In'**
  String get cruiseCheckIn;

  /// Kreuzfahrt Check-Out
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrt Check-Out'**
  String get cruiseCheckOut;

  /// Hotel
  ///
  /// In de, this message translates to:
  /// **'Hotel'**
  String get hotel;

  /// Kabinen Nummer
  ///
  /// In de, this message translates to:
  /// **'Kabinen Nummer'**
  String get cabinNumber;

  /// Deck Nummer
  ///
  /// In de, this message translates to:
  /// **'Deck Nummer'**
  String get deckNumber;

  /// Deck Nummer
  ///
  /// In de, this message translates to:
  /// **'Deck Name'**
  String get deckname;

  /// Restzahlung
  ///
  /// In de, this message translates to:
  /// **'Anzahlung'**
  String get deposit;

  /// No description provided for @finalPayment.
  ///
  /// In de, this message translates to:
  /// **'Restzahlung'**
  String get finalPayment;

  /// Keine Zahlungsinformationen hinterlegt
  ///
  /// In de, this message translates to:
  /// **'Keine Zahlungsinformationen hinterlegt'**
  String get noPaymentInformation;

  /// Bei Buchung zu zahlen
  ///
  /// In de, this message translates to:
  /// **'Vollständig bezahlt'**
  String get fullyPayed;

  /// No description provided for @payOnBooking.
  ///
  /// In de, this message translates to:
  /// **'Bei Buchung zu zahlen'**
  String get payOnBooking;

  /// noch offen
  ///
  /// In de, this message translates to:
  /// **'noch offen'**
  String get stillOpen;

  /// ohne Datum
  ///
  /// In de, this message translates to:
  /// **'ohne Datum'**
  String get withoutDate;

  /// bezahlt
  ///
  /// In de, this message translates to:
  /// **'bezahlt'**
  String get payed;

  /// offen
  ///
  /// In de, this message translates to:
  /// **'offen'**
  String get open;

  /// vor Ort
  ///
  /// In de, this message translates to:
  /// **'vor Ort'**
  String get onSide;

  /// vor Ort
  ///
  /// In de, this message translates to:
  /// **'Gesamter Betrag vor Ort zu zahlen'**
  String get amountPayableOnSide;

  /// Gesamter Betrag vor Ort
  ///
  /// In de, this message translates to:
  /// **'Gesamter Betrag vor Ort'**
  String get amountOnSide;

  /// Zahlung
  ///
  /// In de, this message translates to:
  /// **'Zahlung'**
  String get payment;

  /// Zahlungsart
  ///
  /// In de, this message translates to:
  /// **'Zahlungsart'**
  String get paymentType;

  /// Restzahlung zu Termin
  ///
  /// In de, this message translates to:
  /// **'Restzahlung zu Termin'**
  String get finalPaymentOnDate;

  /// Restzahlung vor Ort
  ///
  /// In de, this message translates to:
  /// **'Restzahlung vor Ort'**
  String get finalPaymentOnSide;

  /// Restbetrag (optional)
  ///
  /// In de, this message translates to:
  /// **'Betrag bereits bezahlt'**
  String get amountAlreadyPayed;

  /// No description provided for @depositAlreadyPayed.
  ///
  /// In de, this message translates to:
  /// **'Anzahlung bereits bezahlt'**
  String get depositAlreadyPayed;

  /// No description provided for @remainingAmountOptional.
  ///
  /// In de, this message translates to:
  /// **'Restbetrag (optional)'**
  String get remainingAmountOptional;

  /// Leer lassen, um aus Gesamtpreis - Anzahlung zu berechnen
  ///
  /// In de, this message translates to:
  /// **'Leer lassen, um aus Gesamtpreis - Anzahlung zu berechnen'**
  String get leaveEmptyForAutomaticCalculation;

  /// Restzahlung fällig bis
  ///
  /// In de, this message translates to:
  /// **'Restzahlung fällig bis'**
  String get remainingAmountDueUntill;

  /// Kein Datum gewählt
  ///
  /// In de, this message translates to:
  /// **'Kein Datum gewählt'**
  String get noDateSelected;

  /// Restbetrag bereits bezahlt
  ///
  /// In de, this message translates to:
  /// **'Restbetrag bereits bezahlt'**
  String get remainingAmountAlreadyPaied;

  /// Restbetrag vor Ort
  ///
  /// In de, this message translates to:
  /// **'Restbetrag vor Ort'**
  String get remainingAmountOnSide;

  /// Zahlungsarten vor Ort
  ///
  /// In de, this message translates to:
  /// **'Zahlungsarten vor Ort'**
  String get paymentTypesOnSide;

  /// Bargeld
  ///
  /// In de, this message translates to:
  /// **'Bargeld'**
  String get cash;

  /// Kreditkarte
  ///
  /// In de, this message translates to:
  /// **'Kreditkarte'**
  String get credit;

  /// Bargeld-Währung
  ///
  /// In de, this message translates to:
  /// **'Bargeld-Währung'**
  String get cashCurrency;

  /// Nur Landeswährung
  ///
  /// In de, this message translates to:
  /// **'Nur Landeswährung'**
  String get onlyLocalCurrency;

  /// Landeswährung oder eigene Währung
  ///
  /// In de, this message translates to:
  /// **'Landeswährung oder eigene Währung'**
  String get localCurrencyOrOwnCurrency;

  /// No description provided for @finalPaymentAlreadyPayed.
  ///
  /// In de, this message translates to:
  /// **'Restbetrag bereits bezahlt'**
  String get finalPaymentAlreadyPayed;

  /// Gesamter Betrag wird vor Ort bezahlt
  ///
  /// In de, this message translates to:
  /// **'Gesamter Betrag wird vor Ort bezahlt'**
  String get fullPaymentOnSide;

  /// Standardtitel für generische Bestätigungsdialoge
  ///
  /// In de, this message translates to:
  /// **'Bestätigung'**
  String get confirmDefaultTitle;

  /// Standardtext für generische Bestätigungsdialoge
  ///
  /// In de, this message translates to:
  /// **'Möchtest du diese Aktion wirklich durchführen?'**
  String get confirmDefaultMessage;

  /// Standardtext für OK/Bestätigen-Button in generischen Dialogen
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get confirmOk;

  /// Standardtext für Abbrechen-Button in generischen Dialogen
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get confirmCancel;

  /// No description provided for @deleteExcursionTitle.
  ///
  /// In de, this message translates to:
  /// **'Ausflug löschen'**
  String get deleteExcursionTitle;

  /// No description provided for @deleteExcursionQuestionmark.
  ///
  /// In de, this message translates to:
  /// **'Diesen Ausflug wirklich löschen?'**
  String get deleteExcursionQuestionmark;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @deleteCruiseTitle.
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrt löschen'**
  String get deleteCruiseTitle;

  /// No description provided for @deleteCruiseQuestionmark.
  ///
  /// In de, this message translates to:
  /// **'Diese Kreuzfahrt wirklich löschen?'**
  String get deleteCruiseQuestionmark;

  /// No description provided for @deleteRouteItemTitle.
  ///
  /// In de, this message translates to:
  /// **'Hafen / Seetag löschen'**
  String get deleteRouteItemTitle;

  /// No description provided for @deleteRouteItemQuestionmark.
  ///
  /// In de, this message translates to:
  /// **'Diesen Hafen / Seetag wirklich löschen?'**
  String get deleteRouteItemQuestionmark;

  /// No description provided for @deleteTravelItemTitle.
  ///
  /// In de, this message translates to:
  /// **'Lösche An- Abreise Teil'**
  String get deleteTravelItemTitle;

  /// No description provided for @deleteTravelItemQuestionmark.
  ///
  /// In de, this message translates to:
  /// **'An- Abreiseteil löschen?'**
  String get deleteTravelItemQuestionmark;

  /// No description provided for @location.
  ///
  /// In de, this message translates to:
  /// **'Adresse'**
  String get location;

  /// No description provided for @startNavigation.
  ///
  /// In de, this message translates to:
  /// **'Navigation starten'**
  String get startNavigation;

  /// Abschnittstitel für verknüpfte Dokumente
  ///
  /// In de, this message translates to:
  /// **'Dokumente'**
  String get documents;

  /// Aktion zum Verknüpfen eines bestehenden Dokuments
  ///
  /// In de, this message translates to:
  /// **'Vorhandenes Dokument verknüpfen'**
  String get attachExistingDocument;

  /// Aktion zum Importieren eines neuen Dokuments für die aktuelle Kreuzfahrt
  ///
  /// In de, this message translates to:
  /// **'Dokument importieren'**
  String get importDocument;

  /// Allgemeiner Leerzustand, wenn keine Dokumente verknüpft sind
  ///
  /// In de, this message translates to:
  /// **'Keine verknüpften Dokumente.'**
  String get noLinkedDocuments;

  /// Leerzustand, wenn keine Dokumente mit der Kreuzfahrt verknüpft sind
  ///
  /// In de, this message translates to:
  /// **'Dieser Kreuzfahrt sind noch keine Dokumente zugeordnet.'**
  String get noLinkedDocumentsForCruise;

  /// Leerzustand, wenn keine Dokumente mit dem Ausflug verknüpft sind
  ///
  /// In de, this message translates to:
  /// **'Diesem Ausflug sind noch keine Dokumente zugeordnet.'**
  String get noLinkedDocumentsForExcursion;

  /// Leerzustand, wenn keine unverknüpften Dokumente verfügbar sind
  ///
  /// In de, this message translates to:
  /// **'Keine vorhandenen Dokumente zum Verknüpfen verfügbar.'**
  String get noAvailableDocumentsToAttach;

  /// Tooltip zum Lösen einer Dokumentverknüpfung
  ///
  /// In de, this message translates to:
  /// **'Dokument lösen'**
  String get detachDocument;

  /// SnackBar nach dem Verknüpfen eines Dokuments
  ///
  /// In de, this message translates to:
  /// **'Dokument verknüpft.'**
  String get documentAttached;

  /// SnackBar nach dem Importieren und Verknüpfen eines Dokuments
  ///
  /// In de, this message translates to:
  /// **'Dokument importiert.'**
  String get documentImported;

  /// SnackBar nach dem Verknüpfen eines bereits vorhandenen passenden Dokuments statt erneutem Import
  ///
  /// In de, this message translates to:
  /// **'Vorhandenes Dokument verknüpft.'**
  String get documentLinkedExisting;

  /// SnackBar, wenn das passende Dokument bereits mit dem aktuellen Ziel verknüpft ist
  ///
  /// In de, this message translates to:
  /// **'Dokument bereits verknüpft.'**
  String get documentAlreadyLinked;

  /// SnackBar, wenn Import oder Verknüpfen eines Dokuments fehlschlägt
  ///
  /// In de, this message translates to:
  /// **'Dokumentimport fehlgeschlagen.'**
  String get documentImportFailed;

  /// SnackBar, wenn ein verknüpftes Dokument nicht geöffnet werden kann
  ///
  /// In de, this message translates to:
  /// **'Dokument konnte nicht geöffnet werden.'**
  String get documentOpenFailed;

  /// Titel des Screens zum manuellen Speichern einer Webseite als PDF
  ///
  /// In de, this message translates to:
  /// **'Webseite als PDF speichern'**
  String get urlSnapshotTitle;

  /// Kurzer Hilfetext für den URL-Snapshot-Screen
  ///
  /// In de, this message translates to:
  /// **'Lade die gewünschte Webseite in der App. Wenn der sichtbare Stand passt, speichere ihn als PDF-Dokument.'**
  String get urlSnapshotHint;

  /// Beschriftung des URL-Eingabefelds im URL-Snapshot-Screen
  ///
  /// In de, this message translates to:
  /// **'URL'**
  String get urlSnapshotUrlLabel;

  /// Aktion zum Laden einer URL im URL-Snapshot-Screen
  ///
  /// In de, this message translates to:
  /// **'Webseite öffnen'**
  String get urlSnapshotOpen;

  /// Aktion zum Neuladen der aktuell geöffneten URL im URL-Snapshot-Screen
  ///
  /// In de, this message translates to:
  /// **'Neu laden'**
  String get urlSnapshotReload;

  /// Primäre Aktion zum Speichern des sichtbaren WebView-Inhalts als PDF
  ///
  /// In de, this message translates to:
  /// **'Als PDF speichern'**
  String get urlSnapshotSaveAsPdf;

  /// Kurzes Label für die Dokument-Sektionsaktion zum Starten des URL-Snapshot-Flows
  ///
  /// In de, this message translates to:
  /// **'URL als PDF'**
  String get urlSnapshotSaveAsPdfShort;

  /// Fehlermeldung, wenn keine gültige URL für den URL-Snapshot vorliegt
  ///
  /// In de, this message translates to:
  /// **'Bitte eine gültige URL angeben.'**
  String get urlSnapshotMissingUrl;

  /// Fehlermeldung, wenn noch keine geladene Seite für den Snapshot vorliegt
  ///
  /// In de, this message translates to:
  /// **'Die Seite ist noch nicht geladen und kann noch nicht als PDF gespeichert werden.'**
  String get urlSnapshotPageNotLoaded;

  /// Generische Fehlermeldung bei Ladefehlern im URL-Snapshot-Screen
  ///
  /// In de, this message translates to:
  /// **'Die Webseite konnte nicht geladen werden.'**
  String get urlSnapshotLoadFailed;

  /// Generische Fehlermeldung bei fehlgeschlagener PDF-Erzeugung oder Dokumentanlage
  ///
  /// In de, this message translates to:
  /// **'Das PDF konnte nicht gespeichert werden.'**
  String get urlSnapshotSaveFailed;

  /// Hinweis, wenn URL-Snapshots auf der aktuellen Plattform nicht unterstützt werden
  ///
  /// In de, this message translates to:
  /// **'Diese Funktion ist derzeit nur auf Android und iOS verfügbar.'**
  String get urlSnapshotUnsupportedPlatform;

  /// Bezeichnung für PDF-Dokumente
  ///
  /// In de, this message translates to:
  /// **'PDF'**
  String get documentKindPdf;

  /// Bezeichnung für E-Mail-Dokumente
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get documentKindEmail;

  /// Bezeichnung für Bilddokumente
  ///
  /// In de, this message translates to:
  /// **'Bild'**
  String get documentKindImage;

  /// Fallback-Bezeichnung für unbekannte Dokumenttypen
  ///
  /// In de, this message translates to:
  /// **'Dokument'**
  String get documentKindUnknown;

  /// Titel der kompakten Karte für ausstehende geteilte Inhalte
  ///
  /// In de, this message translates to:
  /// **'Geteilte Inhalte warten'**
  String get sharePendingTitle;

  /// Zusammenfassung ausstehender Share-Stapel und Elemente
  ///
  /// In de, this message translates to:
  /// **'{batchCount} Stapel mit {itemCount} Elementen warten.'**
  String sharePendingSummary(int batchCount, int itemCount);

  /// Kurzinfo zum zuletzt empfangenen ausstehenden Share-Inhalt
  ///
  /// In de, this message translates to:
  /// **'Zuletzt: {summary}'**
  String sharePendingLatest(String summary);

  /// Aktion zum Öffnen des Pending-Share-Review-Screens
  ///
  /// In de, this message translates to:
  /// **'Ansehen'**
  String get sharePendingReviewAction;

  /// Aktion zum Entfernen aller ausstehenden Share-Inhalte
  ///
  /// In de, this message translates to:
  /// **'Alle entfernen'**
  String get sharePendingClearAllAction;

  /// Kurzinfo für einen Share-Stapel mit mehr als einem Element
  ///
  /// In de, this message translates to:
  /// **'{label} und {count} weitere'**
  String sharePendingAdditionalItems(String label, int count);

  /// Titel des Pending-Share-Review-Screens
  ///
  /// In de, this message translates to:
  /// **'Geteilte Inhalte'**
  String get shareReviewTitle;

  /// Leerzustand für den Pending-Share-Review-Screen
  ///
  /// In de, this message translates to:
  /// **'Aktuell gibt es keine ausstehenden geteilten Inhalte.'**
  String get shareReviewEmpty;

  /// Titel für einen einzelnen Share-Stapel im Review-Screen
  ///
  /// In de, this message translates to:
  /// **'{itemCount} geteilte Elemente'**
  String shareReviewBatchTitle(int itemCount);

  /// Zeitstempel für einen empfangenen Share-Stapel
  ///
  /// In de, this message translates to:
  /// **'Empfangen {receivedAt}'**
  String shareReviewReceivedAt(String receivedAt);

  /// Aktion zum Entfernen eines einzelnen ausstehenden Share-Stapels
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get shareReviewClearBatchAction;

  /// Aktion zum Starten der Zuweisung eines geteilten Elements zu einem bestehenden Ziel
  ///
  /// In de, this message translates to:
  /// **'Zuweisen'**
  String get shareAssignAction;

  /// Titel des Screens für die Zuweisung geteilter Elemente
  ///
  /// In de, this message translates to:
  /// **'Geteiltes Element zuweisen'**
  String get shareAssignTitle;

  /// Hilfstext über der Liste der Zuweisungsziele
  ///
  /// In de, this message translates to:
  /// **'Wähle aus, wohin dieses geteilte Element zugeordnet werden soll.'**
  String get shareAssignSelectTarget;

  /// Hinweis für noch nicht unterstützte Typen geteilter Inhalte
  ///
  /// In de, this message translates to:
  /// **'Dieser Typ geteilter Inhalte kann in diesem Schritt noch nicht zugewiesen werden.'**
  String get shareAssignUnsupported;

  /// Kurze deaktivierte Aktionsbeschriftung für noch nicht unterstützte Share-Typen
  ///
  /// In de, this message translates to:
  /// **'Noch nicht unterstützt'**
  String get shareAssignUnsupportedShort;

  /// Hinweis, wenn ein geteiltes Element während der Zuweisung nicht mehr gefunden wird
  ///
  /// In de, this message translates to:
  /// **'Dieses geteilte Element ist nicht mehr verfügbar.'**
  String get shareAssignItemUnavailable;

  /// Hinweis, wenn noch keine bestehenden Ziele für eine Zuweisung vorhanden sind
  ///
  /// In de, this message translates to:
  /// **'Es sind noch keine zuweisbaren Ziele verfügbar.'**
  String get shareAssignNoTargets;

  /// Titel für die Auswahl, wie eine geteilte URL zugeordnet werden soll
  ///
  /// In de, this message translates to:
  /// **'Wie soll diese URL hinzugefügt werden?'**
  String get shareAssignUrlOptionsTitle;

  /// Hilfetext für die Auswahl im URL-Zuweisungsdialog
  ///
  /// In de, this message translates to:
  /// **'Du kannst den Link als Dokument anhängen oder zusätzlich die Webseite öffnen und den sichtbaren Stand als PDF speichern.'**
  String get shareAssignUrlOptionsHint;

  /// Aktion, um eine geteilte URL nur als Link-Dokument anzuhängen
  ///
  /// In de, this message translates to:
  /// **'Nur Link hinzufügen'**
  String get shareAssignAddLinkOnly;

  /// Aktion, um eine geteilte URL anzuhängen und zusätzlich als PDF zu speichern
  ///
  /// In de, this message translates to:
  /// **'Link hinzufügen und PDF speichern'**
  String get shareAssignAddLinkAndSavePdf;

  /// Hinweis vor dem Einstieg in den URL-Snapshot-Flow aus dem Share-Screen
  ///
  /// In de, this message translates to:
  /// **'Die Webseite wird geöffnet. Prüfe den sichtbaren Stand und speichere sie dann als PDF.'**
  String get shareAssignUrlOpenBeforeSaveHint;

  /// Erfolgsmeldung nach dem Anhängen einer geteilten URL als Link und PDF
  ///
  /// In de, this message translates to:
  /// **'Link und PDF gespeichert.'**
  String get shareAssignUrlAndPdfSaved;

  /// Titel des dedizierten Screens fÃ¼r den Synchronisationsfortschritt
  ///
  /// In de, this message translates to:
  /// **'Synchronisationsfortschritt'**
  String get syncProgressTitle;

  /// Ãœberschrift, solange eine Synchronisierung aktiv ist
  ///
  /// In de, this message translates to:
  /// **'Synchronisierung läuft'**
  String get syncProgressRunning;

  /// Kurzer Hilfstext, solange der Sync aktiv ist
  ///
  /// In de, this message translates to:
  /// **'Die aktuelle Synchronisierung läuft im Hintergrund weiter.'**
  String get syncProgressRunningDescription;

  /// Ãœberschrift nach erfolgreichem Abschluss
  ///
  /// In de, this message translates to:
  /// **'Synchronisierung abgeschlossen'**
  String get syncProgressCompleted;

  /// Kurzer Hilfstext nach erfolgreichem Sync
  ///
  /// In de, this message translates to:
  /// **'Alle Synchronisierungsschritte wurden erfolgreich abgeschlossen.'**
  String get syncProgressCompletedDescription;

  /// Ãœberschrift, wenn der Sync Ã¼bersprungen wurde
  ///
  /// In de, this message translates to:
  /// **'Synchronisierung übersprungen'**
  String get syncProgressSkipped;

  /// Kurzer Hilfstext, wenn der Sync wegen fehlender Einstellungen Ã¼bersprungen wurde
  ///
  /// In de, this message translates to:
  /// **'Die WebDAV-Einstellungen fehlen oder sind unvollständig.'**
  String get syncProgressSkippedDescription;

  /// Ãœberschrift nach fehlgeschlagenem Sync
  ///
  /// In de, this message translates to:
  /// **'Synchronisierung fehlgeschlagen'**
  String get syncProgressFailed;

  /// Kurzer Hilfstext nach fehlgeschlagenem Sync
  ///
  /// In de, this message translates to:
  /// **'Die Synchronisierung wurde mit Fehlern beendet.'**
  String get syncProgressFailedDescription;

  /// Sync-Phase fÃ¼r Vorbereitung und EinstellungsprÃ¼fung
  ///
  /// In de, this message translates to:
  /// **'Einstellungen prüfen'**
  String get syncProgressPreparing;

  /// Sync-Phase fÃ¼r die Synchronisierung der Cruise-JSON
  ///
  /// In de, this message translates to:
  /// **'Kreuzfahrtdaten synchronisieren'**
  String get syncProgressCruiseDataSync;

  /// Sync-Phase fÃ¼r Dokumentanalyse und Metadatenabgleich
  ///
  /// In de, this message translates to:
  /// **'Dokument-Metadaten analysieren'**
  String get syncProgressDocumentMetadataAnalysis;

  /// Sync-Phase fÃ¼r Dokument-Uploads
  ///
  /// In de, this message translates to:
  /// **'Dokumente hochladen'**
  String get syncProgressDocumentUploads;

  /// Sync-Phase fÃ¼r Dokument-Downloads
  ///
  /// In de, this message translates to:
  /// **'Dokumente herunterladen'**
  String get syncProgressDocumentDownloads;

  /// Sync-Phase fÃ¼r lokale Dokument-Wiederherstellung
  ///
  /// In de, this message translates to:
  /// **'Lokale Dokumentdateien wiederherstellen'**
  String get syncProgressLocalDocumentRecovery;

  /// Sync-Phase fÃ¼r Delete-Propagation
  ///
  /// In de, this message translates to:
  /// **'Löschungen übertragen'**
  String get syncProgressDeletionPropagation;

  /// Sync-Phase fÃ¼r Cleanup
  ///
  /// In de, this message translates to:
  /// **'Gelöschte Dokumente bereinigen'**
  String get syncProgressCleanup;

  /// Optionale Elementanzahl neben einer Sync-Phase
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one {1 Element} other {{count} Elemente}}'**
  String syncProgressItemCount(int count);

  /// Beschriftung des SchlieÃŸen-Buttons im Sync-Fortschrittsscreen
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get syncProgressClose;

  /// No description provided for @cruiseLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort'**
  String get cruiseLocation;

  /// No description provided for @cruiseRouteLocations.
  ///
  /// In de, this message translates to:
  /// **'Orte dieser Kreuzfahrt'**
  String get cruiseRouteLocations;

  /// No description provided for @cruiseOtherLocations.
  ///
  /// In de, this message translates to:
  /// **'Weitere Orte'**
  String get cruiseOtherLocations;

  /// No description provided for @cruiseCreateLocation.
  ///
  /// In de, this message translates to:
  /// **'Neuen Ort anlegen'**
  String get cruiseCreateLocation;

  /// No description provided for @cruiseSelectLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort auswählen'**
  String get cruiseSelectLocation;

  /// No description provided for @cruiseLocationName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get cruiseLocationName;

  /// No description provided for @cruiseLocationNameRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Namen eingeben'**
  String get cruiseLocationNameRequired;

  /// No description provided for @cruiseLocationType.
  ///
  /// In de, this message translates to:
  /// **'Typ'**
  String get cruiseLocationType;

  /// No description provided for @cruiseLocationStopPoint.
  ///
  /// In de, this message translates to:
  /// **'Zwischenstopp'**
  String get cruiseLocationStopPoint;

  /// No description provided for @cruiseLocationSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Ort konnte nicht gespeichert werden. Bitte erneut versuchen.'**
  String get cruiseLocationSaveFailed;
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
