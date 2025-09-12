// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Kreuzfahrt App';

  @override
  String get menuExcursions => 'Ausflüge';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get cruises => 'Kreuzfahrten';

  @override
  String get webDavConfigured => 'WebDAV konfiguriert';

  @override
  String get couldNotLoadData => 'Konnte Daten nicht laden: ';

  @override
  String get pleaseEnterWebdavCredentials =>
      'Bitte WebDAV-Zugangsdaten hinterlegen';

  @override
  String get uploadOk => 'Upload (neu) ok';

  @override
  String get downloadOk => 'Download ok';

  @override
  String get remoteWasNewerEtag => 'Remote war neuer (ETag) → Download';

  @override
  String get localWasNewerUpload => 'Lokal war neuer → Upload';

  @override
  String get alreadyUpToDate => 'Bereits aktuell';

  @override
  String get remoteWasNewerDownload => 'Remote war neuer → Download';

  @override
  String get syncError => 'SYNC ERROR: ';

  @override
  String get syncFailed => 'Sync fehlgeschlagen: ';

  @override
  String get stored => 'Gespeichert: ';

  @override
  String get storingFailed => 'Speichern fehlgeschlagen: ';

  @override
  String get syncWithWebdav => 'Mit WebDAV synchronisieren';

  @override
  String get settings => 'Einstellungen';

  @override
  String get noCruiseYet => 'Noch keine Cruises. Tippe auf +';

  @override
  String get noTitle => '(ohne Titel)';

  @override
  String get pleaseCheckEntries => 'Bitte Eingaben prüfen';

  @override
  String get finished => 'Fertig';

  @override
  String get next => 'Weiter';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get back => 'Zurück';

  @override
  String get wizardTitleNewCruise => 'Neue Kreuzfahrt';

  @override
  String get cruiseTitleLabel => 'Titel';

  @override
  String get cruiseTitleHintText => 'z. B. Mittelmeer 2026';

  @override
  String get titleMustNotBeEmpty => 'Titel darf nicht leer sein';

  @override
  String get shipLabel => 'Schiff';

  @override
  String get shipName => 'Schiffsname';

  @override
  String get shipNameHintText => 'z. B. AIDAcosma';

  @override
  String get pleaseEnterShipName => 'Bitte Schiffsname angeben';

  @override
  String get cruiseCompany => 'Reederei';

  @override
  String get cruiseCompanyHintText => 'z. B. AIDA Cruises';

  @override
  String get pleaseEnterCruiseCompany => 'Bitte Reederei angeben';

  @override
  String get periodLabel => 'Zeitraum';

  @override
  String get startDate => 'Startdatum';

  @override
  String get endDate => 'Enddatum';

  @override
  String get endMustAfterStart => 'Ende darf nicht vor Start liegen';

  @override
  String excursionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausflüge',
      one: '1 Ausflug',
      zero: 'Keine Ausflüge',
    );
    return '$_temp0';
  }

  @override
  String get createExcursion => 'Neuen Ausflug anlegen';

  @override
  String get noExcursions => 'Noch keine Ausflüge';

  @override
  String get deleteExcursion => '\'Ausflug löschen?';

  @override
  String get reallyDelete => ' wirklich löschen?';

  @override
  String get delete => 'Löschen';

  @override
  String get changeExcursion => 'Ausflug bearbeiten';

  @override
  String get titleStar => 'Titel *';

  @override
  String get titelStarHintText => 'z.B. Stadtrundgang Halifax';

  @override
  String get titleMustNotBEEmpty => 'Titel darf nicht leer sein.';

  @override
  String get mustBeBetween => 'Muss zwischen ';

  @override
  String get and => ' und ';

  @override
  String get lie => 'liegen';

  @override
  String get harbourOptional => 'Hafen (optional)';

  @override
  String get harbourOptionalHintText => 'z.B. Halifax';

  @override
  String get meetingPoint => 'Treffpunkt';

  @override
  String get meetingPointHintText => 'z.B. Hafenausgang';

  @override
  String get notesOptional => 'Notizen (optional)';

  @override
  String get priceOptional => 'Preis (optional)';

  @override
  String get priceOptionalHintText => 'z.B. 49.90';

  @override
  String get currencyOptional => 'Währung (optional)';

  @override
  String get currencyOptionalHintText => 'z.B. EUR, USD, CAD';

  @override
  String get store => 'Speichern';

  @override
  String get create => 'Anlegen';

  @override
  String get connectionOk => 'Verbindung ok';

  @override
  String get connectionFailed => 'Verbindung fehlgeschlagen: ';

  @override
  String get webdavSettings => 'WebDAV Einstellungen';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get baseUrlHintText => 'https://server/remote.php/dav/files/USERNAME/';

  @override
  String get pleaseEnterBaseUrl => 'Bitte Base URL angeben';

  @override
  String get urlMustStartWithHttp => 'URL muss mit http/https beginnen';

  @override
  String get username => 'Username';

  @override
  String get pleaseEnterUsername => 'Bitte Username angeben';

  @override
  String get password => 'Passwort';

  @override
  String get pleaseEnterPassword => 'Bitte Passwort angeben';

  @override
  String get remotePath => 'Remote Pfad';

  @override
  String get pleaseEnterPath => 'Bitte Pfad angeben';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get excursionTitleLabel => 'Titel';

  @override
  String get dateLabel => 'Datum';

  @override
  String get portLabel => 'Hafen';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get priceLabel => 'Preis';

  @override
  String get currencyLabel => 'Währung';

  @override
  String get tapToAddExcursion => 'Tippe, um einen Ausflug hinzuzufügen';

  @override
  String get validationRequired => 'Dieses Feld ist erforderlich';

  @override
  String get invalidPrice => 'Ungültiger Preis';

  @override
  String excursionOn(String date) {
    return 'Ausflug am $date';
  }

  @override
  String get cruiseDetailsTitle => 'Cruise-Details';

  @override
  String get excursionsCountLabel => 'Ausflüge geplant';

  @override
  String get seeDetailsCta => 'Details ansehen';

  @override
  String get nextExcursionTitle => 'Nächster Ausflug';

  @override
  String get nonePlanned => 'Kein Ausflug geplant';

  @override
  String get dash => '—';

  @override
  String get totalLabel => 'gesamt';

  @override
  String get upcomingLabel => 'zukünftig';

  @override
  String get seeAllExcursionsCta => 'Alle Ausflüge';

  @override
  String get excursionsTitle => 'Ausflüge';

  @override
  String get addNew => 'Neu hinzufügen';

  @override
  String get noExcursionsYet => 'Noch keine Ausflüge.';

  @override
  String get excursionDetailsTitle => 'Ausflugdetails';

  @override
  String get meetingPointLabel => 'Treffpunkt';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get deleteCruiseTitle => 'Reise löschen?';

  @override
  String deleteCruiseMessage(String title) {
    return '„$title“ wirklich löschen?';
  }

  @override
  String get deleteConfirm => 'Löschen';

  @override
  String get deleteCancel => 'Abbrechen';

  @override
  String deletedCruiseSnack(String title) {
    return '„$title“ gelöscht';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String get travelSectionTitle => 'An- & Abreise';

  @override
  String get travelEmptyHint =>
      'Noch keine Segmente vorhanden. Lege dein erstes Segment an.';

  @override
  String get travelShowAll => 'Alle anzeigen';

  @override
  String get travelAddNew => 'Neues Segment';

  @override
  String get travelChooseTypeTitle => 'Typ auswählen';

  @override
  String get travelOverviewTitle => 'Reiseplan';

  @override
  String travelOverviewSubtitle(String cruiseTitle) {
    return 'für $cruiseTitle';
  }

  @override
  String get travelKind_flight => 'Flug';

  @override
  String get travelKind_train => 'Bahn';

  @override
  String get travelKind_transfer => 'Transfer';

  @override
  String get travelKind_rentalCar => 'Mietwagen';

  @override
  String get transferMode_shuttle => 'Shuttle';

  @override
  String get transferMode_taxi => 'Taxi';

  @override
  String get transferMode_privateDriver => 'Privatfahrer';

  @override
  String get transferMode_rideshare => 'Ride-Sharing';

  @override
  String get label_from => 'Von';

  @override
  String get label_to => 'Nach';

  @override
  String get label_pickup => 'Abholung';

  @override
  String get label_dropoff => 'Rückgabe';

  @override
  String get label_start => 'Start';

  @override
  String get label_end => 'Ende';

  @override
  String label_timeRange(String start, String end) {
    return '$start → $end';
  }

  @override
  String get label_price => 'Preis';

  @override
  String get label_currency => 'Währung';

  @override
  String get flight_airline => 'Fluggesellschaft';

  @override
  String get flight_number => 'Flugnr.';

  @override
  String get flight_bookingRef => 'Buchungsnr.';

  @override
  String get flight_bookingClass => 'Klasse';

  @override
  String get flight_seat => 'Sitz';

  @override
  String get flight_terminalDep => 'Terminal (Abflug)';

  @override
  String get flight_terminalArr => 'Terminal (Ankunft)';

  @override
  String get flight_baggagePieces => 'Gepäckstücke';

  @override
  String get train_operator => 'Betreiber';

  @override
  String get train_number => 'Zugnr.';

  @override
  String get train_coach => 'Wagen';

  @override
  String get train_seat => 'Platz';

  @override
  String get transfer_provider => 'Anbieter';

  @override
  String get transfer_confirmation => 'Bestätigung';

  @override
  String get transfer_pax => 'Personen';

  @override
  String get rental_company => 'Vermieter';

  @override
  String get rental_reservation => 'Reservierung';

  @override
  String get rental_vehicleClass => 'Fahrzeugklasse';

  @override
  String get rental_pickupLocation => 'Abholort';

  @override
  String get rental_dropoffLocation => 'Rückgabeort';

  @override
  String travel_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# Segmente',
      one: '# Segment',
      zero: 'Keine Segmente',
    );
    return '$_temp0';
  }

  @override
  String get action_save => 'Speichern';

  @override
  String get action_cancel => 'Abbrechen';

  @override
  String get action_delete => 'Löschen';

  @override
  String get error_required => 'Pflichtfeld.';

  @override
  String get error_endBeforeStart => 'Ende muss nach dem Start liegen.';

  @override
  String get savedSuccessfully => 'Erfolgreich gespeichert';
}
