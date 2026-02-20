import 'dart:io';
import 'dart:typed_data';

import 'package:neuranotteai/model/summary_model.dart';
import 'package:neuranotteai/services/entity_extraction_service.dart';
import 'package:neuranotteai/services/geocoding_service.dart';
import 'package:neuranotteai/services/hugging_face_service.dart';
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
  final String googleMapsApiKey;
  final String? groqApiKey;
  final String? huggingFaceApiKey;
  final SpeechToTextProvider speechProvider;
  final bool autoResolveLocations;
  final Duration timeout;

  const SummarizationConfig({
    required this.googleMapsApiKey,
    this.groqApiKey,
    this.huggingFaceApiKey,
    this.speechProvider = SpeechToTextProvider.whisper,
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
  late final ImageSummarizationService _imageSummarizationService;
  late final SpeechToTextService _speechToTextService;
  late final AudioSummarizationService _audioSummarizationService;
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
        _entityExtractionService = const EntityExtractionService(),
        _geocodingService = GeocodingService(
          config: GeocodingConfig(apiKey: config.googleMapsApiKey),
        ) {
    // Initialize services that require API keys conditionally
    if (config.huggingFaceApiKey != null) {
      _imageSummarizationService = ImageSummarizationService(
        huggingFaceService: HuggingFaceService(
          config: HuggingFaceConfig(
            apiKey: config.huggingFaceApiKey!,
          ),
        ),
      );
    } else {
      throw ArgumentError('Hugging Face API key is required for image summarization');
    }

    _speechToTextService = SpeechToTextService(
      config: SpeechToTextConfig(
        apiKey: config.groqApiKey ?? '',
        provider: config.speechProvider,
      ),
    );

    _audioSummarizationService = AudioSummarizationService(
      sttService: SpeechToTextService(
        config: SpeechToTextConfig(
          apiKey: config.groqApiKey ?? '',
          provider: config.speechProvider,
        ),
      ),
    );
  }

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

      // Create a simple text summary using basic truncation
      final summary = _createTextSummary(text);

      onProgress?.call(SummarizationStage.extractingEntities, 0.5, 'Extracting entities...');

      // Extract entities (now returns empty)
      final entityResult = await _entityExtractionService.extractEntities(text);

      // Resolve locations if enabled
      var locations = entityResult.locations;

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
        summary: summary,
        dateTimes: entityResult.dateTimes,
        locations: locations,
        actionItems: entityResult.actionItems,
        tokensUsed: 0,
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

  /// Create a simple text summary by extracting key sentences
  String _createTextSummary(String text) {
    if (text.length <= 200) return text;

    // Split into sentences
    final sentences = text.split(RegExp(r'[.!?]+\s+'));
    if (sentences.length <= 3) return text;

    // Take first sentence and last sentence, plus key middle sentences
    final summarySentences = <String>[];
    summarySentences.add(sentences.first.trim());

    // Add middle sentences if text is long
    if (sentences.length > 5) {
      final middleIndex = sentences.length ~/ 2;
      summarySentences.add(sentences[middleIndex].trim());
    }

    summarySentences.add(sentences.last.trim());

    return summarySentences.join('. ') + '.';
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
    _geocodingService.dispose();
  }
}

/// Builder for creating SummarizationOrchestrator with fluent API
class SummarizationOrchestratorBuilder {
  String? _googleMapsApiKey;
  String? _groqApiKey;
  String? _huggingFaceApiKey;
  SpeechToTextProvider _speechProvider = SpeechToTextProvider.whisper;
  bool _autoResolveLocations = true;
  Duration _timeout = const Duration(minutes: 2);
  StorageService? _storageService;

  SummarizationOrchestratorBuilder withGoogleMapsApiKey(String apiKey) {
    _googleMapsApiKey = apiKey;
    return this;
  }

  SummarizationOrchestratorBuilder withGroqApiKey(String apiKey) {
    _groqApiKey = apiKey;
    return this;
  }

  SummarizationOrchestratorBuilder withHuggingFaceApiKey(String apiKey) {
    _huggingFaceApiKey = apiKey;
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
    if (_googleMapsApiKey == null) {
      throw ArgumentError('Google Maps API key is required');
    }

    if (_huggingFaceApiKey == null) {
      throw ArgumentError('Hugging Face API key is required for image summarization');
    }

    return SummarizationOrchestrator(
      config: SummarizationConfig(
        googleMapsApiKey: _googleMapsApiKey!,
        groqApiKey: _groqApiKey,
        huggingFaceApiKey: _huggingFaceApiKey,
        speechProvider: _speechProvider,
        autoResolveLocations: _autoResolveLocations,
        timeout: _timeout,
      ),
      storageService: _storageService,
    );
  }
}
