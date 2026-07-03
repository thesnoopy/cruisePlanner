import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/documents/document_analysis_input.dart';
import '../../models/documents/document_analysis_result.dart';
import '../../models/documents/document_import_source_reference.dart';
import '../../models/documents/document_record.dart';
import '../../services/documents/document_analysis_service.dart';
import '../../services/documents/document_import_assistant_action_navigator.dart';
import '../../services/documents/document_import_assistant_flow_service.dart';
import 'document_import_assistant_action_review.dart';

class DocumentImportAssistantDocumentLauncher {
  const DocumentImportAssistantDocumentLauncher({
    this.analysisService,
    this.flowService,
    this.navigator = const DocumentImportAssistantActionNavigator(),
  });

  final DocumentAnalysisService? analysisService;
  final DocumentImportAssistantFlowService? flowService;
  final DocumentImportAssistantActionNavigator navigator;

  Future<bool> startForDocument({
    required BuildContext context,
    required DocumentRecord document,
  }) async {
    final loc = AppLocalizations.of(context)!;

    try {
      final analysisResult =
          await (analysisService ?? DocumentAnalysisService()).analyze(
        DocumentAnalysisInput(
          sourceReference: DocumentImportSourceReference(
            documentId: document.id,
          ),
          documentId: document.id,
          originalFileName: document.originalFileName,
          title: document.title,
          mimeType: document.mimeType,
          localRelativePath: document.localRelativePath,
        ),
      );

      if (!context.mounted) {
        return false;
      }

      return showDocumentImportAssistantForAnalysisResult(
        context: context,
        analysisResult: analysisResult,
        flowService: flowService,
        navigator: navigator,
      );
    } catch (_) {
      if (!context.mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.documentImportAssistantStartFailed),
        ),
      );
      return false;
    }
  }
}

Future<bool> showDocumentImportAssistantForAnalysisResult({
  required BuildContext context,
  required DocumentAnalysisResult analysisResult,
  DocumentImportAssistantFlowService? flowService,
  DocumentImportAssistantActionNavigator navigator =
      const DocumentImportAssistantActionNavigator(),
}) async {
  final resolvedFlowService =
      flowService ?? DocumentImportAssistantFlowService();
  final action = await resolvedFlowService.buildAction(analysisResult);

  if (!context.mounted) {
    return false;
  }

  return showDocumentImportAssistantActionReviewDialog(
    context: context,
    action: action,
    navigator: navigator,
  );
}
