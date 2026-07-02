import 'package:flutter/material.dart';

import '../../models/documents/document_analysis_result.dart';
import '../../services/documents/document_import_assistant_action_navigator.dart';
import '../../services/documents/document_import_assistant_flow_service.dart';
import 'document_import_assistant_action_review.dart';

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
