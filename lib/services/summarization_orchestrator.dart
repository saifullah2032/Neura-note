import 'dart:io';
import 'dart:typed_data';

import 'package:neuranotteai/model/summary_model.dart';
import 'package:neuranotteai/services/ai_service.dart';
import 'package:neuranotteai/services/entity_extraction_service.dart';
import 'package:neuranotteai/services/geocoding_service.dart';
import 'package:neuranotteai/services/image_summarization_service.dart';
import 'package:neuranotteai/services/speech_to_text_service.dart';
import 'package:neuranotteai/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Exception for summarization orchestration errors
class SummarizationException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;

  const SummarizationException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'SummarizationException: $message';
}

/// Configuration for the summarization orchestrator
class SummarizationConfig {
  final String geminiApiKey;
  final String googleMapsApiKey;
  final String? speechToTextApiKey;
  final SpeechToTextProvider speechProvider;
  final bool autoResolveLocations;
  final Duration timeout;

  const SummarizationConfig({
    required this.geminiApiKey,
    required this.googleMapsApiKey,
    this.speechToTextApiKey,
    this.speechProvider = SpeechToTextProvider.gemini,
    this.autoResolveLocations = true,
    this.timeout = const Duration(minutes: 2),
  });
}

/// Progress callback for summarization process
typedef SummarizationProgressCallback = void Function(
  SummarizationStage stage,
  double progress,
  String? message,
);

/// Stages of the summarization process
enum SummarizationStage {
  uploading,
  transcribing,
  analyzing,
  extractingEntities,
  resolvingLocations,
  finalizing,
  complete,
  error,
}

extension SummarizationStageExtension on SummarizationStage {
  String get displayName {
    switch (this) {
      case SummarizationStage.uploading:
        return 'Uploading content...';
      case SummarizationStage.transcribing:
        return 'Transcribing audio...';
      case SummarizationStage.analyzing:
        return 'Analyzing content...';
      case SummarizationStage.extractingEntities:
        return 'Extracting entities...';
      case SummarizationStage.resolvingLocations:
        return 'Resolving locations...';
      case SummarizationStage.finalizing:
        return 'Finalizing summary...';
      case SummarizationStage.complete:
        return 'Complete!';
      case SummarizationStage.error:
        return 'Error occurred';
    }
  }
}

/// Result of the complete summarization pipeline
class SummarizationPipelineResult {
  final String summaryId;
  final SummaryType type;
  final String originalContentUrl;
  final String? thumbnailUrl;
  final String summary;
  final String? transcript;
  final List<DateTimeEntity> dateTimes;
  final List<LocationEntity> locations;
  final List<String> actionItems;
  final int tokensUsed;
  final double confidenceScore;
  final Duration processingTime;
  final Map<String, dynamic>? metadata;

  const SummarizationPipelineResult({
    required this.summaryId,
    required this.type,
    required this.originalContentUrl,
    this.thumbnailUrl,
    required this.summary,
    this.transcript,
    this.dateTimes = const [],
    this.locations = const [],
    this.actionItems = const [],
    this.tokensUsed = 0,
    this.confidenceScore = 1.0,
    required this.processingTime,
    this.metadata,
  });

  bool get hasDateTimeEntities => dateTimes.isNotEmpty;
  bool get hasLocationEntities => locations.isNotEmpty;
  bool get hasActionItems => actionItems.isNotEmpty;
  bool get hasAnyEntities => hasDateTimeEntities || hasLocationEntities;

  /// Convert to SummaryModel for storage
  SummaryModel toSummaryModel({required String userId}) {
    return SummaryModel(
      id: summaryId,
      userId: userId,
      type: type,
      originalContentUrl: originalContentUrl,
      thumbnailUrl: thumbnailUrl,
      summarizedText: summary,
      rawTranscript: transcript,
      createdAt: DateTime.now(),
      hasDateTimeEntity: hasDateTimeEntities,
      extractedDateTimes: dateTimes,
      hasLocationEntity: hasLocationEntities,
      extractedLocations: locations,
      tokensCost: tokensUsed,
      confidenceScore: confidenceScore,
      metadata: metadata,
    );
  }
}

/// Orchestrates the complete summarization pipeline
class SummarizationOrchestrator {
  final AIService _aiService;
  final ImageSummarizationService _imageSummarizationService;
  final SpeechToTextService _speechToTextService;
  final AudioSummarizationService _audioSummarizationService;
  final EntityExtractionService _entityExtractionService;
  final GeocodingService _geocodingService;
  final StorageService? _storageService;
  final SummarizationConfig _config;
  final Uuid _uuid = const Uuid();

