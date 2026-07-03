import 'package:cruiseplanner/models/documents/document_analysis_input.dart';
import 'package:cruiseplanner/models/documents/document_analysis_result.dart';
import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/models/documents/document_text_extraction_result.dart';
import 'package:cruiseplanner/services/documents/document_semantic_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalRuleBasedDocumentSemanticAnalyzer', () {
    const analyzer = LocalRuleBasedDocumentSemanticAnalyzer();

    test('cruise booking text yields a cruise draft', () async {
      final result = await _analyzeText(
        analyzer,
        '''
Cruise: Mediterranean Escape
Booking confirmation
Cruise line: Oceanic Cruises
Ship: MV Aurora
Travel dates: 2026-09-10 - 2026-09-17
Cabin: 12034
Deck: 12
''',
      );

      expect(result.sourceReference, _sourceReference);
      expect(result.drafts, hasLength(1));
      expect(result.primaryDraft!.targetType, DocumentDraftTargetType.cruise);
      expect(result.primaryDraft!.cruise!.title, 'Mediterranean Escape');
      expect(result.primaryDraft!.cruise!.shipName, 'MV Aurora');
      expect(result.primaryDraft!.cruise!.operatorName, 'Oceanic Cruises');
      expect(result.primaryDraft!.cruise!.startDate, DateTime(2026, 9, 10));
      expect(result.primaryDraft!.cruise!.endDate, DateTime(2026, 9, 17));
      expect(result.primaryDraft!.cruise!.cabinNumber, '12034');
      expect(result.primaryDraft!.cruise!.deckNumber, '12');
    });

    test('excursion voucher text yields an excursion draft', () async {
      final result = await _analyzeText(
        analyzer,
        '''
Excursion: Coastal City Tour
Voucher
Date: 15 Oct 2026
Port: Cadiz
Meeting point: Terminal Gate B
Note: Bring sunscreen.
''',
      );

      expect(result.drafts, hasLength(1));
      expect(
        result.primaryDraft!.targetType,
        DocumentDraftTargetType.excursion,
      );
      expect(result.primaryDraft!.excursion!.title, 'Coastal City Tour');
      expect(result.primaryDraft!.excursion!.date, DateTime(2026, 10, 15));
      expect(result.primaryDraft!.excursion!.port, 'Cadiz');
      expect(
        result.primaryDraft!.excursion!.meetingPoint,
        'Terminal Gate B',
      );
      expect(result.primaryDraft!.excursion!.notes, 'Bring sunscreen.');
    });

    test('english long month names parse deterministically', () async {
      final result = await _analyzeText(
        analyzer,
        '''
Excursion: Coastal City Tour
Voucher
Date: 15 October 2026
Port: Cadiz
Meeting point: Terminal Gate B
''',
      );

      expect(result.drafts, hasLength(1));
      expect(
        result.primaryDraft!.targetType,
        DocumentDraftTargetType.excursion,
      );
      expect(result.primaryDraft!.excursion!.date, DateTime(2026, 10, 15));
    });

    test('hotel confirmation text yields a hotel travel draft', () async {
      final result = await _analyzeText(
        analyzer,
        '''
Hotel: Harbor View Hotel
Reservation confirmation
Check-in: 15.10.2026
Check-out: 18.10.2026
Reservation number: HTL42
Location: Barcelona
Address: 123 Port Avenue
''',
      );

      expect(result.drafts, hasLength(1));
      expect(result.primaryDraft!.targetType, DocumentDraftTargetType.hotel);
      expect(result.primaryDraft!.travel!.name, 'Harbor View Hotel');
      expect(result.primaryDraft!.travel!.start, DateTime(2026, 10, 15));
      expect(result.primaryDraft!.travel!.end, DateTime(2026, 10, 18));
      expect(result.primaryDraft!.travel!.recordLocator, 'HTL42');
      expect(result.primaryDraft!.travel!.location, 'Barcelona');
      expect(result.primaryDraft!.travel!.address, '123 Port Avenue');
    });

    test('flight confirmation text yields a flight travel draft', () async {
      final result = await _analyzeText(
        analyzer,
        '''
Flight confirmation
Airline: Lufthansa
Flight number: LH1234
Record locator: ZX81
Departure: Hamburg 2026-10-14 08:45
Arrival: Barcelona 2026-10-14 11:35
Passenger: Test Traveler
''',
      );

      expect(result.drafts, hasLength(1));
      expect(result.primaryDraft!.targetType, DocumentDraftTargetType.flight);
      expect(result.primaryDraft!.travel!.carrier, 'Lufthansa');
      expect(result.primaryDraft!.travel!.flightNo, 'LH1234');
      expect(result.primaryDraft!.travel!.recordLocator, 'ZX81');
      expect(result.primaryDraft!.travel!.from, 'Hamburg');
      expect(result.primaryDraft!.travel!.to, 'Barcelona');
      expect(
        result.primaryDraft!.travel!.start,
        DateTime(2026, 10, 14, 8, 45),
      );
      expect(
        result.primaryDraft!.travel!.end,
        DateTime(2026, 10, 14, 11, 35),
      );
    });

    test('unrelated text does not produce a supported draft', () async {
      final result = await _analyzeText(
        analyzer,
        '''
Packing list
2 shirts
1 camera
Call the pet sitter
''',
      );

      expect(result.drafts, isEmpty);
      expect(result.primaryDraft, isNull);
    });

    test('ambiguous date does not get guessed', () async {
      final result = await _analyzeText(
        analyzer,
        '''
Hotel: Harbor View Hotel
Reservation confirmation
Check-in: 03/04/2026
Check-out: 05/04/2026
Booking reference: ABC123
''',
      );

      expect(result.drafts, hasLength(1));
      expect(result.primaryDraft!.targetType, DocumentDraftTargetType.hotel);
      expect(result.primaryDraft!.travel!.name, 'Harbor View Hotel');
      expect(result.primaryDraft!.travel!.recordLocator, 'ABC123');
      expect(result.primaryDraft!.travel!.start, isNull);
      expect(result.primaryDraft!.travel!.end, isNull);
    });
  });
}

const _sourceReference = DocumentImportSourceReference(documentId: 'doc-1');

Future<DocumentAnalysisResult> _analyzeText(
  LocalRuleBasedDocumentSemanticAnalyzer analyzer,
  String text,
) {
  return analyzer.analyze(
    input: const DocumentAnalysisInput(
      sourceReference: _sourceReference,
    ),
    textExtractionResult: DocumentTextExtractionResult(
      extractedText: text,
    ),
  );
}
