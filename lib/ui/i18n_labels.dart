import 'package:cruiseplanner/gen/l10n/app_localizations.dart';
import '../models/travel.dart';

String travelKindLabel(TravelKind kind, AppLocalizations t) {
  switch (kind) {
    case TravelKind.flight:     return t.travelKind_flight;
    case TravelKind.train:      return t.travelKind_train;
    case TravelKind.transfer:   return t.travelKind_transfer;
    case TravelKind.rentalCar:  return t.travelKind_rentalCar;
  }
}

String transferModeLabel(TransferMode mode, AppLocalizations t) {
  switch (mode) {
    case TransferMode.shuttle:        return t.transferMode_shuttle;
    case TransferMode.taxi:           return t.transferMode_taxi;
    case TransferMode.privateDriver:  return t.transferMode_privateDriver;
    case TransferMode.rideshare:      return t.transferMode_rideshare;
  }
}