  SummarizationOrchestrator({
    required SummarizationConfig config,
    StorageService? storageService,
  })  : _config = config,
        _storageService = storageService,
        _aiService = AIService(
          config: AIConfig.geminiVision(apiKey: config.geminiApiKey),
        ),
        _imageSummarizationService = ImageSummarizationService(
          aiService: AIService(
            config: AIConfig.geminiVision(apiKey: config.geminiApiKey),
          ),
        ),
        _speechToTextService = SpeechToTextService(
          config: SpeechToTextConfig(
            apiKey: config.speechToTextApiKey ?? config.geminiApiKey,
            provider: config.speechProvider,
          ),
        ),
        _audioSummarizationService = AudioSummarizationService(
          sttService: SpeechToTextService(
            config: SpeechToTextConfig(
              apiKey: config.speechToTextApiKey ?? config.geminiApiKey,
              provider: config.speechProvider,
            ),
          ),
          aiService: AIService(
            config: AIConfig.summarization(apiKey: config.geminiApiKey),
          ),
        ),
        _entityExtractionService = EntityExtractionService(
          aiService: AIService(
            config: AIConfig.summarization(apiKey: config.geminiApiKey),
          ),
        ),
        _geocodingService = GeocodingService(
          config: GeocodingConfig(apiKey: config.googleMapsApiKey),
        );

  /// Summarize an image from file path
  Future<SummarizationPipelineResult> summarizeImage({
    required String filePath,
    String? userId,
    SummarizationProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call(SummarizationStage.uploading, 0.1, 'Reading image...');

      // Upload image if storage service available
      String contentUrl = filePath;
      String? thumbnailUrl;

      if (_storageService != null && userId != null) {
        onProgress?.call(SummarizationStage.uploading, 0.2, 'Uploading image...');
        contentUrl = await _storageService!.uploadImage(
          File(filePath),
          userId: userId,
        );
        // Thumbnail would be generated separately if needed
      }

      onProgress?.call(SummarizationStage.analyzing, 0.4, 'Analyzing image...');

      // Summarize the image
      final result = await _imageSummarizationService.summarizeFromFile(filePath);

      onProgress?.call(SummarizationStage.extractingEntities, 0.6, 'Processing entities...');

      // Resolve locations if enabled
      var locations = result.locations;
      if (_config.autoResolveLocations && locations.isNotEmpty) {
        onProgress?.call(SummarizationStage.resolvingLocations, 0.8, 'Resolving locations...');
        locations = await _geocodingService.resolveLocations(locations);
      }

      onProgress?.call(SummarizationStage.finalizing, 0.9, 'Finalizing...');

      stopwatch.stop();

      onProgress?.call(SummarizationStage.complete, 1.0, 'Complete!');

      return SummarizationPipelineResult(
        summaryId: _uuid.v4(),
        type: SummaryType.image,
        originalContentUrl: contentUrl,
        thumbnailUrl: thumbnailUrl,
        summary: result.summary,
        dateTimes: result.dateTimes,
        locations: locations,
        actionItems: result.actionItems,
        tokensUsed: result.tokensUsed,
        confidenceScore: result.confidenceScore,
        processingTime: stopwatch.elapsed,
        metadata: result.rawResponse,
      );
    } catch (e) {
      onProgress?.call(SummarizationStage.error, 0, e.toString());
      throw SummarizationException(
        'Image summarization failed',
        code: 'image_summarization_error',
        originalError: e,
      );
    }
  }

  /// Summarize an image from bytes
  Future<SummarizationPipelineResult> summarizeImageBytes({
    required Uint8List bytes,
    required String mimeType,
    String? userId,
    SummarizationProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call(SummarizationStage.analyzing, 0.3, 'Analyzing image...');

      // Upload if storage service available
      String contentUrl = '';
      if (_storageService != null && userId != null) {
        onProgress?.call(SummarizationStage.uploading, 0.1, 'Uploading image...');
        // Note: StorageService doesn't have uploadImageBytes, skip upload for bytes
        // In a real implementation, you'd save bytes to a temp file first
      }

      // Summarize the image
      final result = await _imageSummarizationService.summarizeFromBytes(
        bytes: bytes,
        mimeType: mimeType,
      );

      onProgress?.call(SummarizationStage.extractingEntities, 0.6, 'Processing entities...');

      // Resolve locations if enabled
      var locations = result.locations;
      if (_config.autoResolveLocations && locations.isNotEmpty) {
        onProgress?.call(SummarizationStage.resolvingLocations, 0.8, 'Resolving locations...');
        locations = await _geocodingService.resolveLocations(locations);
      }

      stopwatch.stop();

      onProgress?.call(SummarizationStage.complete, 1.0, 'Complete!');

      return SummarizationPipelineResult(
        summaryId: _uuid.v4(),
        type: SummaryType.image,
        originalContentUrl: contentUrl,
        summary: result.summary,
        dateTimes: result.dateTimes,
        locations: locations,
        actionItems: result.actionItems,
        tokensUsed: result.tokensUsed,
        confidenceScore: result.confidenceScore,
        processingTime: stopwatch.elapsed,
        metadata: result.rawResponse,
      );
    } catch (e) {
      onProgress?.call(SummarizationStage.error, 0, e.toString());
      throw SummarizationException(
        'Image summarization failed',
        code: 'image_summarization_error',
        originalError: e,
      );
    }
  }

