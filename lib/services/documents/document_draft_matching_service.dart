import '../../models/cruise.dart';
import '../../models/excursion.dart';
import '../../models/period.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/route_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../models/travel/base_travel.dart';
import '../../models/travel/cruise_check_in_item.dart';
import '../../models/travel/cruise_check_out_item.dart';
import '../../models/travel/flight_item.dart';
import '../../models/travel/hotel_item.dart';
import '../../models/travel/rental_car_item.dart';
import '../../models/travel/transfer_item.dart';
import '../../models/documents/document_draft_confidence.dart';
import '../../models/documents/document_draft_match_result.dart';
import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_draft.dart';

class DocumentDraftMatchingService {
  const DocumentDraftMatchingService();

  DocumentDraftMatchResult match({
    required DocumentImportDraft draft,
    required List<Cruise> cruises,
  }) {
    final activeCruises = cruises
        .where((cruise) => cruise.deletedAtUtc == null)
        .toList(growable: false);

    if (draft.isDocumentOnly) {
      return _result(
        draft: draft,
        matchedTargetType: DocumentDraftTargetType.documentOnly,
        action: DocumentDraftMatchAction.documentOnly,
        score: 1,
        reason: 'Draft is document-only and should stay unlinked.',
      );
    }

    if (draft.targetType == DocumentDraftTargetType.unknown) {
      return _result(
        draft: draft,
        matchedTargetType: DocumentDraftTargetType.unknown,
        action: DocumentDraftMatchAction.manualReview,
        score: 0.1,
        reason: 'Draft target is unknown; manual review is required.',
      );
    }

    final explicitMatch = _resolveExplicitMatch(
      draft: draft,
      cruises: activeCruises,
    );

    if (explicitMatch.isDirectExistingMatch) {
      return _result(
        draft: draft,
        matchedCruiseId: explicitMatch.cruise?.id,
        matchedRouteItemId: explicitMatch.routeItem?.id,
        matchedItemId: explicitMatch.itemId,
        matchedTargetType: explicitMatch.matchedTargetType ?? draft.targetType,
        action: DocumentDraftMatchAction.useExisting,
        score: 0.99,
        reason: explicitMatch.reason,
      );
    }

    switch (draft.targetType) {
      case DocumentDraftTargetType.cruise:
        return _matchCruiseDraft(
          draft: draft,
          cruises: activeCruises,
          explicitMatch: explicitMatch,
        );
      case DocumentDraftTargetType.excursion:
        return _matchExcursionDraft(
          draft: draft,
          cruises: activeCruises,
          explicitMatch: explicitMatch,
        );
      case DocumentDraftTargetType.portCall:
      case DocumentDraftTargetType.seaDay:
        return _matchRouteItemDraft(
          draft: draft,
          cruises: activeCruises,
          explicitMatch: explicitMatch,
        );
      case DocumentDraftTargetType.flight:
      case DocumentDraftTargetType.train:
      case DocumentDraftTargetType.transfer:
      case DocumentDraftTargetType.rentalCar:
      case DocumentDraftTargetType.hotel:
      case DocumentDraftTargetType.cruiseCheckIn:
      case DocumentDraftTargetType.cruiseCheckOut:
        return _matchTravelDraft(
          draft: draft,
          cruises: activeCruises,
          explicitMatch: explicitMatch,
        );
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        return _result(
          draft: draft,
          matchedTargetType: draft.targetType,
          action: DocumentDraftMatchAction.manualReview,
          score: 0.1,
          reason: 'Draft target requires manual review.',
        );
    }
  }

  DocumentDraftMatchResult _matchCruiseDraft({
    required DocumentImportDraft draft,
    required List<Cruise> cruises,
    required _ExplicitMatch explicitMatch,
  }) {
    final preservedCruise = explicitMatch.cruise;
    if (preservedCruise != null) {
      return _result(
        draft: draft,
        matchedCruiseId: preservedCruise.id,
        matchedTargetType: DocumentDraftTargetType.cruise,
        action: DocumentDraftMatchAction.useExisting,
        score: 0.99,
        reason: explicitMatch.reason,
      );
    }

    final cruiseDraft = draft.cruise;
    if (cruiseDraft == null) {
      return _result(
        draft: draft,
        matchedTargetType: DocumentDraftTargetType.cruise,
        action: DocumentDraftMatchAction.createNew,
        score: 0.25,
        reason: 'Draft does not contain enough cruise data to match existing cruises reliably.',
      );
    }

    final candidates = cruises
        .map((cruise) => _scoreCruiseCandidate(cruiseDraft, cruise))
        .where((candidate) => candidate.score > 0)
        .toList(growable: false)
      ..sort((left, right) => right.score.compareTo(left.score));

    if (candidates.isEmpty) {
      return _result(
        draft: draft,
        matchedTargetType: DocumentDraftTargetType.cruise,
        action: DocumentDraftMatchAction.createNew,
        score: 0.2,
        reason: 'No existing cruise overlaps enough by period and ship/title; suggest creating a new cruise.',
      );
    }

    final top = candidates.first;
    final isAmbiguous = _isAmbiguous(candidates);
    if (top.score >= 0.78 && !isAmbiguous) {
      return _result(
        draft: draft,
        matchedCruiseId: top.cruise.id,
        matchedTargetType: DocumentDraftTargetType.cruise,
        action: DocumentDraftMatchAction.useExisting,
        score: top.score,
        reason: top.reason,
      );
    }

    return _result(
      draft: draft,
      matchedTargetType: DocumentDraftTargetType.cruise,
      action: DocumentDraftMatchAction.createNew,
      score: 0.28,
      reason: 'Existing cruises look too weak or ambiguous for a safe match; suggest creating a new cruise.',
    );
  }

