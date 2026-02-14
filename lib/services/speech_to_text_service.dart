import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:neuranotteai/model/summary_model.dart';
import 'package:neuranotteai/services/ai_service.dart';

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
    this.provider = SpeechToTextProvider.google,
    this.languageCode = 'en-US',
    this.enableAutomaticPunctuation = true,
    this.enableWordTimeOffsets = false,
    this.timeout = const Duration(minutes: 5),
  });
}

/// Available speech-to-text providers
enum SpeechToTextProvider {
  google,
  whisper,
  gemini, // Use Gemini for audio understanding
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
      // Format: "1.500s"
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

/// Service for converting speech to text
class SpeechToTextService {
  final HttpClient _client;
  final SpeechToTextConfig _config;

  static const String _googleSpeechBaseUrl = 'speech.googleapis.com';
  static const String _whisperBaseUrl = 'api.openai.com';

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
    switch (_config.provider) {
      case SpeechToTextProvider.google:
        return _transcribeWithGoogle(
          bytes: bytes,
          encoding: encoding,
          sampleRateHertz: sampleRateHertz,
        );
      case SpeechToTextProvider.whisper:
        return _transcribeWithWhisper(bytes: bytes, encoding: encoding);
      case SpeechToTextProvider.gemini:
        return _transcribeWithGemini(bytes: bytes, encoding: encoding);
    }
  }

  /// Transcribe using Google Cloud Speech-to-Text
  Future<TranscriptionResult> _transcribeWithGoogle({
    required Uint8List bytes,
    required AudioEncoding encoding,
    int? sampleRateHertz,
  }) async {
    try {
      final uri = Uri.https(
        _googleSpeechBaseUrl,
        '/v1/speech:recognize',
        {'key': _config.apiKey},
      );

      final requestBody = {
        'config': {
          'encoding': encoding.googleValue,
          'sampleRateHertz': sampleRateHertz ?? encoding.defaultSampleRate,
          'languageCode': _config.languageCode,
          'enableAutomaticPunctuation': _config.enableAutomaticPunctuation,
          'enableWordTimeOffsets': _config.enableWordTimeOffsets,
          'model': 'latest_long',
        },
        'audio': {
          'content': base64Encode(bytes),
        },
      };

      final request = await _client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(json.encode(requestBody));

      final response = await request.close().timeout(_config.timeout);
      final responseBody = await _readResponse(response);

      if (response.statusCode != 200) {
        throw _parseGoogleError(responseBody, response.statusCode);
      }

      final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
      return _parseGoogleResponse(jsonResponse);
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
      throw SpeechToTextException('Transcription failed: $e');
    }
  }

  /// Transcribe using OpenAI Whisper
  Future<TranscriptionResult> _transcribeWithWhisper({
    required Uint8List bytes,
    required AudioEncoding encoding,
  }) async {
    try {
      final uri = Uri.https(_whisperBaseUrl, '/v1/audio/transcriptions');

      // Create multipart request
      final boundary = '----FormBoundary${DateTime.now().millisecondsSinceEpoch}';
      final request = await _client.postUrl(uri);
      
      request.headers.set('Authorization', 'Bearer ${_config.apiKey}');
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );

      final body = StringBuffer();
      
      // Add file
      body.writeln('--$boundary');
      body.writeln('Content-Disposition: form-data; name="file"; filename="audio.${encoding.extension}"');
      body.writeln('Content-Type: ${encoding.mimeType}');
      body.writeln();
      
      // Write body text part
      final textPart = body.toString();
      request.add(utf8.encode(textPart));
      
      // Write audio bytes
      request.add(bytes);
      request.add(utf8.encode('\r\n'));
      
      // Add model parameter
      final modelPart = '--$boundary\r\n'
          'Content-Disposition: form-data; name="model"\r\n\r\n'
          'whisper-1\r\n';
      request.add(utf8.encode(modelPart));
      
      // Add language parameter
      final langPart = '--$boundary\r\n'
          'Content-Disposition: form-data; name="language"\r\n\r\n'
          '${_config.languageCode.split('-').first}\r\n';
      request.add(utf8.encode(langPart));
      
      // Close boundary
      request.add(utf8.encode('--$boundary--\r\n'));

      final response = await request.close().timeout(_config.timeout);
      final responseBody = await _readResponse(response);

      if (response.statusCode != 200) {
        throw _parseWhisperError(responseBody, response.statusCode);
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

  /// Transcribe using Gemini (audio understanding)
  Future<TranscriptionResult> _transcribeWithGemini({
    required Uint8List bytes,
    required AudioEncoding encoding,
  }) async {
    try {
      // Note: Gemini 1.5 supports audio understanding
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/gemini-1.5-flash:generateContent',
        {'key': _config.apiKey},
      );

      final base64Audio = base64Encode(bytes);

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': encoding.mimeType,
                  'data': base64Audio,
                }
              },
              {
                'text': 'Transcribe this audio recording. Return ONLY the transcribed text, no additional commentary or formatting.'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 8192,
        },
      };