  /// Summarize audio from file path
  Future<SummarizationPipelineResult> summarizeAudio({
    required String filePath,
    String? userId,
    SummarizationProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call(SummarizationStage.uploading, 0.1, 'Reading audio...');

      // Upload audio if storage service available
      String contentUrl = filePath;
      if (_storageService != null && userId != null) {
        onProgress?.call(SummarizationStage.uploading, 0.2, 'Uploading audio...');
        contentUrl = await _storageService!.uploadAudio(
          File(filePath),
          userId: userId,
        );
      }

      onProgress?.call(SummarizationStage.transcribing, 0.3, 'Transcribing audio...');

      // Summarize the audio (includes transcription)
      final result = await _audioSummarizationService.summarizeFile(filePath);

      onProgress?.call(SummarizationStage.extractingEntities, 0.6, 'Processing entities...');

      // Resolve locations if enabled
      var locations = result.locations;
      if (_config.autoResolveLocations && locations.isNotEmpty) {
        onProgress?.call(SummarizationStage.resolvingLocations, 0.8, 'Resolving locations...');
        locations = await _geocodingService.resolveLocations(locations);
      }

      onProgress?.call(SummarizationStage.finalizing, 0.9, 'Finalizing...');

      stopwatch.stop();

      onProgress?.call(SummarizationStage.complete, 1.0, 'Complete!');

      return SummarizationPipelineResult(
        summaryId: _uuid.v4(),
        type: SummaryType.voice,
        originalContentUrl: contentUrl,
        summary: result.summary,
        transcript: result.transcript,
        dateTimes: result.dateTimes,
        locations: locations,
        actionItems: result.actionItems,
        tokensUsed: result.tokensUsed,
        confidenceScore: result.confidenceScore,
        processingTime: stopwatch.elapsed,
        metadata: result.rawResponse,
      );
    } catch (e) {
      onProgress?.call(SummarizationStage.error, 0, e.toString());
      throw SummarizationException(
        'Audio summarization failed',
        code: 'audio_summarization_error',
        originalError: e,
      );
    }
  }

  /// Summarize audio from bytes
  Future<SummarizationPipelineResult> summarizeAudioBytes({
    required Uint8List bytes,
    required AudioEncoding encoding,
    String? userId,
    SummarizationProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call(SummarizationStage.transcribing, 0.2, 'Transcribing audio...');

      // Upload if storage service available
      String contentUrl = '';
      if (_storageService != null && userId != null) {
        onProgress?.call(SummarizationStage.uploading, 0.1, 'Uploading audio...');
        // Note: StorageService doesn't have uploadAudioBytes, skip upload for bytes
        // In a real implementation, you'd save bytes to a temp file first
      }

      // Summarize the audio
      final result = await _audioSummarizationService.summarizeBytes(
        bytes: bytes,
        encoding: encoding,
      );

      onProgress?.call(SummarizationStage.extractingEntities, 0.6, 'Processing entities...');

      // Resolve locations if enabled
      var locations = result.locations;
      if (_config.autoResolveLocations && locations.isNotEmpty) {
        onProgress?.call(SummarizationStage.resolvingLocations, 0.8, 'Resolving locations...');
        locations = await _geocodingService.resolveLocations(locations);
      }

      stopwatch.stop();

      onProgress?.call(SummarizationStage.complete, 1.0, 'Complete!');

      return SummarizationPipelineResult(
        summaryId: _uuid.v4(),
        type: SummaryType.voice,
        originalContentUrl: contentUrl,
        summary: result.summary,
        transcript: result.transcript,
        dateTimes: result.dateTimes,
        locations: locations,
        actionItems: result.actionItems,
        tokensUsed: result.tokensUsed,
        confidenceScore: result.confidenceScore,
        processingTime: stopwatch.elapsed,
        metadata: result.rawResponse,
      );
    } catch (e) {
      onProgress?.call(SummarizationStage.error, 0, e.toString());
      throw SummarizationException(
        'Audio summarization failed',
        code: 'audio_summarization_error',
        originalError: e,
      );
    }
  }

