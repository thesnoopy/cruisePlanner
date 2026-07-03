import 'package:intl/intl.dart';

import '../../models/documents/document_analysis_input.dart';
import '../../models/documents/document_analysis_result.dart';
import '../../models/documents/document_draft_confidence.dart';
import '../../models/documents/document_draft_target_type.dart';
import '../../models/documents/document_import_draft.dart';
import '../../models/documents/document_text_extraction_result.dart';

abstract class DocumentSemanticAnalyzer {
  const DocumentSemanticAnalyzer();

  Future<DocumentAnalysisResult> analyze({
    required DocumentAnalysisInput input,
    required DocumentTextExtractionResult textExtractionResult,
  });
}

class LocalRuleBasedDocumentSemanticAnalyzer extends DocumentSemanticAnalyzer {
  const LocalRuleBasedDocumentSemanticAnalyzer();

  @override
  Future<DocumentAnalysisResult> analyze({
    required DocumentAnalysisInput input,
    required DocumentTextExtractionResult textExtractionResult,
  }) async {
    final text = _AnalyzedDocumentText.from(
      textExtractionResult.extractedText,
    );
    if (!text.hasText) {
      return DocumentAnalysisResult(
        sourceReference: input.sourceReference,
      );
    }

    final candidates = <_DraftCandidate>[
      ...[
        _analyzeCruise(input, text),
        _analyzeExcursion(input, text),
        _analyzeHotel(input, text),
        _analyzeFlight(input, text),
      ].whereType<_DraftCandidate>(),
    ]..sort((left, right) => right.score.compareTo(left.score));

    if (candidates.isEmpty || _isAmbiguousTopCandidate(candidates)) {
      return DocumentAnalysisResult(
        sourceReference: input.sourceReference,
      );
    }

    final top = candidates.first;
    return DocumentAnalysisResult(
      sourceReference: input.sourceReference,
      drafts: <DocumentImportDraft>[top.draft],
      confidence: top.confidence,
    );
  }

  bool _isAmbiguousTopCandidate(List<_DraftCandidate> candidates) {
    if (candidates.length < 2) {
      return false;
    }

    final top = candidates[0];
    final second = candidates[1];
    return top.score < 0.95 && (top.score - second.score).abs() < 0.06;
  }

