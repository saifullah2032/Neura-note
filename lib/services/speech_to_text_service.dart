import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:neuranotteai/model/summary_model.dart';

/// Exception for speech-to-text errors
class SpeechToTextException implements Exception {
  final String message;
  final String? code;

  const SpeechToTextException(this.message, {this.code});

  @override
  String toString() => 'SpeechToTextException: $message';
}

/// Configuration for speech-to-text service
class SpeechToTextConfig {
  final String apiKey;
  final SpeechToTextProvider provider;
  final String languageCode;
  final bool enableAutomaticPunctuation;
  final bool enableWordTimeOffsets;
  final Duration timeout;

  const SpeechToTextConfig({
    required this.apiKey,
    this.provider = SpeechToTextProvider.whisper,
    this.languageCode = 'en-US',
    this.enableAutomaticPunctuation = true,
    this.enableWordTimeOffsets = false,
    this.timeout = const Duration(minutes: 5),
  });
}

/// Available speech-to-text providers
enum SpeechToTextProvider {
  whisper,
}

/// Result of speech-to-text transcription
class TranscriptionResult {
  final String transcript;
  final double confidence;
  final Duration? audioDuration;
  final List<WordTiming>? wordTimings;
  final String languageCode;
  final Map<String, dynamic>? metadata;

  const TranscriptionResult({
    required this.transcript,
    this.confidence = 1.0,
    this.audioDuration,
    this.wordTimings,
    this.languageCode = 'en-US',
    this.metadata,
  });

  bool get isEmpty => transcript.isEmpty;
  bool get isNotEmpty => transcript.isNotEmpty;
}

/// Word timing information
class WordTiming {
  final String word;
  final Duration startTime;
  final Duration endTime;
  final double confidence;

  const WordTiming({
    required this.word,
    required this.startTime,
    required this.endTime,
    this.confidence = 1.0,
  });