  /// Summarize plain text
  Future<SummarizationPipelineResult> summarizeText({
    required String text,
    SummarizationProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call(SummarizationStage.analyzing, 0.2, 'Analyzing text...');

      // Summarize the text
      final summaryResponse = await _aiService.summarizeText(text);

      onProgress?.call(SummarizationStage.extractingEntities, 0.5, 'Extracting entities...');

      // Extract entities
      final entityResult = await _entityExtractionService.extractEntities(text);

      // Resolve locations if enabled
      var locations = entityResult.locations
          .map((e) => LocationEntity(
                originalText: e.originalText,
                type: e.type,
                confidence: e.confidence,
              ))
          .toList();

      if (_config.autoResolveLocations && locations.isNotEmpty) {
        onProgress?.call(SummarizationStage.resolvingLocations, 0.8, 'Resolving locations...');
        locations = await _geocodingService.resolveLocations(locations);
      }

      stopwatch.stop();

      onProgress?.call(SummarizationStage.complete, 1.0, 'Complete!');

      return SummarizationPipelineResult(
        summaryId: _uuid.v4(),
        type: SummaryType.image, // Could add a 'text' type
        originalContentUrl: '',
        summary: summaryResponse.text,
        dateTimes: entityResult.dateTimes,
        locations: locations,
        actionItems: entityResult.actionItems,
        tokensUsed: summaryResponse.totalTokens + entityResult.tokensUsed,
        confidenceScore: 0.9,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      onProgress?.call(SummarizationStage.error, 0, e.toString());
      throw SummarizationException(
        'Text summarization failed',
        code: 'text_summarization_error',
        originalError: e,
      );
    }
  }

  /// Extract entities from text only (no summarization)
  Future<EntityExtractionResult> extractEntities(String text) async {
    return _entityExtractionService.extractEntities(text);
  }

  /// Resolve a location entity to coordinates
  Future<LocationEntity> resolveLocation(LocationEntity location) async {
    return _geocodingService.resolveLocation(location);
  }

  /// Dispose of resources
  void dispose() {
    _aiService.dispose();
    _geocodingService.dispose();
  }
}

/// Builder for creating SummarizationOrchestrator with fluent API
class SummarizationOrchestratorBuilder {
  String? _geminiApiKey;
  String? _googleMapsApiKey;
  String? _speechToTextApiKey;
  SpeechToTextProvider _speechProvider = SpeechToTextProvider.gemini;
  bool _autoResolveLocations = true;
  Duration _timeout = const Duration(minutes: 2);
  StorageService? _storageService;

  SummarizationOrchestratorBuilder withGeminiApiKey(String apiKey) {
    _geminiApiKey = apiKey;
    return this;
  }

  SummarizationOrchestratorBuilder withGoogleMapsApiKey(String apiKey) {
    _googleMapsApiKey = apiKey;
    return this;
  }

  SummarizationOrchestratorBuilder withSpeechToTextApiKey(String apiKey) {
    _speechToTextApiKey = apiKey;
    return this;
  }

  SummarizationOrchestratorBuilder withSpeechProvider(SpeechToTextProvider provider) {
    _speechProvider = provider;
    return this;
  }

  SummarizationOrchestratorBuilder withAutoResolveLocations(bool enabled) {
    _autoResolveLocations = enabled;
    return this;
  }

  SummarizationOrchestratorBuilder withTimeout(Duration timeout) {
    _timeout = timeout;
    return this;
  }

  SummarizationOrchestratorBuilder withStorageService(StorageService storageService) {
    _storageService = storageService;
    return this;
  }

  SummarizationOrchestrator build() {
    if (_geminiApiKey == null) {
      throw ArgumentError('Gemini API key is required');
    }
    if (_googleMapsApiKey == null) {
      throw ArgumentError('Google Maps API key is required');
    }

    return SummarizationOrchestrator(
      config: SummarizationConfig(
        geminiApiKey: _geminiApiKey!,
        googleMapsApiKey: _googleMapsApiKey!,
        speechToTextApiKey: _speechToTextApiKey,
        speechProvider: _speechProvider,
        autoResolveLocations: _autoResolveLocations,
        timeout: _timeout,
      ),
      storageService: _storageService,
    );
  }
}