  DocumentDraftMatchResult _matchExcursionDraft({
    required DocumentImportDraft draft,
    required List<Cruise> cruises,
    required _ExplicitMatch explicitMatch,
  }) {
    final excursionDraft = draft.excursion;
    final preservedCruise = explicitMatch.cruise;

    if (excursionDraft == null) {
      return _result(
        draft: draft,
        matchedCruiseId: preservedCruise?.id,
        matchedTargetType: DocumentDraftTargetType.excursion,
        action: preservedCruise != null
            ? DocumentDraftMatchAction.createNew
            : DocumentDraftMatchAction.manualReview,
        score: preservedCruise != null ? 0.45 : 0.2,
        reason: preservedCruise != null
            ? 'Cruise is known, but excursion details are too sparse for an existing-item match.'
            : 'Excursion draft is too sparse for reliable matching.',
      );
    }

    final cruiseCandidates = _resolveCruiseCandidates(
      cruises: cruises,
      explicitCruise: preservedCruise,
      eventDate: excursionDraft.date,
      portHints: <String?>[excursionDraft.port],
      expectedRouteType: DocumentDraftTargetType.portCall,
    );

    final itemCandidates = <_ScoredExistingItemCandidate>[];
    for (final cruiseCandidate in cruiseCandidates) {
      for (final excursion in cruiseCandidate.cruise.excursions
          .where((item) => item.deletedAtUtc == null)) {
        final score = _scoreExcursionItem(
          draft: excursionDraft,
          excursion: excursion,
        );
        if (score <= 0) {
          continue;
        }
        itemCandidates.add(
          _ScoredExistingItemCandidate(
            cruise: cruiseCandidate.cruise,
            itemId: excursion.id,
            matchedTargetType: DocumentDraftTargetType.excursion,
            score: score,
            reason: _buildExcursionReason(excursionDraft, excursion),
            matchedRouteItemId: cruiseCandidate.routeItem?.id,
          ),
        );
      }
    }

    itemCandidates.sort((left, right) => right.score.compareTo(left.score));
    if (itemCandidates.isNotEmpty) {
      final top = itemCandidates.first;
      final isAmbiguous = _isAmbiguous(itemCandidates);
      final action = top.score >= 0.82 && !isAmbiguous
          ? DocumentDraftMatchAction.useExisting
          : DocumentDraftMatchAction.manualReview;
      final reason = action == DocumentDraftMatchAction.useExisting
          ? top.reason
          : isAmbiguous
              ? '${top.reason} Multiple plausible matches remain; review before using an existing excursion.'
              : '${top.reason} The match is not strong enough to auto-select an existing excursion.';
      return _result(
        draft: draft,
        matchedCruiseId: top.cruise.id,
        matchedRouteItemId: top.matchedRouteItemId,
        matchedItemId: top.itemId,
        matchedTargetType: DocumentDraftTargetType.excursion,
        action: action,
        score: top.score,
        reason: reason,
      );
    }

    if (cruiseCandidates.isNotEmpty) {
      final topCruise = cruiseCandidates.first;
      return _result(
        draft: draft,
        matchedCruiseId: topCruise.cruise.id,
        matchedRouteItemId: topCruise.routeItem?.id,
        matchedTargetType: DocumentDraftTargetType.excursion,
        action: DocumentDraftMatchAction.createNew,
        score: topCruise.score,
        reason: topCruise.reason.isEmpty
            ? 'Cruise period fits, but no existing excursion matches reliably; suggest creating a new excursion.'
            : '${topCruise.reason} No existing excursion matches reliably; suggest creating a new excursion.',
      );
    }

    return _result(
      draft: draft,
      matchedTargetType: DocumentDraftTargetType.excursion,
      action: DocumentDraftMatchAction.manualReview,
      score: 0.18,
      reason: 'No reliable cruise or excursion match was found.',
    );
  }