  _DraftCandidate? _analyzeCruise(
    DocumentAnalysisInput input,
    _AnalyzedDocumentText text,
  ) {
    final hasCruiseKeyword = text.containsAny(const <String>[
      'cruise',
      'voyage',
      'sailing',
    ]);
    final hasBookingKeyword = text.containsAny(const <String>[
      'booking',
      'reservation',
      'confirmation',
    ]);
    final hasEmbarkationKeyword = text.containsAny(const <String>[
      'embarkation',
      'disembarkation',
      'sailing date',
    ]);

    final shipName = _sanitizeTitleCandidate(
      _extractLabeledValue(
        text.lines,
        const <String>['ship', 'vessel'],
      ),
      const <String>['ship', 'vessel'],
    );
    final operatorName = _extractLabeledValue(
      text.lines,
      const <String>['cruise line', 'operator', 'line'],
    );
    final cabinNumber = _extractTokenValue(
      text.lines,
      const <String>[
        'cabin number',
        'cabin no',
        'cabin',
        'stateroom number',
        'stateroom no',
        'stateroom',
      ],
    );

    final embarkation = _extractLabeledDateTime(
      text.lines,
      const <String>[
        'embarkation date',
        'embarkation',
        'sailing date',
        'start date',
      ],
    );
    final disembarkation = _extractLabeledDateTime(
      text.lines,
      const <String>[
        'disembarkation date',
        'disembarkation',
        'end date',
        'return date',
      ],
    );
    final range = _extractDateRange(
      text.lines,
      keywords: const <String>[
        'travel dates',
        'voyage dates',
        'cruise dates',
        'date range',
        'sailing dates',
        'itinerary',
      ],
    );

    final startDate = embarkation ?? range?.start;
    final endDate = disembarkation ?? range?.end;
    final deckInfo = _parseDeckInfo(
      _extractLabeledValue(
        text.lines,
        const <String>['deck number', 'deck no', 'deck name', 'deck'],
      ),
    );

    var signalCount = 0;
    if (hasCruiseKeyword) {
      signalCount++;
    }
    if (hasBookingKeyword) {
      signalCount++;
    }
    if (shipName != null) {
      signalCount++;
    }
    if (cabinNumber != null) {
      signalCount++;
    }
    if (startDate != null || endDate != null) {
      signalCount++;
    }
    if (hasEmbarkationKeyword) {
      signalCount++;
    }

    final isStrongSignal =
        (hasCruiseKeyword &&
            signalCount >= 3 &&
            (shipName != null ||
                cabinNumber != null ||
                startDate != null ||
                endDate != null ||
                hasEmbarkationKeyword)) ||
        (shipName != null &&
            cabinNumber != null &&
            hasBookingKeyword &&
            (startDate != null || endDate != null || hasEmbarkationKeyword));

    if (!isStrongSignal) {
      return null;
    }

    final title = _sanitizeTitleCandidate(
      _extractLabeledValue(
            text.lines,
            const <String>['cruise', 'voyage', 'itinerary title'],
          ) ??
          shipName,
      const <String>[
        'cruise',
        'voyage',
        'booking',
        'reservation',
        'confirmation',
      ],
    );

    final score = _capScore(
      0.68 +
          (hasCruiseKeyword ? 0.08 : 0) +
          (shipName != null ? 0.08 : 0) +
          (cabinNumber != null ? 0.06 : 0) +
          (startDate != null && endDate != null ? 0.08 : 0) +
          (operatorName != null ? 0.03 : 0),
    );
    final confidence = DocumentDraftConfidence(
      score: score,
      reason: 'Matched strong local cruise booking signals.',
    );

    return _DraftCandidate(
      score: score,
      confidence: confidence,
      draft: DocumentImportDraft(
        targetType: DocumentDraftTargetType.cruise,
        sourceReference: input.sourceReference,
        confidence: confidence,
        cruise: CruiseImportDraft(
          title: title,
          shipName: shipName,
          operatorName: operatorName,
          startDate: startDate,
          endDate: endDate,
          cabinNumber: cabinNumber,
          deckNumber: deckInfo.deckNumber,
          deckName: deckInfo.deckName,
        ),
      ),
    );
  }

  _DraftCandidate? _analyzeExcursion(
    DocumentAnalysisInput input,
    _AnalyzedDocumentText text,
  ) {
    final hasExcursionKeyword = text.containsAny(const <String>[
      'excursion',
      'shore excursion',
    ]);
    final hasTourKeyword = text.containsAny(const <String>['tour']);
    final hasVoucherKeyword = text.containsAny(const <String>[
      'voucher',
      'ticket',
    ]);
    final meetingPoint = _extractLabeledValue(
      text.lines,
      const <String>['meeting point', 'meeting location'],
    );
    final port = _extractLabeledValue(
      text.lines,
      const <String>['port', 'harbour', 'harbor'],
    );
    final date = _extractLabeledDateTime(
          text.lines,
          const <String>['excursion date', 'tour date', 'date'],
        ) ??
        _extractContextualDateTime(
          text.lines,
          const <String>[
            'excursion',
            'tour',
            'voucher',
            'meeting point',
            'port',
          ],
        );

    var signalCount = 0;
    if (hasExcursionKeyword || hasTourKeyword) {
      signalCount++;
    }
    if (hasVoucherKeyword) {
      signalCount++;
    }
    if (meetingPoint != null) {
      signalCount++;
    }
    if (port != null) {
      signalCount++;
    }
    if (date != null) {
      signalCount++;
    }

    final isStrongSignal =
        (hasExcursionKeyword || (hasTourKeyword && hasVoucherKeyword)) &&
        signalCount >= 3 &&
        (meetingPoint != null || port != null || date != null);

    if (!isStrongSignal) {
      return null;
    }

    final title = _sanitizeTitleCandidate(
      _extractLabeledValue(
        text.lines,
        const <String>['excursion', 'tour', 'activity'],
      ),
      const <String>[
        'excursion',
        'tour',
        'voucher',
        'ticket',
      ],
    );
    final notes = _extractShortNote(
      text.lines,
      const <String>['notes', 'note', 'remarks', 'important', 'bring'],
    );
    final score = _capScore(
      0.66 +
          (hasExcursionKeyword ? 0.08 : 0) +
          (hasVoucherKeyword ? 0.07 : 0) +
          (meetingPoint != null ? 0.06 : 0) +
          (port != null ? 0.04 : 0) +
          (date != null ? 0.05 : 0),
    );
    final confidence = DocumentDraftConfidence(
      score: score,
      reason: 'Matched strong local excursion voucher signals.',
    );

    return _DraftCandidate(
      score: score,
      confidence: confidence,
      draft: DocumentImportDraft(
        targetType: DocumentDraftTargetType.excursion,
        sourceReference: input.sourceReference,
        confidence: confidence,
        excursion: ExcursionImportDraft(
          title: title,
          date: date,
          port: port,
          meetingPoint: meetingPoint,
          notes: notes,
        ),
      ),
    );
  }

