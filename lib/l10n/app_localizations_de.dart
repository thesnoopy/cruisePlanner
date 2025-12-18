// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Kreuzfahrtplaner';

  @override
  String get homeTitle => 'Deine Reisen';

  @override
  String get homeNoCruises => 'Noch keine Reisen. Tippe auf +, um eine anzulegen.';

  @override
  String get homeNewCruiseLabel => 'Neue Kreuzfahrt';

  @override
  String get homeWebdavSettingsTooltip => 'WebDAV-Einstellungen';

  @override
  String get homeCloudSyncTooltip => 'Cloud-Sync';

  @override
  String get homeCloudSyncNoStore => 'Kein CruiseStore verfügbar – Sync nicht möglich.';

  @override
  String get homeCloudSyncNoWebdav => 'Bitte zuerst WebDAV-Einstellungen speichern.';

  @override
  String get homeCloudSyncDone => 'Cloud-Sync abgeschlossen.';

  @override
  String homeCloudSyncFailed(String error) {
    return 'Cloud-Sync fehlgeschlagen: $error';
  }

  @override
  String get homeDeleteTooltip => 'Löschen';

  @override
  String get cruisePlanner => 'Cruise Planer';

  @override
  String get ship => 'Schiff';

  @override
  String get cruise => 'Kreuzfahrt';

  @override
  String get route => 'Route';

  @override
  String get excursion => 'Ausflug';

  @override
  String get travel => 'An- Abreise';

  @override
  String get cruiseDetails => 'Kreuzfahrtdetails';

  @override
  String get unknownHarbour => 'Unbekannter Hafen';

  @override
  String get noHarbour => 'Keine Häfen für heute oder zukünftig';

  @override
  String get arrival => 'Ankunft';

  @override
  String get departure => 'Abfahrt';

  @override
  String get allOnBoard => 'Alle an Bord';

  @override
  String get noFutureExcursions => 'Keine kommenden Ausflüge';

  @override
  String get today => 'Heute';

  @override
  String get harbour => 'Hafen';

  @override
  String get meetingPoint => 'Treffpunkt';

  @override
  String get price => 'Preis';

  @override
  String get noTravelItem => 'Keine An- Abreise Teile';

  @override
  String get start => 'Start';

  @override
  String get end => 'Ende';

  @override
  String get from => 'Von';

  @override
  String get to => 'Nach';

  @override
  String get flight => 'Flug';

  @override
  String get train => 'Zug';

  @override
  String get transfer => 'Transfer';

  @override
  String get rentalCar => 'Mietwagen';

  @override
  String get flightnumber => 'Flugnummer';

  @override
  String get rentalCarCompany => 'Vermieter';

  @override
  String get title => 'Titel';

  @override
  String get requiredField => 'Pflichtfeld';

  @override
  String get chatterOptional => 'Reederei (optional)';

  @override
  String get save => 'Speichern';

  @override
  String get seaDay => 'Seetag';

  @override
  String get editPort => 'Hafen bearbeiten';

  @override
  String get editSeaDay => 'Seetag bearbeiten';

  @override
  String get date => 'Datum';

  @override
  String get arrivalOptional => 'Ankunft (optional)';

  @override
  String get departureOptional => 'Abfahrt (optional)';

  @override
  String get dateAndTime => 'Datum & Uhrzeit';

  @override
  String get allOnBoardOptional => 'Alle an Bord (optional)';

  @override
  String get notesOptional => 'Notizen (optional)';

  @override
  String get newExcursion => 'Neuer Ausflug';

  @override
  String get noPort => 'Kein Hafen';

  @override
  String get excursions => 'Ausflüge';

  @override
  String get editExcursion => 'Ausflug bearbeiten';

  @override
  String get currencyOptional => 'Währung (optional)';

  @override
  String get editTravel => 'Reise bearbeiten';

  @override
  String get airlineOptional => 'Fluggesellschaft (optional)';

  @override
  String get bookingNumberOptional => 'Buchungsnummer (optional)';

  @override
  String get modeOptional => 'Modus (optional)';

  @override
  String get editFlight => 'Flug bearbeiten';

  @override
  String get editTrain => 'Zugfahrt bearbeiten';

  @override
  String get editRentalCar => 'Mietwagen bearbeiten';

  @override
  String get editTransfer => 'An- Abreise bearbeiten';

  @override
  String get cruiseCheckIn => 'Kreuzfahrt Check-In';

  @override
  String get cruiseCheckOut => 'Kreuzfahrt Check-Out';

  @override
  String get hotel => 'Hotel';

  @override
  String get cabinNumber => 'Kabinen Nummer';

  @override
  String get deckNumber => 'Deck Nummer';

  @override
  String get deckname => 'Deck Name';

  @override
  String get deposit => 'Anzahlung';

  @override
  String get finalPayment => 'Restzahlung';

  @override
  String get noPaymentInformation => 'Keine Zahlungsinformationen hinterlegt';

  @override
  String get fullyPayed => 'Vollständig bezahlt';

  @override
  String get payOnBooking => 'Bei Buchung zu zahlen';

  @override
  String get stillOpen => 'noch offen';

  @override
  String get withoutDate => 'ohne Datum';

  @override
  String get payed => 'bezahlt';

  @override
  String get open => 'offen';

  @override
  String get onSide => 'vor Ort';

  @override
  String get amountPayableOnSide => 'Gesamter Betrag vor Ort zu zahlen';

  @override
  String get amountOnSide => 'Gesamter Betrag vor Ort';

  @override
  String get payment => 'Zahlung';

  @override
  String get paymentType => 'Zahlungsart';

  @override
  String get finalPaymentOnDate => 'Restzahlung zu Termin';

  @override
  String get finalPaymentOnSide => 'Restzahlung vor Ort';

  @override
  String get amountAlreadyPayed => 'Betrag bereits bezahlt';

  @override
  String get depositAlreadyPayed => 'Anzahlung bereits bezahlt';

  @override
  String get remainingAmountOptional => 'Restbetrag (optional)';

  @override
  String get leaveEmptyForAutomaticCalculation => 'Leer lassen, um aus Gesamtpreis - Anzahlung zu berechnen';

  @override
  String get remainingAmountDueUntill => 'Restzahlung fällig bis';

  @override
  String get noDateSelected => 'Kein Datum gewählt';

  @override
  String get remainingAmountAlreadyPaied => 'Restbetrag bereits bezahlt';

  @override
  String get remainingAmountOnSide => 'Restbetrag vor Ort';

  @override
  String get paymentTypesOnSide => 'Zahlungsarten vor Ort';

  @override
  String get cash => 'Bargeld';

  @override
  String get credit => 'Kreditkarte';

  @override
  String get cashCurrency => 'Bargeld-Währung';

  @override
  String get onlyLocalCurrency => 'Nur Landeswährung';

  @override
  String get localCurrencyOrOwnCurrency => 'Landeswährung oder eigene Währung';

  @override
  String get finalPaymentAlreadyPayed => 'Restbetrag bereits bezahlt';

  @override
  String get fullPaymentOnSide => 'Gesamter Betrag wird vor Ort bezahlt';

  @override
  String get confirmDefaultTitle => 'Bestätigung';

  @override
  String get confirmDefaultMessage => 'Möchtest du diese Aktion wirklich durchführen?';

  @override
  String get confirmOk => 'OK';

  @override
  String get confirmCancel => 'Abbrechen';

  @override
  String get deleteExcursionTitle => 'Ausflug löschen';

  @override
  String get deleteExcursionQuestionmark => 'Diesen Ausflug wirklich löschen?';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteCruiseTitle => 'Kreuzfahrt löschen';

  @override
  String get deleteCruiseQuestionmark => 'Diese Kreuzfahrt wirklich löschen?';

  @override
  String get deleteRouteItemTitle => 'Hafen / Seetag löschen';

  @override
  String get deleteRouteItemQuestionmark => 'Diesen Hafen / Seetag wirklich löschen?';

  @override
  String get deleteTravelItemTitle => 'Lösche An- Abreise Teil';

  @override
  String get deleteTravelItemQuestionmark => 'An- Abreiseteil löschen?';

  @override
  String get location => 'Adresse';
}