  DocumentDraftMatchResult _matchRouteItemDraft({
    required DocumentImportDraft draft,
    required List<Cruise> cruises,
    required _ExplicitMatch explicitMatch,
  }) {
    final routeDraft = draft.routeItem;
    final preservedCruise = explicitMatch.cruise;

    if (routeDraft == null) {
      return _result(
        draft: draft,
        matchedCruiseId: preservedCruise?.id,
        matchedTargetType: draft.targetType,
        action: preservedCruise != null
            ? DocumentDraftMatchAction.createNew
            : DocumentDraftMatchAction.manualReview,
        score: preservedCruise != null ? 0.45 : 0.2,
        reason: preservedCruise != null
            ? 'Cruise is known, but route item details are too sparse for an existing-item match.'
            : 'Route item draft is too sparse for reliable matching.',
      );
    }

    final cruiseCandidates = _resolveCruiseCandidates(
      cruises: cruises,
      explicitCruise: preservedCruise,
      eventDate: routeDraft.date,
      portHints: <String?>[routeDraft.portName],
      expectedRouteType: draft.targetType,
    );

    final itemCandidates = <_ScoredExistingItemCandidate>[];
    for (final cruiseCandidate in cruiseCandidates) {
      for (final item in cruiseCandidate.cruise.route.where(
        (routeItem) => routeItem.deletedAtUtc == null,
      )) {
        final score = _scoreRouteItem(
          draft: draft,
          routeDraft: routeDraft,
          item: item,
        );
        if (score <= 0) {
          continue;
        }
        itemCandidates.add(
          _ScoredExistingItemCandidate(
            cruise: cruiseCandidate.cruise,
            itemId: item.id,
            matchedTargetType: draft.targetType,
            score: score,
            reason: _buildRouteReason(routeDraft, item),
            matchedRouteItemId: item.id,
          ),
        );
      }
    }

    itemCandidates.sort((left, right) => right.score.compareTo(left.score));
    if (itemCandidates.isNotEmpty) {
      final top = itemCandidates.first;
      final isAmbiguous = _isAmbiguous(itemCandidates);
      final action = top.score >= 0.82 && !isAmbiguous
          ? DocumentDraftMatchAction.useExisting
          : DocumentDraftMatchAction.manualReview;
      final reason = action == DocumentDraftMatchAction.useExisting
          ? top.reason
          : isAmbiguous
              ? '${top.reason} Multiple plausible route items remain; manual review is safer.'
              : '${top.reason} The match is not strong enough to auto-select an existing route item.';
      return _result(
        draft: draft,
        matchedCruiseId: top.cruise.id,
        matchedRouteItemId: top.matchedRouteItemId,
        matchedTargetType: draft.targetType,
        action: action,
        score: top.score,
        reason: reason,
      );
    }

    if (cruiseCandidates.isNotEmpty) {
      final topCruise = cruiseCandidates.first;
      return _result(
        draft: draft,
        matchedCruiseId: topCruise.cruise.id,
        matchedTargetType: draft.targetType,
        action: DocumentDraftMatchAction.createNew,
        score: topCruise.score,
        reason: topCruise.reason.isEmpty
            ? 'Cruise period fits, but no existing route item matches reliably; suggest creating a new route item.'
            : '${topCruise.reason} No existing route item matches reliably; suggest creating a new route item.',
      );
    }

    return _result(
      draft: draft,
      matchedTargetType: draft.targetType,
      action: DocumentDraftMatchAction.manualReview,
      score: 0.18,
      reason: 'No reliable cruise or route item match was found.',
    );
  }

  DocumentDraftMatchResult _matchTravelDraft({
    required DocumentImportDraft draft,
    required List<Cruise> cruises,
    required _ExplicitMatch explicitMatch,
  }) {
    final travelDraft = draft.travel;
    final preservedCruise = explicitMatch.cruise;

    if (travelDraft == null) {
      return _result(
        draft: draft,
        matchedCruiseId: preservedCruise?.id,
        matchedTargetType: draft.targetType,
        action: preservedCruise != null
            ? DocumentDraftMatchAction.createNew
            : DocumentDraftMatchAction.manualReview,
        score: preservedCruise != null ? 0.45 : 0.2,
        reason: preservedCruise != null
            ? 'Cruise is known, but travel details are too sparse for an existing-item match.'
            : 'Travel draft is too sparse for reliable matching.',
      );
    }

    final expectedKind = _travelKindForTargetType(draft.targetType);
    if (expectedKind == null) {
      return _result(
        draft: draft,
        matchedTargetType: draft.targetType,
        action: DocumentDraftMatchAction.manualReview,
        score: 0.12,
        reason: 'Travel target type could not be mapped to a travel kind.',
      );
    }

    final eventDate = travelDraft.start ?? travelDraft.end;
    final cruiseCandidates = _resolveCruiseCandidates(
      cruises: cruises,
      explicitCruise: preservedCruise,
      eventDate: eventDate,
      portHints: <String?>[
        travelDraft.from,
        travelDraft.to,
        travelDraft.location,
        travelDraft.name,
      ],
    );

    final itemCandidates = <_ScoredExistingItemCandidate>[];
    for (final cruiseCandidate in cruiseCandidates) {
      for (final item in cruiseCandidate.cruise.travel.where(
        (travelItem) =>
            travelItem.deletedAtUtc == null &&
            travelItem.kind == expectedKind,
      )) {
        final score = _scoreTravelItem(
          draft: draft,
          travelDraft: travelDraft,
          item: item,
        );
        if (score <= 0) {
          continue;
        }
        itemCandidates.add(
          _ScoredExistingItemCandidate(
            cruise: cruiseCandidate.cruise,
            itemId: item.id,
            matchedTargetType: draft.targetType,
            score: score,
            reason: _buildTravelReason(draft.targetType, travelDraft, item),
          ),
        );
      }
    }

    itemCandidates.sort((left, right) => right.score.compareTo(left.score));
    if (itemCandidates.isNotEmpty) {
      final top = itemCandidates.first;
      final isAmbiguous = _isAmbiguous(itemCandidates);
      final action = top.score >= 0.82 && !isAmbiguous
          ? DocumentDraftMatchAction.useExisting
          : DocumentDraftMatchAction.manualReview;
      final reason = action == DocumentDraftMatchAction.useExisting
          ? top.reason
          : isAmbiguous
              ? '${top.reason} Similar travel items exist; manual review is safer.'
              : '${top.reason} The match is not strong enough to auto-select an existing travel item.';
      return _result(
        draft: draft,
        matchedCruiseId: top.cruise.id,
        matchedItemId: top.itemId,
        matchedTargetType: draft.targetType,
        action: action,
        score: top.score,
        reason: reason,
      );
    }

    if (cruiseCandidates.isNotEmpty) {
      final topCruise = cruiseCandidates.first;
      return _result(
        draft: draft,
        matchedCruiseId: topCruise.cruise.id,
        matchedRouteItemId: topCruise.routeItem?.id,
        matchedTargetType: draft.targetType,
        action: DocumentDraftMatchAction.createNew,
        score: topCruise.score,
        reason: topCruise.reason.isEmpty
            ? 'Cruise period fits, but no existing travel item matches reliably; suggest creating a new travel item.'
            : '${topCruise.reason} No existing travel item matches reliably; suggest creating a new travel item.',
      );
    }

    return _result(
      draft: draft,
      matchedTargetType: draft.targetType,
      action: DocumentDraftMatchAction.manualReview,
      score: 0.18,
      reason: 'No reliable cruise or travel item match was found.',
    );
  }

