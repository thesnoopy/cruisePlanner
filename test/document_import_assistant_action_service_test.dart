import 'package:cruiseplanner/models/documents/document_draft_confidence.dart';
import 'package:cruiseplanner/models/documents/document_draft_match_result.dart';
import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_assistant_action.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/services/documents/document_import_assistant_action_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentImportAssistantActionService', () {
    const service = DocumentImportAssistantActionService();

    test('useExisting excursion match becomes an edit-existing action', () {
      final excursionDraft = ExcursionImportDraft(
        title: 'Island Tour Voucher',
        date: DateTime(2026, 7, 5),
        port: 'Nassau',
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.excursion,
          excursion: excursionDraft,
        ),
        action: DocumentDraftMatchAction.useExisting,
        matchedCruiseId: 'cruise-1',
        matchedItemId: 'exc-1',
      );

      final action = service.buildAction(result);

      expect(
        action.type,
        DocumentImportAssistantActionType.editExistingExcursion,
      );
      expect(action.excursionId, 'exc-1');
      expect(action.initialDraft, excursionDraft);
    });

    test('createNew excursion match with cruise id becomes a create-new action', () {
      final excursionDraft = ExcursionImportDraft(
        title: 'Beach Day',
        date: DateTime(2026, 7, 6),
        port: 'Cozumel',
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.excursion,
          excursion: excursionDraft,
        ),
        action: DocumentDraftMatchAction.createNew,
        matchedCruiseId: 'cruise-2',
      );

      final action = service.buildAction(result);

      expect(
        action.type,
        DocumentImportAssistantActionType.createNewExcursion,
      );
      expect(action.cruiseId, 'cruise-2');
      expect(action.initialDraft, excursionDraft);
    });

    test('useExisting travel match becomes an edit-existing travel action', () {
      final travelDraft = TravelImportDraft(
        start: DateTime(2026, 7, 7, 10),
        end: DateTime(2026, 7, 7, 12),
        from: 'Miami Airport',
        to: 'Port of Miami',
        notes: 'Terminal transfer',
        mode: 'shuttle',
      );
      const sourceReference = DocumentImportSourceReference(
        documentId: 'doc-travel-1',
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.transfer,
          sourceReference: sourceReference,
          travel: travelDraft,
        ),
        action: DocumentDraftMatchAction.useExisting,
        matchedCruiseId: 'cruise-5',
        matchedItemId: 'travel-1',
        matchedTargetType: DocumentDraftTargetType.transfer,
      );

      final action = service.buildAction(result);

      expect(
        action.type,
        DocumentImportAssistantActionType.editExistingTravel,
      );
      expect(action.travelItemId, 'travel-1');
      expect(action.draftTargetType, DocumentDraftTargetType.transfer);
      expect(action.targetType, DocumentDraftTargetType.transfer);
      expect(action.initialTravelDraft, travelDraft);
      expect(action.sourceReference, sourceReference);
    });

    test('createNew travel match with cruise id becomes a create-new travel action', () {
      final travelDraft = TravelImportDraft(
        start: DateTime(2026, 7, 8, 14),
        end: DateTime(2026, 7, 10, 9),
        name: 'Harbor View Hotel',
        location: 'Barcelona',
        company: 'Harbor Stays',
        recordLocator: 'HV123',
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.hotel,
          travel: travelDraft,
        ),
        action: DocumentDraftMatchAction.createNew,
        matchedCruiseId: 'cruise-6',
        matchedTargetType: DocumentDraftTargetType.hotel,
      );

      final action = service.buildAction(result);

      expect(
        action.type,
        DocumentImportAssistantActionType.createNewTravel,
      );
      expect(action.cruiseId, 'cruise-6');
      expect(action.draftTargetType, DocumentDraftTargetType.hotel);
      expect(action.targetType, DocumentDraftTargetType.hotel);
      expect(action.initialTravelDraft, travelDraft);
    });

    test('manualReview returns a manual-review action', () {
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.excursion,
          excursion: ExcursionImportDraft(
            title: 'Unknown Excursion',
          ),
        ),
        action: DocumentDraftMatchAction.manualReview,
      );

      final action = service.buildAction(result);

      expect(action.type, DocumentImportAssistantActionType.manualReview);
      expect(action.requiresManualReview, isTrue);
      expect(action.isSupported, isFalse);
    });

    test('unsupported non-travel and non-excursion draft returns unsupported', () {
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.cruise,
          cruise: CruiseImportDraft(
            title: 'Summer Cruise',
          ),
        ),
        action: DocumentDraftMatchAction.createNew,
        matchedCruiseId: 'cruise-3',
        matchedTargetType: DocumentDraftTargetType.cruise,
      );

      final action = service.buildAction(result);

      expect(action.type, DocumentImportAssistantActionType.unsupported);
      expect(action.isSupported, isFalse);
    });

    test('sourceReference is preserved', () {
      const sourceReference = DocumentImportSourceReference(
        documentId: 'doc-1',
        pendingShareBatchId: 'share-1',
        pendingShareItemIndex: 2,
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.excursion,
          sourceReference: sourceReference,
          excursion: ExcursionImportDraft(
            title: 'Snorkeling',
          ),
        ),
        action: DocumentDraftMatchAction.useExisting,
        matchedCruiseId: 'cruise-4',
        matchedItemId: 'exc-4',
      );

      final action = service.buildAction(result);

      expect(action.sourceReference, sourceReference);
    });
  });
}

DocumentDraftMatchResult _buildMatchResult({
  required DocumentImportDraft draft,
  required DocumentDraftMatchAction action,
  DocumentDraftTargetType? matchedTargetType,
  String? matchedCruiseId,
  String? matchedItemId,
}) {
  return DocumentDraftMatchResult(
    draft: draft,
    matchedCruiseId: matchedCruiseId,
    matchedItemId: matchedItemId,
    matchedTargetType: matchedTargetType ?? draft.targetType,
    action: action,
    confidence: const DocumentDraftConfidence(
      score: 0.9,
      reason: 'test',
    ),
  );
}