  _DraftCandidate? _analyzeHotel(
    DocumentAnalysisInput input,
    _AnalyzedDocumentText text,
  ) {
    final hasHotelKeyword = text.containsAny(const <String>[
      'hotel',
      'reservation',
      'booking',
      'check in',
      'check out',
    ]);
    final hotelName = _sanitizeTitleCandidate(
      _extractLabeledValue(
        text.lines,
        const <String>['hotel', 'property', 'accommodation'],
      ),
      const <String>['hotel', 'reservation', 'booking', 'confirmation'],
    );
    final checkInValue = _extractTemporalTextValue(
      text.lines,
      const <String>['check-in', 'check in', 'arrival date'],
    );
    final checkOutValue = _extractTemporalTextValue(
      text.lines,
      const <String>['check-out', 'check out', 'departure date'],
    );
    final reservationValue = _extractTokenValue(
      text.lines,
      const <String>[
        'reservation number',
        'reservation no',
        'booking reference',
        'confirmation number',
        'confirmation no',
      ],
    );

    final hasCheckInSignal =
        checkInValue.found || text.containsAny(const <String>['check in']);
    final hasCheckOutSignal =
        checkOutValue.found || text.containsAny(const <String>['check out']);
    final hasReservationSignal = reservationValue != null ||
        text.containsAny(
          const <String>['reservation', 'booking', 'confirmation'],
        );

    final isStrongSignal =
        (hasHotelKeyword || hotelName != null) &&
        hasCheckInSignal &&
        hasCheckOutSignal &&
        hasReservationSignal;

    if (!isStrongSignal) {
      return null;
    }

    final location = _extractLabeledValue(
      text.lines,
      const <String>['location', 'city'],
    );
    final address = _extractLabeledValue(
      text.lines,
      const <String>['address'],
    );
    final company = _extractLabeledValue(
      text.lines,
      const <String>['provider', 'booked via', 'company'],
    );
    final notes = _extractShortNote(
      text.lines,
      const <String>['notes', 'note', 'remarks'],
    );
    final score = _capScore(
      0.67 +
          (hotelName != null ? 0.08 : 0) +
          (checkInValue.dateTime != null ? 0.05 : 0) +
          (checkOutValue.dateTime != null ? 0.05 : 0) +
          (reservationValue != null ? 0.05 : 0),
    );
    final confidence = DocumentDraftConfidence(
      score: score,
      reason: 'Matched strong local hotel reservation signals.',
    );

    return _DraftCandidate(
      score: score,
      confidence: confidence,
      draft: DocumentImportDraft(
        targetType: DocumentDraftTargetType.hotel,
        sourceReference: input.sourceReference,
        confidence: confidence,
        travel: TravelImportDraft(
          start: checkInValue.dateTime,
          end: checkOutValue.dateTime,
          name: hotelName,
          location: location ?? checkInValue.text ?? checkOutValue.text,
          address: address,
          recordLocator: reservationValue,
          company: company,
          notes: notes,
        ),
      ),
    );
  }

