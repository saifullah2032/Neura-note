import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// @deprecated
/// This file is deprecated and no longer used. 
/// 
/// The app has been migrated to use:
/// - Groq (Whisper) for audio transcription
/// - Hugging Face for image analysis and text processing
/// 
/// This file is kept for reference only and will be removed in a future version.
/// 
/// To migrate existing code:
/// - Replace AIService usage with HuggingFaceService for image/text analysis
/// - Use SpeechToTextService with Whisper provider for transcription
/// 
/// See:
/// - lib/services/hugging_face_service.dart
/// - lib/services/speech_to_text_service.dart

/// Exception thrown when AI operations fail
@Deprecated('Use service-specific exceptions instead')
class AIException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  const AIException(this.message, {this.errorCode, this.statusCode});

  @override
  String toString() => 'AIException: $message (code: $errorCode)';
}

/// Configuration for AI service
@Deprecated('Use HuggingFaceConfig instead')
class AIConfig {
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final Duration timeout;
  final bool useJsonMode;

  const AIConfig({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.timeout = const Duration(seconds: 60),
    this.useJsonMode = false,
  });

  factory AIConfig.geminiVision({required String apiKey}) {
    return AIConfig(
      apiKey: apiKey,
      model: 'gemini-2.5-flash',
      temperature: 0.4,
      maxTokens: 4096,
    );
  }

  factory AIConfig.summarization({required String apiKey}) {
    return AIConfig(
      apiKey: apiKey,
      model: 'gemini-2.5-flash',
      temperature: 0.3,
      maxTokens: 2048,
    );
  }
}

/// Response from AI generation
@Deprecated('Not used anymore')
class AIGenerationResponse {
  final String text;
  final String? reasoning;
  final int promptTokens;
  final int completionTokens;
  final String? finishReason;
  final Map<String, dynamic>? metadata;

  const AIGenerationResponse({
    required this.text,
    this.reasoning,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.finishReason,
    this.metadata,
  });

  int get totalTokens => promptTokens + completionTokens;

  Map<String, dynamic> toMap() => json.decode(text);
}

/// Service for AI-powered operations using Google Gemini API
/// 
/// @deprecated This service is deprecated. Use HuggingFaceService instead.
@Deprecated('Use HuggingFaceService for image/text analysis. This class will be removed in a future version.')
class AIService {
  final HttpClient _client;
  final AIConfig _config;

  static const String _baseUrl = 'generativelanguage.googleapis.com';
  static const String _apiVersion = 'v1';

  @Deprecated('Use HuggingFaceService instead')
  AIService({required AIConfig config, HttpClient? client})
    : _config = config,
      _client = client ?? HttpClient() {
    _client.connectionTimeout = _config.timeout;
  }

  @Deprecated('Use HuggingFaceService.analyzeImage() instead')
  Future<AIGenerationResponse> generateText(
    String prompt, {
    bool forceJson = false,
  }) async {
    throw UnimplementedError('AIService is deprecated. Use HuggingFaceService instead.');
  }

  @Deprecated('Use HuggingFaceService.analyzeImage() instead')
  Future<AIGenerationResponse> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String prompt = 'Analyze this image and provide a detailed summary.',
    bool forceJson = false,
  }) async {
    throw UnimplementedError('AIService is deprecated. Use HuggingFaceService instead.');
  }

  @Deprecated('Use HuggingFaceService.analyzeImage() instead')
  Future<AIGenerationResponse> analyzeImageFile({
    required String filePath,
    String prompt = 'Analyze this image and provide a detailed summary.',
  }) async {
    throw UnimplementedError('AIService is deprecated. Use HuggingFaceService instead.');
  }

  @Deprecated('Text summarization is not supported in the new architecture')
  Future<AIGenerationResponse> summarizeText(String text) async {
    throw UnimplementedError('AIService is deprecated.');
  }

  @Deprecated('Use EntityExtractionService instead')
  Future<AIGenerationResponse> extractEntities(String text) async {
    throw UnimplementedError('AIService is deprecated. Use EntityExtractionService instead.');
  }

  @Deprecated('Use HuggingFaceService instead')
  Future<AIGenerationResponse> summarizeImageWithEntities({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    throw UnimplementedError('AIService is deprecated. Use HuggingFaceService instead.');
  }

  @Deprecated('Use AudioSummarizationService instead')
  Future<AIGenerationResponse> summarizeTranscriptWithEntities(
    String transcript,
  ) async {
    throw UnimplementedError('AIService is deprecated. Use AudioSummarizationService instead.');
  }

  void dispose() => _client.close();
}
