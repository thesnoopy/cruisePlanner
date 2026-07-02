import 'package:equatable/equatable.dart';

import 'document_draft_confidence.dart';
import 'document_draft_target_type.dart';
import 'document_import_source_reference.dart';

class DocumentImportDraft extends Equatable {
  static const Object _unset = Object();

  final DocumentDraftTargetType targetType;
  final DocumentImportSourceReference sourceReference;
  final DocumentDraftConfidence? confidence;
  final String? existingCruiseId;
  final String? existingItemId;
  final String? matchedRouteItemId;
  final CruiseImportDraft? cruise;
  final ExcursionImportDraft? excursion;
  final TravelImportDraft? travel;
  final RouteItemImportDraft? routeItem;

  const DocumentImportDraft({
    required this.targetType,
    this.sourceReference = const DocumentImportSourceReference(),
    this.confidence,
    this.existingCruiseId,
    this.existingItemId,
    this.matchedRouteItemId,
    this.cruise,
    this.excursion,
    this.travel,
    this.routeItem,
  });

  bool get isDocumentOnly =>
      targetType == DocumentDraftTargetType.documentOnly;

  DocumentImportDraft copyWith({
    DocumentDraftTargetType? targetType,
    DocumentImportSourceReference? sourceReference,
    Object? confidence = _unset,
    Object? existingCruiseId = _unset,
    Object? existingItemId = _unset,
    Object? matchedRouteItemId = _unset,
    Object? cruise = _unset,
    Object? excursion = _unset,
    Object? travel = _unset,
    Object? routeItem = _unset,
  }) {
    return DocumentImportDraft(
      targetType: targetType ?? this.targetType,
      sourceReference: sourceReference ?? this.sourceReference,
      confidence: identical(confidence, _unset)
          ? this.confidence
          : confidence as DocumentDraftConfidence?,
      existingCruiseId: identical(existingCruiseId, _unset)
          ? this.existingCruiseId
          : existingCruiseId as String?,
      existingItemId: identical(existingItemId, _unset)
          ? this.existingItemId
          : existingItemId as String?,
      matchedRouteItemId: identical(matchedRouteItemId, _unset)
          ? this.matchedRouteItemId
          : matchedRouteItemId as String?,
      cruise: identical(cruise, _unset) ? this.cruise : cruise as CruiseImportDraft?,
      excursion: identical(excursion, _unset)
          ? this.excursion
          : excursion as ExcursionImportDraft?,
      travel: identical(travel, _unset) ? this.travel : travel as TravelImportDraft?,
      routeItem: identical(routeItem, _unset)
          ? this.routeItem
          : routeItem as RouteItemImportDraft?,
    );
  }

  @override
  List<Object?> get props => [
        targetType,
        sourceReference,
        confidence,
        existingCruiseId,
        existingItemId,
        matchedRouteItemId,
        cruise,
        excursion,
        travel,
        routeItem,
      ];
}

class CruiseImportDraft extends Equatable {
  static const Object _unset = Object();

  final String? title;
  final String? shipName;
  final String? operatorName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? cabinNumber;
  final String? deckNumber;
  final String? deckName;

  const CruiseImportDraft({
    this.title,
    this.shipName,
    this.operatorName,
    this.startDate,
    this.endDate,
    this.cabinNumber,
    this.deckNumber,
    this.deckName,
  });

  CruiseImportDraft copyWith({
    Object? title = _unset,
    Object? shipName = _unset,
    Object? operatorName = _unset,
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? cabinNumber = _unset,
    Object? deckNumber = _unset,
    Object? deckName = _unset,
  }) {
    return CruiseImportDraft(
      title: identical(title, _unset) ? this.title : title as String?,
      shipName: identical(shipName, _unset)
          ? this.shipName
          : shipName as String?,
      operatorName: identical(operatorName, _unset)
          ? this.operatorName
          : operatorName as String?,
      startDate: identical(startDate, _unset)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
      cabinNumber: identical(cabinNumber, _unset)
          ? this.cabinNumber
          : cabinNumber as String?,
      deckNumber: identical(deckNumber, _unset)
          ? this.deckNumber
          : deckNumber as String?,
      deckName: identical(deckName, _unset)
          ? this.deckName
          : deckName as String?,
    );
  }

  @override
  List<Object?> get props => [
        title,
        shipName,
        operatorName,
        startDate,
        endDate,
        cabinNumber,
        deckNumber,
        deckName,
      ];
}

class ExcursionImportDraft extends Equatable {
  static const Object _unset = Object();

  final String? title;
  final DateTime? date;
  final String? port;
  final String? meetingPoint;
  final String? notes;
  final num? price;
  final String? currency;

