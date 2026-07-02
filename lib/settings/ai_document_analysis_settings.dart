import 'dart:convert';

import 'package:equatable/equatable.dart';

enum AiDocumentAnalysisProvider { openAi, gemini, custom }

AiDocumentAnalysisProvider aiDocumentAnalysisProviderFromStorageValue(
  String? value,
) {
  switch (value) {
    case 'gemini':
      return AiDocumentAnalysisProvider.gemini;
    case 'custom':
      return AiDocumentAnalysisProvider.custom;
    case 'openAi':
    default:
      return AiDocumentAnalysisProvider.openAi;
  }
}

extension AiDocumentAnalysisProviderStorageValue
    on AiDocumentAnalysisProvider {
  String get storageValue {
    switch (this) {
      case AiDocumentAnalysisProvider.openAi:
        return 'openAi';
      case AiDocumentAnalysisProvider.gemini:
        return 'gemini';
      case AiDocumentAnalysisProvider.custom:
        return 'custom';
    }
  }
}

class AiDocumentAnalysisSettings extends Equatable {
  final bool enabled;
  final AiDocumentAnalysisProvider provider;
  final String? apiKey;
  final String? model;
  final bool sendPdfWhenOcrIsInsufficient;

  const AiDocumentAnalysisSettings({
    this.enabled = false,
    this.provider = AiDocumentAnalysisProvider.openAi,
    this.apiKey,
    this.model,
    this.sendPdfWhenOcrIsInsufficient = false,
  });

  AiDocumentAnalysisSettings copyWith({
    bool? enabled,
    AiDocumentAnalysisProvider? provider,
    String? apiKey,
    bool clearApiKey = false,
    String? model,
    bool clearModel = false,
    bool? sendPdfWhenOcrIsInsufficient,
  }) {
    return AiDocumentAnalysisSettings(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
      model: clearModel ? null : (model ?? this.model),
      sendPdfWhenOcrIsInsufficient:
          sendPdfWhenOcrIsInsufficient ?? this.sendPdfWhenOcrIsInsufficient,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'provider': provider.storageValue,
      'apiKey': _nullableTrimmed(apiKey),
      'model': _nullableTrimmed(model),
      'sendPdfWhenOcrIsInsufficient': sendPdfWhenOcrIsInsufficient,
    };
  }

  factory AiDocumentAnalysisSettings.fromMap(Map<String, dynamic> map) {
    return AiDocumentAnalysisSettings(
      enabled: _boolValue(map['enabled']),
      provider: aiDocumentAnalysisProviderFromStorageValue(
        map['provider'] as String?,
      ),
      apiKey: _nullableTrimmed(map['apiKey'] as String?),
      model: _nullableTrimmed(map['model'] as String?),
      sendPdfWhenOcrIsInsufficient: _boolValue(
        map['sendPdfWhenOcrIsInsufficient'],
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AiDocumentAnalysisSettings.fromJson(String s) =>
      AiDocumentAnalysisSettings.fromMap(
        jsonDecode(s) as Map<String, dynamic>,
      );

  @override
  List<Object?> get props => [
        enabled,
        provider,
        apiKey,
        model,
        sendPdfWhenOcrIsInsufficient,
      ];

  @override
  String toString() {
    return 'AiDocumentAnalysisSettings('
        'enabled: $enabled, '
        'provider: ${provider.storageValue}, '
        'apiKey: ${apiKey == null ? 'null' : '***hidden***'}, '
        'model: $model, '
        'sendPdfWhenOcrIsInsufficient: $sendPdfWhenOcrIsInsufficient'
        ')';
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
  }
}
