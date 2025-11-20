import 'package:flutter/foundation.dart';

/// Haupttypen für An-/Abreise
enum TravelKind { flight, train, transfer, rentalCar, hotel, cruiseCheckIn, cruiseCheckOut }

/// Untermodus für Transfer
enum TransferMode { shuttle, taxi, privateDriver, rideshare }

/// Abstrakte Basisklasse für alle Travel-Items.
/// - Polymorph serialisiert mit dem Discriminator `type`.
/// - UI-Formatierung (Date/Price) passiert bewusst NICHT hier.
abstract class TravelItem {
  final String id;         // UUID
  final TravelKind type;
  final DateTime start;    // lokaler Startzeitpunkt
  final DateTime? end;     // optional, falls bekannt
  final String? from;      // Freitext (IATA, Bahnhof, Adresse, "Hotel ...")
  final String? to;        // Freitext
  final String? notes;
  final num? price;
  final String? currency;  // ISO 4217, z.B. "EUR", "USD"

  const TravelItem({
    required this.id,
    required this.type,
    required this.start,
    this.end,
    this.from,
    this.to,
    this.notes,
    this.price,
    this.currency,
  });

  /// Identifier für Kurzansichten (z.B. "LH401", "ICE 713", "Sixt").
  String summaryId();

  /// Serialisierung inklusive Discriminator.
  Map<String, dynamic> toMap();

  /// Fabrik: baut die richtige Subklasse auf Basis des `type`.
  static TravelItem fromMap(Map<String, dynamic> j) {
    final String t = (j['type'] as String).toLowerCase();
    switch (t) {
      case 'flight':
        return FlightItem.fromMap(j);
      case 'train':
        return TrainItem.fromMap(j);
      case 'transfer':
        return TransferItem.fromMap(j);
      case 'rentalcar':
        return RentalCarItem.fromMap(j);
      default:
        throw ArgumentError('Unknown TravelItem type: $t');
    }
  }

  /// Hilfsparser für ISO Datumsfelder
  @protected
  static DateTime? _parseNullableDate(dynamic v) {
    if (v == null) return null;
    return DateTime.parse(v as String);
  }
}

/// ------------------------------
/// Flug
/// ------------------------------
class FlightItem extends TravelItem {
  final String airline;         // "Lufthansa"
  final String flightNumber;    // "LH401"
  final String? bookingRef;     // PNR
  final String? bookingClass;   // "Y" / "J"
  final String? seat;           // "14A"
  final String? depTerminal;    // "T1"
  final String? arrTerminal;    // "T2"
  final int? baggagePieces;     // 0..n

  const FlightItem({
    required super.id,
    required super.start,
    super.end,
    super.from,
    super.to,
    super.notes,
    super.price,
    super.currency,
    required this.airline,
    required this.flightNumber,
    this.bookingRef,
    this.bookingClass,
    this.seat,
    this.depTerminal,
    this.arrTerminal,
    this.baggagePieces,
  }) : super(
          type: TravelKind.flight,
        );

  @override
  String summaryId() => flightNumber;

  @override
  Map<String, dynamic> toMap() => {
        'type': 'flight',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'from': from,
        'to': to,
        'notes': notes,
        'price': price,
        'currency': currency,
        'airline': airline,
        'flightNumber': flightNumber,
        'bookingRef': bookingRef,
        'bookingClass': bookingClass,
        'seat': seat,
        'depTerminal': depTerminal,
        'arrTerminal': arrTerminal,
        'baggagePieces': baggagePieces,
      };

  static FlightItem fromMap(Map<String, dynamic> j) => FlightItem(
        id: j['id'] as String,
        start: DateTime.parse(j['start'] as String),
        end: TravelItem._parseNullableDate(j['end']),
        from: j['from'] as String?,
        to: j['to'] as String?,
        notes: j['notes'] as String?,
        price: j['price'] as num?,
        currency: j['currency'] as String?,
        airline: j['airline'] as String,
        flightNumber: j['flightNumber'] as String,
        bookingRef: j['bookingRef'] as String?,
        bookingClass: j['bookingClass'] as String?,
        seat: j['seat'] as String?,
        depTerminal: j['depTerminal'] as String?,
        arrTerminal: j['arrTerminal'] as String?,
        baggagePieces: j['baggagePieces'] as int?,
      );