  List<_ScoredCruiseCandidate> _resolveCruiseCandidates({
    required List<Cruise> cruises,
    required Cruise? explicitCruise,
    required DateTime? eventDate,
    List<String?> portHints = const <String?>[],
    DocumentDraftTargetType? expectedRouteType,
  }) {
    if (explicitCruise != null) {
      final routeItem = eventDate == null
          ? null
          : _bestRouteItemCandidate(
              cruise: explicitCruise,
              date: eventDate,
              portHints: portHints,
              expectedRouteType: expectedRouteType,
            );
      return <_ScoredCruiseCandidate>[
        _ScoredCruiseCandidate(
          cruise: explicitCruise,
          score: 0.9,
          reason: 'Using the explicitly referenced cruise.',
          routeItem: routeItem?.item,
        ),
      ];
    }

    if (eventDate == null) {
      return const <_ScoredCruiseCandidate>[];
    }

    final candidates = cruises
        .where((cruise) => _periodContainsDate(cruise.period, eventDate))
        .map(
          (cruise) {
            final routeItemCandidate = _bestRouteItemCandidate(
              cruise: cruise,
              date: eventDate,
              portHints: portHints,
              expectedRouteType: expectedRouteType,
            );
            var score = 0.55;
            var reason = 'Cruise period contains the draft date.';
            if (routeItemCandidate != null) {
              score += routeItemCandidate.score;
              if (routeItemCandidate.reason.isNotEmpty) {
                reason = '$reason ${routeItemCandidate.reason}';
              }
            }
            return _ScoredCruiseCandidate(
              cruise: cruise,
              score: score > 0.95 ? 0.95 : score,
              reason: reason,
              routeItem: routeItemCandidate?.item,
            );
          },
        )
        .toList(growable: false)
      ..sort((left, right) => right.score.compareTo(left.score));

    return candidates;
  }

  _ScoredCruiseCandidate _scoreCruiseCandidate(
    CruiseImportDraft draft,
    Cruise cruise,
  ) {
    var score = 0.0;
    final reasons = <String>[];

    final overlaps = _periodsOverlap(
      cruise.period,
      start: draft.startDate,
      end: draft.endDate,
    );
    if (overlaps) {
      score += 0.42;
      reasons.add('cruise periods overlap');
    } else if (draft.startDate != null &&
        _periodContainsDate(cruise.period, draft.startDate!)) {
      score += 0.35;
      reasons.add('existing cruise contains the draft start date');
    } else if (draft.endDate != null &&
        _periodContainsDate(cruise.period, draft.endDate!)) {
      score += 0.35;
      reasons.add('existing cruise contains the draft end date');
    }

    final shipScore = _textMatchScore(draft.shipName, cruise.ship.name);
    if (shipScore > 0) {
      score += 0.32 * shipScore;
      reasons.add('ship name is similar');
    }

    final titleScore = _textMatchScore(draft.title, cruise.title);
    if (titleScore > 0) {
      score += 0.2 * titleScore;
      reasons.add('cruise title is similar');
    }

    final operatorScore =
        _textMatchScore(draft.operatorName, cruise.ship.operatorName);
    if (operatorScore > 0) {
      score += 0.08 * operatorScore;
      reasons.add('operator name is similar');
    }

    return _ScoredCruiseCandidate(
      cruise: cruise,
      score: score > 0.99 ? 0.99 : score,
      reason: reasons.isEmpty
          ? ''
          : 'Matched existing cruise because ${reasons.join(', ')}.',
    );
  }