      final request = await _client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(json.encode(requestBody));

      final response = await request.close().timeout(_config.timeout);
      final responseBody = await _readResponse(response);

      if (response.statusCode != 200) {
        throw _parseGeminiError(responseBody, response.statusCode);
      }

      final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      
      if (candidates == null || candidates.isEmpty) {
        throw const SpeechToTextException(
          'No transcription generated',
          code: 'empty_response',
        );
      }

      final candidate = candidates.first as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = parts?.first['text'] as String? ?? '';

      return TranscriptionResult(
        transcript: text.trim(),
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
      throw SpeechToTextException('Gemini transcription failed: $e');
    }
  }

  /// Parse Google Speech-to-Text response
  TranscriptionResult _parseGoogleResponse(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      return const TranscriptionResult(transcript: '', confidence: 0);
    }

    final transcriptParts = <String>[];
    final wordTimings = <WordTiming>[];
    var totalConfidence = 0.0;
    var confidenceCount = 0;

    for (final result in results) {
      final alternatives = result['alternatives'] as List<dynamic>?;
      if (alternatives == null || alternatives.isEmpty) continue;

      final best = alternatives.first as Map<String, dynamic>;
      transcriptParts.add(best['transcript'] as String? ?? '');
      
      final confidence = (best['confidence'] as num?)?.toDouble();
      if (confidence != null) {
        totalConfidence += confidence;
        confidenceCount++;
      }

      // Parse word timings if available
      final words = best['words'] as List<dynamic>?;
      if (words != null) {
        for (final word in words) {
          wordTimings.add(WordTiming.fromJson(word as Map<String, dynamic>));
        }
      }
    }

    return TranscriptionResult(
      transcript: transcriptParts.join(' '),
      confidence: confidenceCount > 0 ? totalConfidence / confidenceCount : 0.8,
      wordTimings: wordTimings.isNotEmpty ? wordTimings : null,
      languageCode: _config.languageCode,
      metadata: json,
    );
  }

  /// Parse Google error response
  SpeechToTextException _parseGoogleError(String body, int statusCode) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? 'Unknown error';
      final code = error?['status'] as String?;
      return SpeechToTextException(message, code: code);
    } catch (_) {
      return SpeechToTextException(
        'Request failed with status $statusCode',
        code: 'http_$statusCode',
      );
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

  /// Parse Gemini error response
  SpeechToTextException _parseGeminiError(String body, int statusCode) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? 'Unknown error';
      return SpeechToTextException(message, code: 'gemini_error');
    } catch (_) {
      return SpeechToTextException(
        'Gemini request failed with status $statusCode',
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
  String get googleValue {
    switch (this) {
      case AudioEncoding.linearPcm:
        return 'LINEAR16';
      case AudioEncoding.flac:
        return 'FLAC';
      case AudioEncoding.mp3:
        return 'MP3';
      case AudioEncoding.aac:
        return 'AAC';
      case AudioEncoding.oggOpus:
        return 'OGG_OPUS';
      case AudioEncoding.webmOpus:
        return 'WEBM_OPUS';
    }
  }

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

/// Service for summarizing audio content (transcription + summary)
class AudioSummarizationService {
  final SpeechToTextService _sttService;
  final AIService _aiService;

  AudioSummarizationService({
    required SpeechToTextService sttService,
    required AIService aiService,
  })  : _sttService = sttService,
        _aiService = aiService;

  /// Summarize audio from file path
  Future<AudioSummarizationResult> summarizeFile(String filePath) async {
    // First, transcribe the audio
    final transcription = await _sttService.transcribeFile(filePath);
    
    if (transcription.isEmpty) {
      return const AudioSummarizationResult(
        transcript: '',
        summary: 'No speech detected in the audio.',
      );
    }

    // Then summarize with entity extraction
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
    // First, transcribe the audio
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

    // Then summarize with entity extraction
    return _summarizeTranscript(
      transcription.transcript,
      audioDuration: transcription.audioDuration,
    );
  }

  /// Summarize a transcript
  Future<AudioSummarizationResult> _summarizeTranscript(
    String transcript, {
    Duration? audioDuration,
  }) async {
    try {
      final response = await _aiService.summarizeTranscriptWithEntities(transcript);
      final parsed = _parseResponse(response.text);

      return AudioSummarizationResult(
        transcript: transcript,
        summary: parsed['summary'] ?? 'No summary available',
        dateTimes: _parseDateTimes(parsed['dateTimes']),
        locations: _parseLocations(parsed['locations']),
        people: _parsePeople(parsed['people']),
        organizations: _parseOrganizations(parsed['organizations']),
        actionItems: _parseActionItems(parsed['actionItems']),
        tokensUsed: response.totalTokens,
        confidenceScore: _calculateConfidence(parsed),
        audioDuration: audioDuration,
        rawResponse: parsed,
      );
    } on AIException catch (e) {
      throw SpeechToTextException(
        'Summarization failed: ${e.message}',
        code: e.errorCode,
      );
    }
  }

  /// Parse the JSON response from AI
  Map<String, dynamic> _parseResponse(String text) {
    var cleanText = text.trim();
    
    // Remove markdown code blocks if present
    if (cleanText.startsWith('```json')) {
      cleanText = cleanText.substring(7);
    } else if (cleanText.startsWith('```')) {
      cleanText = cleanText.substring(3);
    }
    if (cleanText.endsWith('```')) {
      cleanText = cleanText.substring(0, cleanText.length - 3);
    }
    cleanText = cleanText.trim();

    try {
      return json.decode(cleanText) as Map<String, dynamic>;
    } catch (e) {
      return {
        'summary': text,
        'dateTimes': <dynamic>[],
        'locations': <dynamic>[],
        'people': <dynamic>[],
        'organizations': <dynamic>[],
        'actionItems': <dynamic>[],
      };
    }
  }

  /// Parse date/time entities
  List<DateTimeEntity> _parseDateTimes(dynamic data) {
    if (data == null) return [];
    
    final list = data as List<dynamic>;
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return DateTimeEntity(
        originalText: map['originalText'] as String? ?? '',
        parsedDateTime: _parseDateTime(map['parsedDateTime']),
        type: _parseDateTimeType(map['type'] as String?),
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0.8,
      );
    }).where((e) => e.originalText.isNotEmpty).toList();
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTimeType _parseDateTimeType(String? type) {
    switch (type?.toLowerCase()) {
      case 'specific':
        return DateTimeType.specific;
      case 'relative':
        return DateTimeType.relative;
      case 'recurring':
        return DateTimeType.recurring;
      case 'dateonly':
        return DateTimeType.dateOnly;
      case 'timeonly':
        return DateTimeType.timeOnly;
      default:
        return DateTimeType.specific;
    }
  }

  /// Parse location entities
  List<LocationEntity> _parseLocations(dynamic data) {
    if (data == null) return [];
    
    final list = data as List<dynamic>;
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return LocationEntity(
        originalText: map['originalText'] as String? ?? '',
        resolvedAddress: map['resolvedAddress'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        type: _parseLocationType(map['type'] as String?),
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0.8,
      );
    }).where((e) => e.originalText.isNotEmpty).toList();
  }

  LocationType _parseLocationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'address':
        return LocationType.address;
      case 'placename':
        return LocationType.placeName;
      case 'landmark':
        return LocationType.landmark;
      case 'city':
        return LocationType.city;
      case 'relative':
        return LocationType.relative;
      default:
        return LocationType.placeName;
    }
  }

  List<String> _parsePeople(dynamic data) {
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list.map((item) {
      if (item is String) return item;
      if (item is Map) return item['name'] as String? ?? '';
      return '';
    }).where((name) => name.isNotEmpty).toList();
  }

  List<String> _parseOrganizations(dynamic data) {
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list.map((item) {
      if (item is String) return item;
      if (item is Map) return item['name'] as String? ?? '';
      return '';
    }).where((name) => name.isNotEmpty).toList();
  }

  List<String> _parseActionItems(dynamic data) {
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }

  double _calculateConfidence(Map<String, dynamic> parsed) {
    var totalConfidence = 0.0;
    var count = 0;

    final dateTimes = parsed['dateTimes'] as List<dynamic>?;
    if (dateTimes != null) {
      for (final dt in dateTimes) {
        if (dt is Map) {
          totalConfidence += (dt['confidence'] as num?)?.toDouble() ?? 0.8;
          count++;
        }
      }
    }

    final locations = parsed['locations'] as List<dynamic>?;
    if (locations != null) {
      for (final loc in locations) {
        if (loc is Map) {
          totalConfidence += (loc['confidence'] as num?)?.toDouble() ?? 0.8;
          count++;
        }
      }
    }

    if (count == 0) return 0.85;
    return totalConfidence / count;
  }
}