  FlightItem copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency,
    String? airline,
    String? flightNumber,
    String? bookingRef,
    String? bookingClass,
    String? seat,
    String? depTerminal,
    String? arrTerminal,
    int? baggagePieces,
  }) {
    return FlightItem(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      from: from ?? this.from,
      to: to ?? this.to,
      notes: notes ?? this.notes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      airline: airline ?? this.airline,
      flightNumber: flightNumber ?? this.flightNumber,
      bookingRef: bookingRef ?? this.bookingRef,
      bookingClass: bookingClass ?? this.bookingClass,
      seat: seat ?? this.seat,
      depTerminal: depTerminal ?? this.depTerminal,
      arrTerminal: arrTerminal ?? this.arrTerminal,
      baggagePieces: baggagePieces ?? this.baggagePieces,
    );
  }
}

/// ------------------------------
/// Bahn
/// ------------------------------
class TrainItem extends TravelItem {
  final String operatorName;    // "DB"
  final String trainNumber;     // "ICE 713"
  final String? coach;          // Wagen
  final String? seat;           // Platz

  const TrainItem({
    required super.id,
    required super.start,
    super.end,
    super.from,
    super.to,
    super.notes,
    super.price,
    super.currency,
    required this.operatorName,
    required this.trainNumber,
    this.coach,
    this.seat,
  }) : super(
          type: TravelKind.train,
        );

  @override
  String summaryId() => trainNumber;

  @override
  Map<String, dynamic> toMap() => {
        'type': 'train',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'from': from,
        'to': to,
        'notes': notes,
        'price': price,
        'currency': currency,
        'operatorName': operatorName,
        'trainNumber': trainNumber,
        'coach': coach,
        'seat': seat,
      };

  static TrainItem fromMap(Map<String, dynamic> j) => TrainItem(
        id: j['id'] as String,
        start: DateTime.parse(j['start'] as String),
        end: TravelItem._parseNullableDate(j['end']),
        from: j['from'] as String?,
        to: j['to'] as String?,
        notes: j['notes'] as String?,
        price: j['price'] as num?,
        currency: j['currency'] as String?,
        operatorName: j['operatorName'] as String,
        trainNumber: j['trainNumber'] as String,
        coach: j['coach'] as String?,
        seat: j['seat'] as String?,
      );

  TrainItem copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency,
    String? operatorName,
    String? trainNumber,
    String? coach,
    String? seat,
  }) {
    return TrainItem(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      from: from ?? this.from,
      to: to ?? this.to,
      notes: notes ?? this.notes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      operatorName: operatorName ?? this.operatorName,
      trainNumber: trainNumber ?? this.trainNumber,
      coach: coach ?? this.coach,
      seat: seat ?? this.seat,
    );
  }
}

/// ------------------------------
/// Transfer (Shuttle/Taxi/Privat)
/// ------------------------------
class TransferItem extends TravelItem {
  final String provider;        // "Uber", "Hotel Shuttle"
  final TransferMode mode;
  final String? confirmation;   // Buchungsnr.
  final int? pax;               // Personenanzahl

  const TransferItem({
    required super.id,
    required super.start,
    super.end,
    super.from,
    super.to,
    super.notes,
    super.price,
    super.currency,
    required this.provider,
    required this.mode,
    this.confirmation,
    this.pax,
  }) : super(
          type: TravelKind.transfer,
        );

  @override
  String summaryId() => provider;

  @override
  Map<String, dynamic> toMap() => {
        'type': 'transfer',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'from': from,
        'to': to,
        'notes': notes,
        'price': price,
        'currency': currency,
        'provider': provider,
        'mode': mode.name,
        'confirmation': confirmation,
        'pax': pax,
      };

  static TransferItem fromMap(Map<String, dynamic> j) => TransferItem(
        id: j['id'] as String,
        start: DateTime.parse(j['start'] as String),
        end: TravelItem._parseNullableDate(j['end']),
        from: j['from'] as String?,
        to: j['to'] as String?,
        notes: j['notes'] as String?,
        price: j['price'] as num?,
        currency: j['currency'] as String?,
        provider: j['provider'] as String,
        mode: TransferMode.values
            .firstWhere((m) => m.name == (j['mode'] as String)),
        confirmation: j['confirmation'] as String?,
        pax: j['pax'] as int?,
      );

  TransferItem copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency,
    String? provider,
    TransferMode? mode,
    String? confirmation,
    int? pax,
  }) {
    return TransferItem(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      from: from ?? this.from,
      to: to ?? this.to,
      notes: notes ?? this.notes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      provider: provider ?? this.provider,
      mode: mode ?? this.mode,
      confirmation: confirmation ?? this.confirmation,
      pax: pax ?? this.pax,
    );
  }
}

