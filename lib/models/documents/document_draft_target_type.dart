enum DocumentDraftTargetType {
  cruise,
  excursion,
  portCall,
  seaDay,
  flight,
  train,
  transfer,
  rentalCar,
  hotel,
  cruiseCheckIn,
  cruiseCheckOut,
  documentOnly,
  unknown,
}

extension DocumentDraftTargetTypeX on DocumentDraftTargetType {
  bool get isRouteItemTarget =>
      this == DocumentDraftTargetType.portCall ||
      this == DocumentDraftTargetType.seaDay;

  bool get isTravelTarget =>
      this == DocumentDraftTargetType.flight ||
      this == DocumentDraftTargetType.train ||
      this == DocumentDraftTargetType.transfer ||
      this == DocumentDraftTargetType.rentalCar ||
      this == DocumentDraftTargetType.hotel ||
      this == DocumentDraftTargetType.cruiseCheckIn ||
      this == DocumentDraftTargetType.cruiseCheckOut;
}
