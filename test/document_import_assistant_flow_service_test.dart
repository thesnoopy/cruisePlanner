import 'package:cruiseplanner/models/cruise.dart';
import 'package:cruiseplanner/models/documents/document_analysis_result.dart';
import 'package:cruiseplanner/models/documents/document_draft_target_type.dart';
import 'package:cruiseplanner/models/documents/document_import_assistant_action.dart';
import 'package:cruiseplanner/models/documents/document_import_draft.dart';
import 'package:cruiseplanner/models/documents/document_import_source_reference.dart';
import 'package:cruiseplanner/models/excursion.dart';
import 'package:cruiseplanner/models/period.dart';
import 'package:cruiseplanner/models/ship.dart';
import 'package:cruiseplanner/services/documents/document_import_assistant_flow_service.dart';
import 'package:cruiseplanner/store/cruise_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentImportAssistantFlowService', () {
    test('turns an excursion analysis result into an edit action', () async {
      final cruiseStore = _FakeCruiseStore(
        cruises: <Cruise>[
          _buildCruise(
            id: 'cruise-1',
            excursions: <Excursion>[
              Excursion(
                id: 'exc-1',
                title: 'Island Tour',
                date: DateTime(2026, 7, 5),
                port: 'Nassau',
              ),
            ],
          ),
        ],
      );
      final service = DocumentImportAssistantFlowService(
        cruiseStore: cruiseStore,
      );
      final analysisResult = DocumentAnalysisResult(
        sourceReference: const DocumentImportSourceReference(
          documentId: 'doc-exc-1',
        ),
        drafts: <DocumentImportDraft>[
          DocumentImportDraft(
            targetType: DocumentDraftTargetType.excursion,
            excursion: ExcursionImportDraft(
              title: 'Island Tour Voucher',
              date: DateTime(2026, 7, 5),
              port: 'Nassau',
            ),
          ),
        ],
      );

      final action = await service.buildAction(analysisResult);

      expect(
        action.type,
        DocumentImportAssistantActionType.editExistingExcursion,
      );
      expect(action.excursionId, 'exc-1');
      expect(action.sourceReference, analysisResult.sourceReference);
    });

    test(
      'turns a cruise analysis result into createNewCruise without matchedCruiseId',
      () async {
        final service = DocumentImportAssistantFlowService(
          cruiseStore: _FakeCruiseStore(),
        );
        final analysisResult = DocumentAnalysisResult(
          sourceReference: const DocumentImportSourceReference(
            documentId: 'doc-cruise-1',
          ),
          drafts: <DocumentImportDraft>[
            DocumentImportDraft(
              targetType: DocumentDraftTargetType.cruise,
              cruise: CruiseImportDraft(
                title: 'Autumn Voyage',
                shipName: 'Sea Breeze',
                startDate: DateTime(2026, 9, 1),
                endDate: DateTime(2026, 9, 8),
              ),
            ),
          ],
        );

        final action = await service.buildAction(analysisResult);

        expect(action.type, DocumentImportAssistantActionType.createNewCruise);
        expect(action.cruiseId, isNull);
        expect(action.initialCruiseDraft, analysisResult.primaryDraft!.cruise);
      },
    );

    test('returns unsupported when no usable draft is present', () async {
      const sourceReference = DocumentImportSourceReference(
        pendingShareBatchId: 'batch-1',
        pendingShareItemIndex: 0,
      );
      final service = DocumentImportAssistantFlowService(
        cruiseStore: _FakeCruiseStore(),
      );

      final action = await service.buildAction(
        const DocumentAnalysisResult(sourceReference: sourceReference),
      );

      expect(action.type, DocumentImportAssistantActionType.unsupported);
      expect(action.sourceReference, sourceReference);
    });

    test('returns manualReview for an unknown draft target', () async {
      const sourceReference = DocumentImportSourceReference(
        documentId: 'doc-unknown-1',
      );
      final cruiseStore = _FakeCruiseStore(isLoaded: false);
      final service = DocumentImportAssistantFlowService(
        cruiseStore: cruiseStore,
      );

      final action = await service.buildAction(
        const DocumentAnalysisResult(
          sourceReference: sourceReference,
          drafts: <DocumentImportDraft>[
            DocumentImportDraft(
              targetType: DocumentDraftTargetType.unknown,
            ),
          ],
        ),
      );

      expect(action.type, DocumentImportAssistantActionType.manualReview);
      expect(action.sourceReference, sourceReference);
      expect(cruiseStore.loadCallCount, 0);
    });

    test(
      'preserves the analysis sourceReference through matching and action',
      () async {
        const sourceReference = DocumentImportSourceReference(
          documentId: 'doc-source-1',
          pendingShareBatchId: 'batch-source-1',
          pendingShareItemIndex: 3,
        );
        final service = DocumentImportAssistantFlowService(
          cruiseStore: _FakeCruiseStore(
            cruises: <Cruise>[
              _buildCruise(
                id: 'cruise-2',
                excursions: <Excursion>[
                  Excursion(
                    id: 'exc-2',
                    title: 'Snorkeling',
                    date: DateTime(2026, 8, 12),
                    port: 'Cozumel',
                  ),
                ],
              ),
            ],
          ),
        );

        final action = await service.buildAction(
          DocumentAnalysisResult(
            sourceReference: sourceReference,
            drafts: <DocumentImportDraft>[
              DocumentImportDraft(
                targetType: DocumentDraftTargetType.excursion,
                sourceReference: DocumentImportSourceReference(),
                excursion: ExcursionImportDraft(
                  title: 'Snorkeling Tickets',
                  date: DateTime(2026, 8, 12),
                  port: 'Cozumel',
                ),
              ),
            ],
          ),
        );

        expect(
          action.type,
          DocumentImportAssistantActionType.editExistingExcursion,
        );
        expect(action.sourceReference, sourceReference);
      },
    );

    test('keeps an existing draft sourceReference when the result has none', () async {
      const sourceReference = DocumentImportSourceReference(
        documentId: 'doc-draft-only-1',
      );
      final service = DocumentImportAssistantFlowService(
        cruiseStore: _FakeCruiseStore(
          cruises: <Cruise>[
            _buildCruise(
              id: 'cruise-4',
              excursions: <Excursion>[
                Excursion(
                  id: 'exc-4',
                  title: 'Museum Visit',
                  date: DateTime(2026, 11, 4),
                  port: 'Cadiz',
                ),
              ],
            ),
          ],
        ),
      );

      final action = await service.buildAction(
        DocumentAnalysisResult(
          drafts: <DocumentImportDraft>[
            DocumentImportDraft(
              targetType: DocumentDraftTargetType.excursion,
              sourceReference: sourceReference,
              excursion: ExcursionImportDraft(
                title: 'Museum Visit Voucher',
                date: DateTime(2026, 11, 4),
                port: 'Cadiz',
              ),
            ),
          ],
        ),
      );

      expect(
        action.type,
        DocumentImportAssistantActionType.editExistingExcursion,
      );
      expect(action.sourceReference, sourceReference);
    });

    test(
      'does not require UI context or navigation and can load cruises on demand',
      () async {
        final cruiseStore = _FakeCruiseStore(
          isLoaded: false,
          cruises: <Cruise>[
            _buildCruise(
              id: 'cruise-3',
              excursions: <Excursion>[
                Excursion(
                  id: 'exc-3',
                  title: 'City Walk',
                  date: DateTime(2026, 10, 2),
                  port: 'Lisbon',
                ),
              ],
            ),
          ],
        );
        final service = DocumentImportAssistantFlowService(
          cruiseStore: cruiseStore,
        );

        final action = await service.buildAction(
          DocumentAnalysisResult(
            drafts: <DocumentImportDraft>[
              DocumentImportDraft(
                targetType: DocumentDraftTargetType.excursion,
                excursion: ExcursionImportDraft(
                  title: 'City Walk Confirmation',
                  date: DateTime(2026, 10, 2),
                  port: 'Lisbon',
                ),
              ),
            ],
          ),
        );

        expect(cruiseStore.loadCallCount, 1);
        expect(
          action.type,
          DocumentImportAssistantActionType.editExistingExcursion,
        );
      },
    );
  });
}

class _FakeCruiseStore extends CruiseStore {
  _FakeCruiseStore({
    List<Cruise> cruises = const <Cruise>[],
    bool isLoaded = true,
  })  : _cruises = cruises,
        _isLoaded = isLoaded;

  final List<Cruise> _cruises;
  bool _isLoaded;
  int loadCallCount = 0;

  @override
  bool get isLoaded => _isLoaded;

  @override
  List<Cruise> get cruises => List<Cruise>.unmodifiable(_cruises);

  @override
  List<Cruise> get activeCruises => List<Cruise>.unmodifiable(_cruises);

  @override
  Future<void> load() async {
    loadCallCount++;
    _isLoaded = true;
  }
}

Cruise _buildCruise({
  required String id,
  List<Excursion> excursions = const <Excursion>[],
}) {
  return Cruise(
    id: id,
    title: 'Test Cruise',
    ship: Ship(name: 'Test Ship'),
    period: Period(
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 12, 31),
    ),
    excursions: excursions,
  );
}