  _ScoredRouteItemCandidate? _bestRouteItemCandidate({
    required Cruise cruise,
    required DateTime date,
    required List<String?> portHints,
    DocumentDraftTargetType? expectedRouteType,
  }) {
    final candidates = <_ScoredRouteItemCandidate>[];
    for (final item in cruise.route.where((routeItem) {
      return routeItem.deletedAtUtc == null && _isSameDay(routeItem.date, date);
    })) {
      var score = 0.0;
      var reason = '';

      if (item is SeaDayItem &&
          expectedRouteType == DocumentDraftTargetType.seaDay) {
        score = 0.28;
        reason = 'Same-day sea day exists on the route.';
      } else if (item is PortCallItem) {
        final portScore = _bestTextMatch(
          item.portName,
          portHints,
        );
        if (portScore > 0) {
          score = 0.3 * portScore;
          reason = 'Same-day port call with a similar port name exists.';
        } else if (expectedRouteType == null) {
          score = 0.08;
          reason = 'Same-day route item exists on the cruise.';
        }
      }

      if (score <= 0) {
        continue;
      }
      candidates.add(
        _ScoredRouteItemCandidate(
          item: item,
          score: score,
          reason: reason,
        ),
      );
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((left, right) => right.score.compareTo(left.score));
    return candidates.first;
  }

  double _scoreExcursionItem({
    required ExcursionImportDraft draft,
    required Excursion excursion,
  }) {
    if (draft.date == null || !_isSameDay(draft.date!, excursion.date)) {
      return 0;
    }

    var score = 0.5;
    final titleScore = _textMatchScore(draft.title, excursion.title);
    if (titleScore > 0) {
      score += 0.32 * titleScore;
    }

    final portScore = _textMatchScore(draft.port, excursion.port);
    if (portScore > 0) {
      score += 0.18 * portScore;
    }

    return score > 0.99 ? 0.99 : score;
  }

  double _scoreRouteItem({
    required DocumentImportDraft draft,
    required RouteItemImportDraft routeDraft,
    required RouteItem item,
  }) {
    if (routeDraft.date == null || !_isSameDay(routeDraft.date!, item.date)) {
      return 0;
    }

    switch (draft.targetType) {
      case DocumentDraftTargetType.seaDay:
        return item is SeaDayItem ? 0.9 : 0;
      case DocumentDraftTargetType.portCall:
        if (item is! PortCallItem) {
          return 0;
        }
        var score = 0.58;
        score += 0.28 * _textMatchScore(routeDraft.portName, item.portName);
        score += 0.06 * _dateTimeMatchScore(routeDraft.arrival, item.arrival);
        score += 0.04 * _dateTimeMatchScore(routeDraft.departure, item.departure);
        score += 0.04 * _dateTimeMatchScore(routeDraft.allAboard, item.allAboard);
        return score > 0.99 ? 0.99 : score;
      default:
        return 0;
    }
  }

  double _scoreTravelItem({
    required DocumentImportDraft draft,
    required TravelImportDraft travelDraft,
    required TravelItem item,
  }) {
    final start = travelDraft.start;
    final end = travelDraft.end;
    if (start == null && end == null) {
      return 0;
    }

    final referenceDraftDate = start ?? end!;
    final referenceItemDate = start != null ? item.start : (item.end ?? item.start);
    if (!_isSameDay(referenceDraftDate, referenceItemDate)) {
      return 0;
    }

    var score = 0.45;
    score += 0.18 * _dateTimeMatchScore(start, item.start);
    score += 0.08 * _dateTimeMatchScore(end, item.end ?? item.start);
    score += 0.12 * _textMatchScore(travelDraft.from, item.from);
    score += 0.12 * _textMatchScore(travelDraft.to, item.to);
    score += 0.2 * _textMatchScore(travelDraft.recordLocator, item.recordLocator);

    switch (draft.targetType) {
      case DocumentDraftTargetType.flight:
        final flight = item as FlightItem;
        score += 0.08 * _textMatchScore(travelDraft.carrier, flight.carrier);
        score += 0.18 * _textMatchScore(travelDraft.flightNo, flight.flightNo);
        break;
      case DocumentDraftTargetType.train:
        break;
      case DocumentDraftTargetType.transfer:
        final transfer = item as TransferItem;
        score += 0.14 * _textMatchScore(
          travelDraft.mode,
          transfer.mode?.name,
        );
        break;
      case DocumentDraftTargetType.rentalCar:
        final rentalCar = item as RentalCarItem;
        score += 0.16 * _textMatchScore(travelDraft.company, rentalCar.company);
        break;
      case DocumentDraftTargetType.hotel:
        final hotel = item as HotelItem;
        score += 0.22 * _textMatchScore(travelDraft.name, hotel.name);
        score += 0.12 * _textMatchScore(travelDraft.location, hotel.location);
        score += 0.08 * _textMatchScore(travelDraft.address, hotel.address);
        break;
      case DocumentDraftTargetType.cruiseCheckIn:
        final checkIn = item as CruiseCheckIn;
        score += 0.08 * _textMatchScore(travelDraft.location, checkIn.to);
        break;
      case DocumentDraftTargetType.cruiseCheckOut:
        final checkOut = item as CruiseCheckOut;
        score += 0.08 * _textMatchScore(travelDraft.location, checkOut.from);
        break;
      case DocumentDraftTargetType.cruise:
      case DocumentDraftTargetType.excursion:
      case DocumentDraftTargetType.portCall:
      case DocumentDraftTargetType.seaDay:
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        break;
    }

    return score > 0.99 ? 0.99 : score;
  }

  String _buildExcursionReason(
    ExcursionImportDraft draft,
    Excursion excursion,
  ) {
    final details = <String>['same date'];
    if (_textMatchScore(draft.title, excursion.title) > 0) {
      details.add('similar title');
    }
    if (_textMatchScore(draft.port, excursion.port) > 0) {
      details.add('similar port');
    }
    return 'Matched existing excursion because it has ${details.join(', ')}.';
  }

  String _buildRouteReason(
    RouteItemImportDraft draft,
    RouteItem item,
  ) {
    if (item is SeaDayItem) {
      return 'Matched existing sea day because the date matches exactly.';
    }

    final details = <String>['same date'];
    if (item is PortCallItem &&
        _textMatchScore(draft.portName, item.portName) > 0) {
      details.add('similar port');
    }
    return 'Matched existing route item because it has ${details.join(', ')}.';
  }

  String _buildTravelReason(
    DocumentDraftTargetType targetType,
    TravelImportDraft draft,
    TravelItem item,
  ) {
    final details = <String>['same date'];
    if (_dateTimeMatchScore(draft.start, item.start) > 0) {
      details.add('similar start time');
    }
    if (_textMatchScore(draft.from, item.from) > 0 ||
        _textMatchScore(draft.to, item.to) > 0) {
      details.add('similar route');
    }
    if (_textMatchScore(draft.recordLocator, item.recordLocator) > 0) {
      details.add('matching record locator');
    }
    switch (targetType) {
      case DocumentDraftTargetType.flight:
        final flight = item as FlightItem;
        if (_textMatchScore(draft.flightNo, flight.flightNo) > 0) {
          details.add('matching flight number');
        }
        break;
      case DocumentDraftTargetType.hotel:
        final hotel = item as HotelItem;
        if (_textMatchScore(draft.name, hotel.name) > 0) {
          details.add('similar hotel name');
        }
        break;
      case DocumentDraftTargetType.rentalCar:
        final rentalCar = item as RentalCarItem;
        if (_textMatchScore(draft.company, rentalCar.company) > 0) {
          details.add('similar company');
        }
        break;
      case DocumentDraftTargetType.transfer:
        final transfer = item as TransferItem;
        if (_textMatchScore(draft.mode, transfer.mode?.name) > 0) {
          details.add('similar transfer mode');
        }
        break;
      case DocumentDraftTargetType.cruiseCheckIn:
      case DocumentDraftTargetType.cruiseCheckOut:
      case DocumentDraftTargetType.train:
      case DocumentDraftTargetType.cruise:
      case DocumentDraftTargetType.excursion:
      case DocumentDraftTargetType.portCall:
      case DocumentDraftTargetType.seaDay:
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        break;
    }

    return 'Matched existing travel item because it has ${details.join(', ')}.';
  }

  _ExplicitMatch _resolveExplicitMatch({
    required DocumentImportDraft draft,
    required List<Cruise> cruises,
  }) {
    final explicitCruise = _findCruiseById(cruises, draft.existingCruiseId);

    if (draft.targetType == DocumentDraftTargetType.cruise &&
        explicitCruise != null) {
      return _ExplicitMatch(
        cruise: explicitCruise,
        matchedTargetType: DocumentDraftTargetType.cruise,
        reason: 'Preserved the explicitly referenced cruise id.',
      );
    }

    if (draft.targetType.isRouteItemTarget) {
      final routeItemId = draft.matchedRouteItemId ?? draft.existingItemId;
      final routeItemMatch = _findRouteItemMatch(
        cruises: cruises,
        cruise: explicitCruise,
        routeItemId: routeItemId,
        expectedType: draft.targetType,
      );
      if (routeItemMatch != null) {
        return _ExplicitMatch(
          cruise: routeItemMatch.cruise,
          routeItem: routeItemMatch.item,
          matchedTargetType: draft.targetType,
          reason: 'Preserved the explicitly referenced route item id.',
        );
      }
    }

    if (draft.targetType == DocumentDraftTargetType.excursion) {
      final excursionMatch = _findExcursionMatch(
        cruises: cruises,
        cruise: explicitCruise,
        excursionId: draft.existingItemId,
      );
      if (excursionMatch != null) {
        return _ExplicitMatch(
          cruise: excursionMatch.cruise,
          itemId: excursionMatch.item.id,
          matchedTargetType: DocumentDraftTargetType.excursion,
          reason: 'Preserved the explicitly referenced excursion id.',
        );
      }
    }

    if (draft.targetType.isTravelTarget) {
      final expectedKind = _travelKindForTargetType(draft.targetType);
      final travelMatch = _findTravelMatch(
        cruises: cruises,
        cruise: explicitCruise,
        itemId: draft.existingItemId,
        expectedKind: expectedKind,
      );
      if (travelMatch != null) {
        return _ExplicitMatch(
          cruise: travelMatch.cruise,
          itemId: travelMatch.item.id,
          matchedTargetType: draft.targetType,
          reason: 'Preserved the explicitly referenced travel item id.',
        );
      }
    }

    if (explicitCruise != null) {
      return _ExplicitMatch(
        cruise: explicitCruise,
        matchedTargetType: draft.targetType,
        reason: 'Preserved the explicitly referenced cruise id.',
      );
    }

    return const _ExplicitMatch();
  }

  _RouteItemMatch? _findRouteItemMatch({
    required List<Cruise> cruises,
    required Cruise? cruise,
    required String? routeItemId,
    required DocumentDraftTargetType expectedType,
  }) {
    if (routeItemId == null) {
      return null;
    }

    final cruisePool = cruise == null ? cruises : <Cruise>[cruise];
    for (final currentCruise in cruisePool) {
      for (final item in currentCruise.route.where(
        (routeItem) => routeItem.deletedAtUtc == null && routeItem.id == routeItemId,
      )) {
        final matchesType =
            expectedType == DocumentDraftTargetType.portCall && item is PortCallItem ||
                expectedType == DocumentDraftTargetType.seaDay && item is SeaDayItem;
        if (!matchesType) {
          continue;
        }
        return _RouteItemMatch(cruise: currentCruise, item: item);
      }
    }

    return null;
  }

  _ExcursionMatch? _findExcursionMatch({
    required List<Cruise> cruises,
    required Cruise? cruise,
    required String? excursionId,
  }) {
    if (excursionId == null) {
      return null;
    }

    final cruisePool = cruise == null ? cruises : <Cruise>[cruise];
    for (final currentCruise in cruisePool) {
      for (final item in currentCruise.excursions.where(
        (excursion) => excursion.deletedAtUtc == null && excursion.id == excursionId,
      )) {
        return _ExcursionMatch(cruise: currentCruise, item: item);
      }
    }

    return null;
  }

  _TravelMatch? _findTravelMatch({
    required List<Cruise> cruises,
    required Cruise? cruise,
    required String? itemId,
    required TravelKind? expectedKind,
  }) {
    if (itemId == null) {
      return null;
    }

    final cruisePool = cruise == null ? cruises : <Cruise>[cruise];
    for (final currentCruise in cruisePool) {
      for (final item in currentCruise.travel.where((travelItem) {
        return travelItem.deletedAtUtc == null &&
            travelItem.id == itemId &&
            (expectedKind == null || travelItem.kind == expectedKind);
      })) {
        return _TravelMatch(cruise: currentCruise, item: item);
      }
    }

    return null;
  }

  Cruise? _findCruiseById(List<Cruise> cruises, String? cruiseId) {
    if (cruiseId == null) {
      return null;
    }

    for (final cruise in cruises) {
      if (cruise.id == cruiseId) {
        return cruise;
      }
    }

    return null;
  }

  TravelKind? _travelKindForTargetType(DocumentDraftTargetType targetType) {
    switch (targetType) {
      case DocumentDraftTargetType.flight:
        return TravelKind.flight;
      case DocumentDraftTargetType.train:
        return TravelKind.train;
      case DocumentDraftTargetType.transfer:
        return TravelKind.transfer;
      case DocumentDraftTargetType.rentalCar:
        return TravelKind.rentalCar;
      case DocumentDraftTargetType.hotel:
        return TravelKind.hotel;
      case DocumentDraftTargetType.cruiseCheckIn:
        return TravelKind.cruiseCheckIn;
      case DocumentDraftTargetType.cruiseCheckOut:
        return TravelKind.cruiseCheckOut;
      case DocumentDraftTargetType.cruise:
      case DocumentDraftTargetType.excursion:
      case DocumentDraftTargetType.portCall:
      case DocumentDraftTargetType.seaDay:
      case DocumentDraftTargetType.documentOnly:
      case DocumentDraftTargetType.unknown:
        return null;
    }
  }

  DocumentDraftMatchResult _result({
    required DocumentImportDraft draft,
    required DocumentDraftTargetType matchedTargetType,
    required DocumentDraftMatchAction action,
    required double score,
    required String reason,
    String? matchedCruiseId,
    String? matchedRouteItemId,
    String? matchedItemId,
  }) {
    return DocumentDraftMatchResult(
      draft: draft,
      matchedCruiseId: matchedCruiseId,
      matchedRouteItemId: matchedRouteItemId,
      matchedItemId: matchedItemId,
      matchedTargetType: matchedTargetType,
      action: action,
      confidence: DocumentDraftConfidence(
        score: score,
        reason: reason,
      ),
    );
  }

  bool _isAmbiguous(List<_ScoredCandidate> candidates) {
    if (candidates.length < 2) {
      return false;
    }

    final top = candidates[0];
    final second = candidates[1];
    return top.score < 0.95 && (top.score - second.score).abs() < 0.08;
  }

  bool _periodContainsDate(Period period, DateTime date) {
    final normalizedDate = _dateOnly(date);
    final start = _dateOnly(period.start);
    final end = _dateOnly(period.end);
    return !normalizedDate.isBefore(start) && !normalizedDate.isAfter(end);
  }

  bool _periodsOverlap(
    Period period, {
    required DateTime? start,
    required DateTime? end,
  }) {
    if (start == null && end == null) {
      return false;
    }

    final normalizedStart = _dateOnly(start ?? end!);
    final normalizedEnd = _dateOnly(end ?? start!);
    final rangeStart = normalizedStart.isBefore(normalizedEnd)
        ? normalizedStart
        : normalizedEnd;
    final rangeEnd = normalizedStart.isBefore(normalizedEnd)
        ? normalizedEnd
        : normalizedStart;
    final periodStart = _dateOnly(period.start);
    final periodEnd = _dateOnly(period.end);
    return !rangeEnd.isBefore(periodStart) && !rangeStart.isAfter(periodEnd);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  double _bestTextMatch(String? value, List<String?> candidates) {
    var best = 0.0;
    for (final candidate in candidates) {
      final score = _textMatchScore(value, candidate);
      if (score > best) {
        best = score;
      }
    }
    return best;
  }

  double _textMatchScore(String? left, String? right) {
    final normalizedLeft = _normalizeText(left);
    final normalizedRight = _normalizeText(right);
    if (normalizedLeft.isEmpty || normalizedRight.isEmpty) {
      return 0;
    }

    if (normalizedLeft == normalizedRight) {
      return 1;
    }

    final shorter = normalizedLeft.length <= normalizedRight.length
        ? normalizedLeft
        : normalizedRight;
    final longer = normalizedLeft.length > normalizedRight.length
        ? normalizedLeft
        : normalizedRight;
    if (shorter.length >= 4 && longer.contains(shorter)) {
      return 0.8;
    }

    final leftTokens = normalizedLeft.split(' ').where((token) => token.isNotEmpty).toSet();
    final rightTokens = normalizedRight.split(' ').where((token) => token.isNotEmpty).toSet();
    if (leftTokens.isEmpty || rightTokens.isEmpty) {
      return 0;
    }

    final common = leftTokens.intersection(rightTokens).length;
    if (common == 0) {
      return 0;
    }

    final ratio = common / (leftTokens.length < rightTokens.length
        ? leftTokens.length
        : rightTokens.length);
    if (ratio >= 1) {
      return 0.7;
    }
    if (ratio >= 0.5) {
      return 0.5;
    }
    return 0.3;
  }

  String _normalizeText(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }

    return normalized
        .replaceAll(RegExp(r'[\s\-_/,.;:()]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _dateTimeMatchScore(DateTime? left, DateTime? right) {
    if (left == null || right == null || !_isSameDay(left, right)) {
      return 0;
    }

    if (!_hasExplicitTime(left) || !_hasExplicitTime(right)) {
      return 0.5;
    }

    final difference = left.difference(right).abs().inMinutes;
    if (difference <= 15) {
      return 1;
    }
    if (difference <= 90) {
      return 0.75;
    }
    if (difference <= 180) {
      return 0.4;
    }
    return 0;
  }

  bool _hasExplicitTime(DateTime value) {
    return value.hour != 0 ||
        value.minute != 0 ||
        value.second != 0 ||
        value.millisecond != 0 ||
        value.microsecond != 0;
  }
}

abstract class _ScoredCandidate {
  double get score;
}

class _ExplicitMatch {
  final Cruise? cruise;
  final RouteItem? routeItem;
  final String? itemId;
  final DocumentDraftTargetType? matchedTargetType;
  final String reason;

  bool get isDirectExistingMatch =>
      routeItem != null ||
      itemId != null ||
      matchedTargetType == DocumentDraftTargetType.cruise && cruise != null;

  const _ExplicitMatch({
    this.cruise,
    this.routeItem,
    this.itemId,
    this.matchedTargetType,
    this.reason = '',
  });
}

class _ScoredCruiseCandidate extends _ScoredCandidate {
  final Cruise cruise;
  @override
  final double score;
  final String reason;
  final RouteItem? routeItem;

  _ScoredCruiseCandidate({
    required this.cruise,
    required this.score,
    required this.reason,
    this.routeItem,
  });
}

class _ScoredRouteItemCandidate extends _ScoredCandidate {
  final RouteItem item;
  @override
  final double score;
  final String reason;

  _ScoredRouteItemCandidate({
    required this.item,
    required this.score,
    required this.reason,
  });
}

class _ScoredExistingItemCandidate extends _ScoredCandidate {
  final Cruise cruise;
  final String itemId;
  final DocumentDraftTargetType matchedTargetType;
  @override
  final double score;
  final String reason;
  final String? matchedRouteItemId;

  _ScoredExistingItemCandidate({
    required this.cruise,
    required this.itemId,
    required this.matchedTargetType,
    required this.score,
    required this.reason,
    this.matchedRouteItemId,
  });
}

class _RouteItemMatch {
  final Cruise cruise;
  final RouteItem item;

  _RouteItemMatch({
    required this.cruise,
    required this.item,
  });
}

class _ExcursionMatch {
  final Cruise cruise;
  final Excursion item;

  _ExcursionMatch({
    required this.cruise,
    required this.item,
  });
}

class _TravelMatch {
  final Cruise cruise;
  final TravelItem item;

  _TravelMatch({
    required this.cruise,
    required this.item,
  });
}