  const ExcursionImportDraft({
    this.title,
    this.date,
    this.port,
    this.meetingPoint,
    this.notes,
    this.price,
    this.currency,
  });

  ExcursionImportDraft copyWith({
    Object? title = _unset,
    Object? date = _unset,
    Object? port = _unset,
    Object? meetingPoint = _unset,
    Object? notes = _unset,
    Object? price = _unset,
    Object? currency = _unset,
  }) {
    return ExcursionImportDraft(
      title: identical(title, _unset) ? this.title : title as String?,
      date: identical(date, _unset) ? this.date : date as DateTime?,
      port: identical(port, _unset) ? this.port : port as String?,
      meetingPoint: identical(meetingPoint, _unset)
          ? this.meetingPoint
          : meetingPoint as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      price: identical(price, _unset) ? this.price : price as num?,
      currency: identical(currency, _unset)
          ? this.currency
          : currency as String?,
    );
  }

  @override
  List<Object?> get props => [
        title,
        date,
        port,
        meetingPoint,
        notes,
        price,
        currency,
      ];
}

class TravelImportDraft extends Equatable {
  static const Object _unset = Object();

  final DateTime? start;
  final DateTime? end;
  final String? from;
  final String? to;
  final String? notes;
  final num? price;
  final String? currency;
  final String? recordLocator;
  final String? company;
  final String? carrier;
  final String? flightNo;
  final String? name;
  final String? location;
  final String? address;
  final String? mode;

  const TravelImportDraft({
    this.start,
    this.end,
    this.from,
    this.to,
    this.notes,
    this.price,
    this.currency,
    this.recordLocator,
    this.company,
    this.carrier,
    this.flightNo,
    this.name,
    this.location,
    this.address,
    this.mode,
  });

  TravelImportDraft copyWith({
    Object? start = _unset,
    Object? end = _unset,
    Object? from = _unset,
    Object? to = _unset,
    Object? notes = _unset,
    Object? price = _unset,
    Object? currency = _unset,
    Object? recordLocator = _unset,
    Object? company = _unset,
    Object? carrier = _unset,
    Object? flightNo = _unset,
    Object? name = _unset,
    Object? location = _unset,
    Object? address = _unset,
    Object? mode = _unset,
  }) {
    return TravelImportDraft(
      start: identical(start, _unset) ? this.start : start as DateTime?,
      end: identical(end, _unset) ? this.end : end as DateTime?,
      from: identical(from, _unset) ? this.from : from as String?,
      to: identical(to, _unset) ? this.to : to as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      price: identical(price, _unset) ? this.price : price as num?,
      currency: identical(currency, _unset)
          ? this.currency
          : currency as String?,
      recordLocator: identical(recordLocator, _unset)
          ? this.recordLocator
          : recordLocator as String?,
      company: identical(company, _unset) ? this.company : company as String?,
      carrier: identical(carrier, _unset) ? this.carrier : carrier as String?,
      flightNo: identical(flightNo, _unset)
          ? this.flightNo
          : flightNo as String?,
      name: identical(name, _unset) ? this.name : name as String?,
      location: identical(location, _unset)
          ? this.location
          : location as String?,
      address: identical(address, _unset) ? this.address : address as String?,
      mode: identical(mode, _unset) ? this.mode : mode as String?,
    );
  }

  @override
  List<Object?> get props => [
        start,
        end,
        from,
        to,
        notes,
        price,
        currency,
        recordLocator,
        company,
        carrier,
        flightNo,
        name,
        location,
        address,
        mode,
      ];
}

class RouteItemImportDraft extends Equatable {
  static const Object _unset = Object();

  final DateTime? date;
  final String? portName;
  final DateTime? arrival;
  final DateTime? departure;
  final DateTime? allAboard;
  final String? notes;

  const RouteItemImportDraft({
    this.date,
    this.portName,
    this.arrival,
    this.departure,
    this.allAboard,
    this.notes,
  });

  RouteItemImportDraft copyWith({
    Object? date = _unset,
    Object? portName = _unset,
    Object? arrival = _unset,
    Object? departure = _unset,
    Object? allAboard = _unset,
    Object? notes = _unset,
  }) {
    return RouteItemImportDraft(
      date: identical(date, _unset) ? this.date : date as DateTime?,
      portName: identical(portName, _unset)
          ? this.portName
          : portName as String?,
      arrival: identical(arrival, _unset)
          ? this.arrival
          : arrival as DateTime?,
      departure: identical(departure, _unset)
          ? this.departure
          : departure as DateTime?,
      allAboard: identical(allAboard, _unset)
          ? this.allAboard
          : allAboard as DateTime?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }

  @override
  List<Object?> get props => [
        date,
        portName,
        arrival,
        departure,
        allAboard,
        notes,
      ];
}