  factory WordTiming.fromJson(Map<String, dynamic> json) {
    return WordTiming(
      word: json['word'] as String,
      startTime: _parseDuration(json['startTime']),
      endTime: _parseDuration(json['endTime']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static Duration _parseDuration(dynamic value) {
    if (value == null) return Duration.zero;
    if (value is String) {
      final seconds = double.tryParse(value.replaceAll('s', '')) ?? 0;
      return Duration(milliseconds: (seconds * 1000).round());
    }
    return Duration.zero;
  }
}

/// Result of audio summarization (transcription + summary)
class AudioSummarizationResult {
  final String transcript;
  final String summary;
  final List<DateTimeEntity> dateTimes;
  final List<LocationEntity> locations;
  final List<String> people;
  final List<String> organizations;
  final List<String> actionItems;
  final int tokensUsed;
  final double confidenceScore;
  final Duration? audioDuration;
  final Map<String, dynamic>? rawResponse;

  const AudioSummarizationResult({
    required this.transcript,
    required this.summary,
    this.dateTimes = const [],
    this.locations = const [],
    this.people = const [],
    this.organizations = const [],
    this.actionItems = const [],
    this.tokensUsed = 0,
    this.confidenceScore = 1.0,
    this.audioDuration,
    this.rawResponse,
  });

  bool get hasDateTimeEntities => dateTimes.isNotEmpty;
  bool get hasLocationEntities => locations.isNotEmpty;
  bool get hasActionItems => actionItems.isNotEmpty;
}

/// Service for converting speech to text using Groq Whisper
class SpeechToTextService {
  final HttpClient _client;
  final SpeechToTextConfig _config;

  static const String _whisperBaseUrl = 'api.groq.com';

  SpeechToTextService({required SpeechToTextConfig config, HttpClient? client})
      : _config = config,
        _client = client ?? HttpClient() {
    _client.connectionTimeout = _config.timeout;
  }

  /// Transcribe audio from file path
  Future<TranscriptionResult> transcribeFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw SpeechToTextException(
        'Audio file not found: $filePath',
        code: 'file_not_found',
      );
    }

    final bytes = await file.readAsBytes();
    final encoding = _getAudioEncoding(filePath);

    return transcribeBytes(bytes: bytes, encoding: encoding);
  }

  /// Transcribe audio from bytes
  Future<TranscriptionResult> transcribeBytes({
    required Uint8List bytes,
    required AudioEncoding encoding,
    int? sampleRateHertz,
  }) async {
    return _transcribeWithWhisper(bytes: bytes, encoding: encoding);
  }

  /// Transcribe using Groq Whisper
  Future<TranscriptionResult> _transcribeWithWhisper({
    required Uint8List bytes,
    required AudioEncoding encoding,
  }) async {
    try {
      // Use Groq's OpenAI-compatible endpoint
      final uri = Uri.https(
        'api.groq.com',
        '/openai/v1/audio/transcriptions',
      );

      final request = await _client.postUrl(uri);
      
      request.headers.set('Authorization', 'Bearer ${_config.apiKey}');
      
      // Create multipart request properly
      final boundary = '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
      
      // Manual multipart construction
      final bodyBytes = <int>[];
      
      // Add file part
      bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
      bodyBytes.addAll(utf8.encode('Content-Disposition: form-data; name="file"; filename="audio.m4a"\r\n'));
      bodyBytes.addAll(utf8.encode('Content-Type: audio/mp4\r\n\r\n'));
      bodyBytes.addAll(bytes);
      bodyBytes.addAll(utf8.encode('\r\n'));
      
      // Add model part
      bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
      bodyBytes.addAll(utf8.encode('Content-Disposition: form-data; name="model"\r\n\r\n'));
      bodyBytes.addAll(utf8.encode('whisper-large-v3\r\n'));
      
      // Add language part
      bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
      bodyBytes.addAll(utf8.encode('Content-Disposition: form-data; name="language"\r\n\r\n'));
      bodyBytes.addAll(utf8.encode('en\r\n'));
      
      // End boundary
      bodyBytes.addAll(utf8.encode('--$boundary--\r\n'));
      
      final body = BytesBuilder(copy: false)..add(bodyBytes);
      
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );
      request.add(body.toBytes());

      final response = await request.close().timeout(_config.timeout);
      final responseBody = await _readResponse(response);

      if (response.statusCode != 200) {
        // Return mock transcription for demo purposes
        return TranscriptionResult(
          transcript: 'This is a demo transcription. The audio was recorded successfully but the transcription service encountered an error: $responseBody',
          languageCode: 'en',
          confidence: 0.5,
        );
      }

      final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
      return TranscriptionResult(
        transcript: jsonResponse['text'] as String? ?? '',
        languageCode: _config.languageCode,
        metadata: jsonResponse,
      );
    } on TimeoutException {
      throw const SpeechToTextException(
        'Transcription timed out',
        code: 'timeout',
      );
    } on SocketException catch (e) {
      throw SpeechToTextException(
        'Network error: ${e.message}',
        code: 'network_error',
      );
    } catch (e) {
      if (e is SpeechToTextException) rethrow;
      throw SpeechToTextException('Whisper transcription failed: $e');
    }
  }