  _DraftCandidate? _analyzeFlight(
    DocumentAnalysisInput input,
    _AnalyzedDocumentText text,
  ) {
    final hasFlightKeyword = text.containsAny(const <String>[
      'flight',
      'boarding pass',
      'passenger',
      'departure',
      'arrival',
    ]);
    final departure = _extractTemporalTextValue(
      text.lines,
      const <String>['departure'],
    );
    final arrival = _extractTemporalTextValue(
      text.lines,
      const <String>['arrival'],
    );
    final flightNo = _extractTokenValue(
      text.lines,
      const <String>['flight number', 'flight no'],
    );
    final carrier = _extractLabeledValue(
      text.lines,
      const <String>['airline', 'carrier'],
    );
    final recordLocator = _extractTokenValue(
      text.lines,
      const <String>[
        'record locator',
        'booking reference',
        'reservation code',
        'pnr',
      ],
    );

    final hasRouteSignal = departure.found && arrival.found;
    final hasPassengerSignal = text.containsAny(const <String>[
      'boarding',
      'passenger',
    ]);
    final isStrongSignal =
        hasFlightKeyword &&
        (flightNo != null || hasRouteSignal) &&
        (recordLocator != null || carrier != null || hasPassengerSignal);

    if (!isStrongSignal) {
      return null;
    }

    final from = _extractLabeledValue(text.lines, const <String>['from']) ??
        departure.text;
    final to = _extractLabeledValue(text.lines, const <String>['to']) ??
        arrival.text;
    final notes = _extractShortNote(
      text.lines,
      const <String>['notes', 'note', 'remarks'],
    );
    final score = _capScore(
      0.68 +
          (flightNo != null ? 0.08 : 0) +
          (departure.dateTime != null ? 0.05 : 0) +
          (arrival.dateTime != null ? 0.05 : 0) +
          (recordLocator != null ? 0.05 : 0) +
          (carrier != null ? 0.03 : 0),
    );
    final confidence = DocumentDraftConfidence(
      score: score,
      reason: 'Matched strong local flight confirmation signals.',
    );

    return _DraftCandidate(
      score: score,
      confidence: confidence,
      draft: DocumentImportDraft(
        targetType: DocumentDraftTargetType.flight,
        sourceReference: input.sourceReference,
        confidence: confidence,
        travel: TravelImportDraft(
          start: departure.dateTime,
          end: arrival.dateTime,
          from: from,
          to: to,
          carrier: carrier,
          flightNo: flightNo,
          recordLocator: recordLocator,
          notes: notes,
        ),
      ),
    );
  }

  _DeckInfo _parseDeckInfo(String? value) {
    final normalized = _normalizeExtractedValue(value);
    if (normalized == null) {
      return const _DeckInfo();
    }

    if (RegExp(r'^\d+[a-zA-Z]?$').hasMatch(normalized)) {
      return _DeckInfo(deckNumber: normalized);
    }

    final numberMatch = RegExp(r'\b\d+[a-zA-Z]?\b').firstMatch(normalized);
    final deckNumber = numberMatch?.group(0);
    final deckName = _normalizeExtractedValue(
      normalized.replaceFirst(RegExp(r'\b\d+[a-zA-Z]?\b'), ''),
    );

    return _DeckInfo(
      deckNumber: deckNumber,
      deckName: deckName ?? normalized,
    );
  }

  DateTime? _extractLabeledDateTime(
    List<String> lines,
    List<String> labels,
  ) {
    return _extractTemporalTextValue(lines, labels).dateTime;
  }

