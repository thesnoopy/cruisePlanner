import 'package:cruiseplanner/models/documents/document_analysis_result.dart';
import 'package:cruiseplanner/models/documents/document_draft_confidence.dart';
import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentAnalysisResult', () {
    test('keeps the primary draft and source reference metadata', () {
      const draft = DocumentImportDraft(
        targetType: DocumentDraftTargetType.excursion,
        sourceReference: DocumentImportSourceReference(
          pendingShareBatchId: 'batch-1',
          pendingShareItemIndex: 2,
        ),
        confidence: DocumentDraftConfidence(
          score: 0.92,
          reason: 'matched excursion booking keywords',
        ),
        existingCruiseId: 'cruise-1',
        existingItemId: 'excursion-1',
        excursion: ExcursionImportDraft(
          title: 'Island tour',
          port: 'Nassau',
        ),
      );

      const result = DocumentAnalysisResult(
        sourceReference: DocumentImportSourceReference(
          pendingShareBatchId: 'batch-1',
          pendingShareItemIndex: 2,
        ),
        drafts: <DocumentImportDraft>[draft],
      );

      expect(result.hasDrafts, isTrue);
      expect(result.primaryDraft, draft);
      expect(result.sourceReference.hasPendingShareReference, isTrue);
      expect(result.primaryDraft!.existingCruiseId, 'cruise-1');
      expect(result.primaryDraft!.existingItemId, 'excursion-1');
      expect(result.primaryDraft!.confidence!.score, 0.92);
    });
  });

  group('DocumentImportDraft', () {
    test('can switch to a document-only fallback draft', () {
      final draft = const DocumentImportDraft(
        targetType: DocumentDraftTargetType.flight,
        sourceReference: DocumentImportSourceReference(documentId: 'doc-1'),
        travel: TravelImportDraft(
          from: 'HAM',
          to: 'BCN',
        ),
      ).copyWith(
        targetType: DocumentDraftTargetType.documentOnly,
        travel: null,
      );

      expect(draft.isDocumentOnly, isTrue);
      expect(draft.travel, isNull);
      expect(draft.sourceReference.hasDocumentId, isTrue);
    });
  });

  group('DocumentDraftTargetTypeX', () {
    test('classifies route and travel targets', () {
      expect(DocumentDraftTargetType.portCall.isRouteItemTarget, isTrue);
      expect(DocumentDraftTargetType.seaDay.isRouteItemTarget, isTrue);
      expect(DocumentDraftTargetType.hotel.isTravelTarget, isTrue);
      expect(DocumentDraftTargetType.excursion.isTravelTarget, isFalse);
    });
  });
}