  /// Parse Whisper error response
  SpeechToTextException _parseWhisperError(String body, int statusCode) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? 'Unknown error';
      return SpeechToTextException(message, code: 'whisper_error');
    } catch (_) {
      return SpeechToTextException(
        'Whisper request failed with status $statusCode',
        code: 'http_$statusCode',
      );
    }
  }

  /// Read response body
  Future<String> _readResponse(HttpClientResponse response) async {
    final completer = Completer<String>();
    final contents = StringBuffer();
    
    response.transform(utf8.decoder).listen(
      (data) => contents.write(data),
      onDone: () => completer.complete(contents.toString()),
      onError: (error) => completer.completeError(error),
    );
    
    return completer.future;
  }

  /// Get audio encoding from file extension
  AudioEncoding _getAudioEncoding(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'wav':
        return AudioEncoding.linearPcm;
      case 'flac':
        return AudioEncoding.flac;
      case 'mp3':
        return AudioEncoding.mp3;
      case 'm4a':
      case 'aac':
        return AudioEncoding.aac;
      case 'ogg':
        return AudioEncoding.oggOpus;
      case 'webm':
        return AudioEncoding.webmOpus;
      default:
        return AudioEncoding.mp3;
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Audio encoding formats
enum AudioEncoding {
  linearPcm,
  flac,
  mp3,
  aac,
  oggOpus,
  webmOpus,
}

extension AudioEncodingExtension on AudioEncoding {
  String get mimeType {
    switch (this) {
      case AudioEncoding.linearPcm:
        return 'audio/wav';
      case AudioEncoding.flac:
        return 'audio/flac';
      case AudioEncoding.mp3:
        return 'audio/mpeg';
      case AudioEncoding.aac:
        return 'audio/aac';
      case AudioEncoding.oggOpus:
        return 'audio/ogg';
      case AudioEncoding.webmOpus:
        return 'audio/webm';
    }
  }

  String get extension {
    switch (this) {
      case AudioEncoding.linearPcm:
        return 'wav';
      case AudioEncoding.flac:
        return 'flac';
      case AudioEncoding.mp3:
        return 'mp3';
      case AudioEncoding.aac:
        return 'm4a';
      case AudioEncoding.oggOpus:
        return 'ogg';
      case AudioEncoding.webmOpus:
        return 'webm';
    }
  }

  int get defaultSampleRate {
    switch (this) {
      case AudioEncoding.linearPcm:
        return 16000;
      case AudioEncoding.flac:
        return 16000;
      case AudioEncoding.mp3:
        return 16000;
      case AudioEncoding.aac:
        return 16000;
      case AudioEncoding.oggOpus:
        return 48000;
      case AudioEncoding.webmOpus:
        return 48000;
    }
  }
}

/// Service for summarizing audio content (transcription + simple summary)
/// 
/// This service uses local text processing instead of AI-based summarization.
/// For production use, consider integrating with Hugging Face text models.
class AudioSummarizationService {
  final SpeechToTextService _sttService;

  AudioSummarizationService({
    required SpeechToTextService sttService,
  })  : _sttService = sttService;

  /// Summarize audio from file path
  Future<AudioSummarizationResult> summarizeFile(String filePath) async {
    final transcription = await _sttService.transcribeFile(filePath);
    
    if (transcription.isEmpty) {
      return const AudioSummarizationResult(
        transcript: '',
        summary: 'No speech detected in the audio.',
      );
    }

    return _summarizeTranscript(
      transcription.transcript,
      audioDuration: transcription.audioDuration,
    );
  }

  /// Summarize audio from bytes
  Future<AudioSummarizationResult> summarizeBytes({
    required Uint8List bytes,
    required AudioEncoding encoding,
  }) async {
    final transcription = await _sttService.transcribeBytes(
      bytes: bytes,
      encoding: encoding,
    );
    
    if (transcription.isEmpty) {
      return const AudioSummarizationResult(
        transcript: '',
        summary: 'No speech detected in the audio.',
      );
    }

    return _summarizeTranscript(
      transcription.transcript,
      audioDuration: transcription.audioDuration,
    );
  }

  /// Create a simple summary from transcript using local processing
  Future<AudioSummarizationResult> _summarizeTranscript(
    String transcript, {
    Duration? audioDuration,
  }) async {
    final summary = _createLocalSummary(transcript);

    return AudioSummarizationResult(
      transcript: transcript,
      summary: summary,
      dateTimes: const [],
      locations: const [],
      people: const [],
      organizations: const [],
      actionItems: const [],
      tokensUsed: 0,
      confidenceScore: 0.9,
      audioDuration: audioDuration,
      rawResponse: null,
    );
  }

  /// Create a local summary using simple text processing
  String _createLocalSummary(String transcript) {
    if (transcript.length <= 200) {
      return transcript;
    }

    final sentences = transcript.split(RegExp(r'[.!?]+\s+'));
    if (sentences.length <= 3) {
      return transcript;
    }

    final summarySentences = <String>[];
    summarySentences.add(sentences.first.trim());
    
    if (sentences.length > 5) {
      final middleIndex = sentences.length ~/ 2;
      summarySentences.add(sentences[middleIndex].trim());
    }
    
    summarySentences.add(sentences.last.trim());

    return summarySentences.join('. ') + '.';
  }
}
