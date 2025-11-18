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
}