  _TemporalTextValue _extractTemporalTextValue(
    List<String> lines,
    List<String> labels,
  ) {
    final labeledValue = _findLabeledValue(lines, labels);
    if (!labeledValue.found) {
      return const _TemporalTextValue();
    }

    final rawValue = labeledValue.value ?? '';
    final match = _findFirstDateMatch(rawValue);
    if (match == null) {
      return const _TemporalTextValue(found: true);
    }

    final remainder = _normalizeExtractedValue(
      rawValue
          .replaceRange(match.start, match.end, ' ')
          .replaceAll(RegExp(r'\s+'), ' '),
    );
    return _TemporalTextValue(
      found: true,
      dateTime: match.value,
      text: remainder,
    );
  }

  DateTime? _extractContextualDateTime(
    List<String> lines,
    List<String> keywords,
  ) {
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      final hasKeyword = keywords.any((keyword) => lowerLine.contains(keyword));
      if (!hasKeyword) {
        continue;
      }

      final match = _findFirstDateMatch(line);
      if (match != null) {
        return match.value;
      }
    }

    return null;
  }

  _DateRange? _extractDateRange(
    List<String> lines, {
    required List<String> keywords,
  }) {
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      final hasKeyword = keywords.any((keyword) => lowerLine.contains(keyword));
      if (!hasKeyword) {
        continue;
      }

      final matches = _findDateMatches(line);
      if (matches.length < 2) {
        continue;
      }

      final start = matches[0].value;
      final end = matches[1].value;
      if (end.isBefore(start)) {
        continue;
      }

      return _DateRange(start: start, end: end);
    }

    return null;
  }

  String? _extractLabeledValue(
    List<String> lines,
    List<String> labels,
  ) {
    final labeledValue = _findLabeledValue(lines, labels);
    return _normalizeExtractedValue(labeledValue.value);
  }

  String? _extractTokenValue(
    List<String> lines,
    List<String> labels,
  ) {
    final value = _extractLabeledValue(lines, labels);
    if (value == null) {
      return null;
    }

    final tokenMatch = RegExp(r'[A-Z0-9][A-Z0-9\-]{1,}').firstMatch(value);
    return tokenMatch?.group(0) ?? value;
  }

  _LabeledValue _findLabeledValue(
    List<String> lines,
    List<String> labels,
  ) {
    if (labels.isEmpty) {
      return const _LabeledValue();
    }

    final sortedLabels = <String>[...labels]
      ..sort((left, right) => right.length.compareTo(left.length));
    final pattern = RegExp(
      '^(?:${sortedLabels.map(_labelPattern).join('|')})'
      r'\s*(?:[:\-])\s*(.+)$',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match == null) {
        continue;
      }

      return _LabeledValue(
        found: true,
        value: match.group(1),
      );
    }

    return const _LabeledValue();
  }

  String _labelPattern(String value) {
    return RegExp.escape(value).replaceAll(r'\ ', r'[\s\-]+');
  }

  String? _extractShortNote(
    List<String> lines,
    List<String> labels,
  ) {
    return _shortSnippet(_extractLabeledValue(lines, labels));
  }

  String? _shortSnippet(String? value, {int maxLength = 120}) {
    final normalized = _normalizeExtractedValue(value);
    if (normalized == null) {
      return null;
    }

    if (normalized.length <= maxLength) {
      return normalized;
    }

    return '${normalized.substring(0, maxLength - 3).trim()}...';
  }

  String? _sanitizeTitleCandidate(
    String? value,
    List<String> genericWords,
  ) {
    final normalized = _normalizeExtractedValue(value);
    if (normalized == null) {
      return null;
    }

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    final filtered = tokens.where((token) {
      final lowerToken = token.toLowerCase();
      return !genericWords.any((word) => lowerToken == word);
    }).toList(growable: false);

    return filtered.isEmpty ? null : normalized;
  }

  String? _normalizeExtractedValue(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.isEmpty ? null : normalized;
  }

  _ParsedDateMatch? _findFirstDateMatch(String text) {
    final matches = _findDateMatches(text);
    return matches.isEmpty ? null : matches.first;
  }

  List<_ParsedDateMatch> _findDateMatches(String text) {
    final matches = <_ParsedDateMatch>[];
    final seen = <String>{};
    final patterns = <RegExp>[
      RegExp(r'\b\d{4}[./-]\d{1,2}[./-]\d{1,2}(?:[ T]\d{1,2}:\d{2})?\b'),
      RegExp(r'\b\d{1,2}[./-]\d{1,2}[./-]\d{4}(?:\s+\d{1,2}:\d{2})?\b'),
      RegExp(
        r'\b\d{1,2}\.?\s+[^0-9\s,.:/-]{3,}\s+\d{4}(?:\s+\d{1,2}:\d{2})?\b',
      ),
      RegExp(
        r'\b[^0-9\s,.:/-]{3,}\s+\d{1,2},?\s+\d{4}(?:\s+\d{1,2}:\d{2})?\b',
      ),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final raw = match.group(0);
        if (raw == null) {
          continue;
        }

        final parsed = _parseDateToken(raw);
        if (parsed == null) {
          continue;
        }

        final key = '${match.start}:${match.end}:${parsed.toIso8601String()}';
        if (!seen.add(key)) {
          continue;
        }

        matches.add(
          _ParsedDateMatch(
            start: match.start,
            end: match.end,
            value: parsed,
          ),
        );
      }
    }

    matches.sort((left, right) => left.start.compareTo(right.start));
    return matches;
  }

  DateTime? _parseDateToken(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final timeMatch =
        RegExp(r'(?:[ T])(\d{1,2}:\d{2})$').firstMatch(normalized);
    final timePart = timeMatch?.group(1);
    final datePart = timeMatch == null
        ? normalized
        : normalized.substring(0, timeMatch.start).trim();
    final time = _parseTimeOfDay(timePart);

    final isoMatch =
        RegExp(r'^(\d{4})[./-](\d{1,2})[./-](\d{1,2})$').firstMatch(datePart);
    if (isoMatch != null) {
      return _buildDateTime(
        year: int.parse(isoMatch.group(1)!),
        month: int.parse(isoMatch.group(2)!),
        day: int.parse(isoMatch.group(3)!),
        time: time,
      );
    }

    final numericMatch =
        RegExp(r'^(\d{1,2})([./-])(\d{1,2})\2(\d{4})$').firstMatch(datePart);
    if (numericMatch != null) {
      final first = int.parse(numericMatch.group(1)!);
      final separator = numericMatch.group(2)!;
      final second = int.parse(numericMatch.group(3)!);
      final year = int.parse(numericMatch.group(4)!);

      if (separator == '.') {
        return _buildDateTime(
          year: year,
          month: second,
          day: first,
          time: time,
        );
      }

      if (first > 12 && second <= 12) {
        return _buildDateTime(
          year: year,
          month: second,
          day: first,
          time: time,
        );
      }

      if (second > 12 && first <= 12) {
        return _buildDateTime(
          year: year,
          month: first,
          day: second,
          time: time,
        );
      }

      return null;
    }

    final englishMonthNameDate = _parseEnglishMonthNameDate(
      datePart,
      time: time,
    );
    if (englishMonthNameDate != null) {
      return englishMonthNameDate;
    }

    for (final locale in const <String>['en', 'de']) {
      for (final pattern in const <String>[
        'd MMM yyyy',
        'd MMMM yyyy',
        'd. MMM yyyy',
        'd. MMMM yyyy',
        'MMM d, yyyy',
        'MMMM d, yyyy',
        'MMM d yyyy',
        'MMMM d yyyy',
      ]) {
        try {
          final date = DateFormat(pattern, locale).parseStrict(datePart);
          return _buildDateTime(
            year: date.year,
            month: date.month,
            day: date.day,
            time: time,
          );
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  DateTime? _parseEnglishMonthNameDate(
    String value, {
    required _TimeOfDayParts? time,
  }) {
    final match = RegExp(
      r'^(\d{1,2})\.?\s+([A-Za-z]+)\.?\s+(\d{4})$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final day = int.parse(match.group(1)!);
    final monthToken = match.group(2)!.toLowerCase();
    final year = int.parse(match.group(3)!);
    final month = _englishMonthNumbers[monthToken];
    if (month == null) {
      return null;
    }

    return _buildDateTime(
      year: year,
      month: month,
      day: day,
      time: time,
    );
  }

  _TimeOfDayParts? _parseTimeOfDay(String? value) {
    if (value == null) {
      return null;
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      return null;
    }

    return _TimeOfDayParts(hour: hour, minute: minute);
  }

  DateTime? _buildDateTime({
    required int year,
    required int month,
    required int day,
    required _TimeOfDayParts? time,
  }) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final value = DateTime(
      year,
      month,
      day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
    if (value.year != year || value.month != month || value.day != day) {
      return null;
    }

    return value;
  }

  double _capScore(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 0.95) {
      return 0.95;
    }
    return value;
  }
}

class NoOpDocumentSemanticAnalyzer extends DocumentSemanticAnalyzer {
  const NoOpDocumentSemanticAnalyzer();

  @override
  Future<DocumentAnalysisResult> analyze({
    required DocumentAnalysisInput input,
    required DocumentTextExtractionResult textExtractionResult,
  }) async {
    return DocumentAnalysisResult(
      sourceReference: input.sourceReference,
    );
  }
}

class _DraftCandidate {
  final double score;
  final DocumentDraftConfidence confidence;
  final DocumentImportDraft draft;

  const _DraftCandidate({
    required this.score,
    required this.confidence,
    required this.draft,
  });
}

class _AnalyzedDocumentText {
  final List<String> lines;
  final String _searchText;

  bool get hasText => _searchText.trim().isNotEmpty;

  const _AnalyzedDocumentText._({
    required this.lines,
    required String searchText,
  }) : _searchText = searchText;

  factory _AnalyzedDocumentText.from(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final searchText = lines
        .join(' ')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return _AnalyzedDocumentText._(
      lines: lines,
      searchText: ' $searchText ',
    );
  }

  bool containsAny(List<String> keywords) {
    return keywords.any(containsKeyword);
  }

  bool containsKeyword(String keyword) {
    final normalized = keyword
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return false;
    }

    return _searchText.contains(' $normalized ');
  }
}

class _LabeledValue {
  final bool found;
  final String? value;

  const _LabeledValue({
    this.found = false,
    this.value,
  });
}

class _TemporalTextValue {
  final bool found;
  final DateTime? dateTime;
  final String? text;

  const _TemporalTextValue({
    this.found = false,
    this.dateTime,
    this.text,
  });
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({
    required this.start,
    required this.end,
  });
}

class _ParsedDateMatch {
  final int start;
  final int end;
  final DateTime value;

  const _ParsedDateMatch({
    required this.start,
    required this.end,
    required this.value,
  });
}

class _TimeOfDayParts {
  final int hour;
  final int minute;

  const _TimeOfDayParts({
    required this.hour,
    required this.minute,
  });
}

class _DeckInfo {
  final String? deckNumber;
  final String? deckName;

  const _DeckInfo({
    this.deckNumber,
    this.deckName,
  });
}

const Map<String, int> _englishMonthNumbers = <String, int>{
  'jan': 1,
  'january': 1,
  'feb': 2,
  'february': 2,
  'mar': 3,
  'march': 3,
  'apr': 4,
  'april': 4,
  'may': 5,
  'jun': 6,
  'june': 6,
  'jul': 7,
  'july': 7,
  'aug': 8,
  'august': 8,
  'sep': 9,
  'sept': 9,
  'september': 9,
  'oct': 10,
  'october': 10,
  'nov': 11,
  'november': 11,
  'dec': 12,
  'december': 12,
};