/// ------------------------------
/// Mietwagen
/// ------------------------------
class RentalCarItem extends TravelItem {
  final String company;         // "Sixt"
  final String? reservation;    // Reservierungsnr.
  final String? vehicleClass;   // "Intermediate SUV"
  final String? pickupLocation; // Freitext/Code
  final String? dropoffLocation;

  // Hinweis: Für Mietwagen sind start/end die Abhol-/Rückgabezeiten.
  const RentalCarItem({
    required super.id,
    required super.start,
    required DateTime super.end,
    super.from,
    super.to,
    super.notes,
    super.price,
    super.currency,
    required this.company,
    this.reservation,
    this.vehicleClass,
    this.pickupLocation,
    this.dropoffLocation,
  }) : super(
          type: TravelKind.rentalCar,
        );

  @override
  String summaryId() => company;

  @override
  Map<String, dynamic> toMap() => {
        'type': 'rentalCar',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'from': from,
        'to': to,
        'notes': notes,
        'price': price,
        'currency': currency,
        'company': company,
        'reservation': reservation,
        'vehicleClass': vehicleClass,
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
      };

  static RentalCarItem fromMap(Map<String, dynamic> j) => RentalCarItem(
        id: j['id'] as String,
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        from: j['from'] as String?,
        to: j['to'] as String?,
        notes: j['notes'] as String?,
        price: j['price'] as num?,
        currency: j['currency'] as String?,
        company: j['company'] as String,
        reservation: j['reservation'] as String?,
        vehicleClass: j['vehicleClass'] as String?,
        pickupLocation: j['pickupLocation'] as String?,
        dropoffLocation: j['dropoffLocation'] as String?,
      );

  RentalCarItem copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency,
    String? company,
    String? reservation,
    String? vehicleClass,
    String? pickupLocation,
    String? dropoffLocation,
  }) {
    return RentalCarItem(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end ?? this.end!, // end ist required
      from: from ?? this.from,
      to: to ?? this.to,
      notes: notes ?? this.notes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      company: company ?? this.company,
      reservation: reservation ?? this.reservation,
      vehicleClass: vehicleClass ?? this.vehicleClass,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
    );
  }  
}

/// ------------------------------
/// Hotel
/// ------------------------------
class HotelItem extends TravelItem {
  final String? company;         // "Marriott"
  final String name;    // "Name des Hotels"
  final String? location;   // "Adresse"

  // Hinweis: Für Hotels sind start/end die check in / check out Zeiten.
  const HotelItem({
    required super.id,
    required super.start,
    required DateTime super.end,
    super.notes,
    super.price,
    super.currency,
    this.company,
    required this.name,
    this.location
  }) : super(
          type: TravelKind.hotel,
        );

  @override
  String summaryId() => name;

  @override
  Map<String, dynamic> toMap() => {
        'type': 'hotel',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'notes': notes,
        'price': price,
        'currency': currency,
        'company': company,
        'name': name,
        'location': location
      };

  static HotelItem fromMap(Map<String, dynamic> j) => HotelItem(
        id: j['id'] as String,
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        notes: j['notes'] as String?,
        price: j['price'] as num?,
        currency: j['currency'] as String?,
        company: j['company'] as String?,
        name: j['name'] as String,
        location: j['location'] as String?
      );

  HotelItem copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency,
    String? company,
    String? name,
    String? location
  }) {
    return HotelItem(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end ?? this.end!, // end ist required
      notes: notes ?? this.notes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      company: company ?? this.company,
      name: name ?? this.name,
      location: location ?? this.location
    );
  }  
}

/// ------------------------------
/// Cruise Check In
/// ------------------------------
class CruiseCheckInItem extends TravelItem {

  // Hinweis: Für Hotels sind start/end die check in / check out Zeiten.
  const CruiseCheckInItem({
    required super.id,
    required super.start,
    required DateTime super.end,
    super.notes,
    super.price,
    super.currency
  }) : super(
          type: TravelKind.hotel,
        );

  @override
  String summaryId() => 'Cruise Check In';

  @override
  Map<String, dynamic> toMap() => {
        'type': 'hotel',
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'notes': notes,
        'price': price,
        'currency': currency
      };

  static CruiseCheckInItem fromMap(Map<String, dynamic> j) => CruiseCheckInItem(
        id: j['id'] as String,
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        notes: j['notes'] as String?,
        price: j['price'] as num?,
        currency: j['currency'] as String?
      );

  CruiseCheckInItem copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? from,
    String? to,
    String? notes,
    num? price,
    String? currency
  }) {
    return CruiseCheckInItem(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end ?? this.end!, // end ist required
      notes: notes ?? this.notes,
      price: price ?? this.price,
      currency: currency ?? this.currency
    );
  }  
}
