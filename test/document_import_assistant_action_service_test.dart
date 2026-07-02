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

    test('maps existing port call match to editExistingRouteItem', () {
      final routeDraft = RouteItemImportDraft(
        date: DateTime(2026, 7, 9),
        portName: 'Palma',
        arrival: DateTime(2026, 7, 9, 8),
        departure: DateTime(2026, 7, 9, 18),
      );
      const sourceReference = DocumentImportSourceReference(
        documentId: 'doc-route-1',
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.portCall,
          sourceReference: sourceReference,
          routeItem: routeDraft,
        ),
        action: DocumentDraftMatchAction.useExisting,
        matchedCruiseId: 'cruise-route-1',
        matchedRouteItemId: 'route-1',
        matchedTargetType: DocumentDraftTargetType.portCall,
      );

      final action = service.buildAction(result);

      expect(
        action.type,
        DocumentImportAssistantActionType.editExistingRouteItem,
      );
      expect(action.cruiseId, 'cruise-route-1');
      expect(action.routeItemId, 'route-1');
      expect(action.draftTargetType, DocumentDraftTargetType.portCall);
      expect(action.targetType, DocumentDraftTargetType.portCall);
      expect(action.initialRouteItemDraft, routeDraft);
      expect(action.sourceReference, sourceReference);
    });

    test('maps new port call draft with cruiseId to createNewRouteItem', () {
      final routeDraft = RouteItemImportDraft(
        date: DateTime(2026, 7, 10),
        portName: 'Marseille',
        notes: 'Shuttle timings on ticket',
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.portCall,
          routeItem: routeDraft,
        ),
        action: DocumentDraftMatchAction.createNew,
        matchedCruiseId: 'cruise-route-2',
        matchedTargetType: DocumentDraftTargetType.portCall,
      );

      final action = service.buildAction(result);

      expect(
        action.type,
        DocumentImportAssistantActionType.createNewRouteItem,
      );
      expect(action.cruiseId, 'cruise-route-2');
      expect(action.routeItemId, isNull);
      expect(action.draftTargetType, DocumentDraftTargetType.portCall);
      expect(action.targetType, DocumentDraftTargetType.portCall);
      expect(action.initialRouteItemDraft, routeDraft);
    });

    test('maps existing sea day match to editExistingRouteItem', () {
      final routeDraft = RouteItemImportDraft(
        date: DateTime(2026, 7, 11),
        notes: 'Formal night',
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.seaDay,
          routeItem: routeDraft,
        ),
        action: DocumentDraftMatchAction.useExisting,
        matchedCruiseId: 'cruise-route-3',
        matchedRouteItemId: 'sea-1',
        matchedTargetType: DocumentDraftTargetType.seaDay,
      );

      final action = service.buildAction(result);

      expect(
        action.type,
        DocumentImportAssistantActionType.editExistingRouteItem,
      );
      expect(action.cruiseId, 'cruise-route-3');
      expect(action.routeItemId, 'sea-1');
      expect(action.draftTargetType, DocumentDraftTargetType.seaDay);
      expect(action.targetType, DocumentDraftTargetType.seaDay);
      expect(action.initialRouteItemDraft, routeDraft);
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

    test('maps existing cruise match to editExistingCruise', () {
      final cruiseDraft = CruiseImportDraft(
        title: 'Summer Cruise',
        shipName: 'Ocean Star',
        startDate: DateTime(2026, 7, 13),
        endDate: DateTime(2026, 7, 20),
      );
      const sourceReference = DocumentImportSourceReference(
        documentId: 'doc-cruise-1',
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.cruise,
          sourceReference: sourceReference,
          cruise: cruiseDraft,
        ),
        action: DocumentDraftMatchAction.useExisting,
        matchedCruiseId: 'cruise-3',
        matchedTargetType: DocumentDraftTargetType.cruise,
      );

      final action = service.buildAction(result);

      expect(action.type, DocumentImportAssistantActionType.editExistingCruise);
      expect(action.cruiseId, 'cruise-3');
      expect(action.draftTargetType, DocumentDraftTargetType.cruise);
      expect(action.targetType, DocumentDraftTargetType.cruise);
      expect(action.initialCruiseDraft, cruiseDraft);
      expect(action.sourceReference, sourceReference);
      expect(action.isSupported, isTrue);
    });

    test(
      'maps new cruise draft to createNewCruise without requiring matchedCruiseId',
      () {
        final cruiseDraft = CruiseImportDraft(
          title: 'Autumn Voyage',
          shipName: 'Sea Breeze',
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 8),
        );
        final result = _buildMatchResult(
          draft: DocumentImportDraft(
            targetType: DocumentDraftTargetType.cruise,
            cruise: cruiseDraft,
          ),
          action: DocumentDraftMatchAction.createNew,
          matchedTargetType: DocumentDraftTargetType.cruise,
        );

        final action = service.buildAction(result);

        expect(action.type, DocumentImportAssistantActionType.createNewCruise);
        expect(action.cruiseId, isNull);
        expect(action.draftTargetType, DocumentDraftTargetType.cruise);
        expect(action.targetType, DocumentDraftTargetType.cruise);
        expect(action.initialCruiseDraft, cruiseDraft);
        expect(action.isSupported, isTrue);
      },
    );

    test('does not edit existing cruise without matchedCruiseId', () {
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.cruise,
          cruise: CruiseImportDraft(
            title: 'Winter Cruise',
          ),
        ),
        action: DocumentDraftMatchAction.useExisting,
        matchedTargetType: DocumentDraftTargetType.cruise,
      );

      final action = service.buildAction(result);

      expect(action.type, DocumentImportAssistantActionType.unsupported);
      expect(action.isSupported, isFalse);
    });

    test('does not create route item action without cruiseId', () {
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.seaDay,
          routeItem: RouteItemImportDraft(
            date: DateTime(2026, 7, 12),
            notes: 'At sea all day',
          ),
        ),
        action: DocumentDraftMatchAction.createNew,
        matchedTargetType: DocumentDraftTargetType.seaDay,
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

    test('sourceReference is preserved for cruise actions', () {
      const sourceReference = DocumentImportSourceReference(
        documentId: 'doc-cruise-2',
        pendingShareBatchId: 'share-cruise-1',
        pendingShareItemIndex: 1,
      );
      final result = _buildMatchResult(
        draft: DocumentImportDraft(
          targetType: DocumentDraftTargetType.cruise,
          sourceReference: sourceReference,
          cruise: CruiseImportDraft(
            title: 'Northern Lights Cruise',
          ),
        ),
        action: DocumentDraftMatchAction.createNew,
        matchedCruiseId: 'cruise-7',
        matchedTargetType: DocumentDraftTargetType.cruise,
      );

      final action = service.buildAction(result);

      expect(action.type, DocumentImportAssistantActionType.createNewCruise);
      expect(action.cruiseId, 'cruise-7');
      expect(action.sourceReference, sourceReference);
    });
  });
}

DocumentDraftMatchResult _buildMatchResult({
  required DocumentImportDraft draft,
  required DocumentDraftMatchAction action,
  DocumentDraftTargetType? matchedTargetType,
  String? matchedCruiseId,
  String? matchedRouteItemId,
  String? matchedItemId,
}) {
  return DocumentDraftMatchResult(
    draft: draft,
    matchedCruiseId: matchedCruiseId,
    matchedRouteItemId: matchedRouteItemId,
    matchedItemId: matchedItemId,
    matchedTargetType: matchedTargetType ?? draft.targetType,
    action: action,
    confidence: const DocumentDraftConfidence(
      score: 0.9,
      reason: 'test',
    ),
  );
}
