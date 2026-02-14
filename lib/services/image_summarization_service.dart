import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:neuranotteai/model/summary_model.dart';
import 'package:neuranotteai/services/ai_service.dart';

/// Result of image summarization
class ImageSummarizationResult {
  final String summary;
  final List<DateTimeEntity> dateTimes;
  final List<LocationEntity> locations;
  final List<String> people;
  final List<String> organizations;
  final List<String> actionItems;
  final int tokensUsed;
  final double confidenceScore;
  final Map<String, dynamic>? rawResponse;

  const ImageSummarizationResult({
    required this.summary,
    this.dateTimes = const [],
    this.locations = const [],
    this.people = const [],
    this.organizations = const [],
    this.actionItems = const [],
    this.tokensUsed = 0,
    this.confidenceScore = 1.0,
    this.rawResponse,
  });

  bool get hasDateTimeEntities => dateTimes.isNotEmpty;
  bool get hasLocationEntities => locations.isNotEmpty;
  bool get hasActionItems => actionItems.isNotEmpty;
}

/// Exception for image summarization errors
class ImageSummarizationException implements Exception {
  final String message;
  final String? code;

  const ImageSummarizationException(this.message, {this.code});

  @override
  String toString() => 'ImageSummarizationException: $message';
}

/// Service for summarizing images using Vision AI
class ImageSummarizationService {
  final AIService _aiService;

  ImageSummarizationService({required AIService aiService})
      : _aiService = aiService;

  /// Summarize an image from file path
  Future<ImageSummarizationResult> summarizeFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ImageSummarizationException(
          'Image file not found: $filePath',
          code: 'file_not_found',
        );
      }

      final bytes = await file.readAsBytes();
      final mimeType = _getMimeType(filePath);

      return _summarize(bytes, mimeType);
    } catch (e) {
      if (e is ImageSummarizationException) rethrow;
      throw ImageSummarizationException('Failed to summarize image: $e');
    }
  }

  /// Summarize an image from bytes
  Future<ImageSummarizationResult> summarizeFromBytes({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return _summarize(bytes, mimeType);
  }

  /// Summarize an image from URL
  Future<ImageSummarizationResult> summarizeFromUrl(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final client = HttpClient();
      
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode != 200) {
          throw ImageSummarizationException(
            'Failed to download image: HTTP ${response.statusCode}',
            code: 'download_failed',
          );
        }

        final bytes = await _consolidateBytes(response);
        final mimeType = response.headers.contentType?.mimeType ?? 'image/jpeg';

        return _summarize(bytes, mimeType);
      } finally {
        client.close();
      }
    } catch (e) {
      if (e is ImageSummarizationException) rethrow;
      throw ImageSummarizationException('Failed to summarize image from URL: $e');
    }
  }

  /// Core summarization logic
  Future<ImageSummarizationResult> _summarize(
    Uint8List bytes,
    String mimeType,
  ) async {
    try {
      // Use AI service to analyze image with entity extraction
      final response = await _aiService.summarizeImageWithEntities(
        imageBytes: bytes,
        mimeType: mimeType,
      );

      // Parse the JSON response
      final parsed = _parseResponse(response.text);

      return ImageSummarizationResult(
        summary: parsed['summary'] ?? 'No summary available',
        dateTimes: _parseDateTimes(parsed['dateTimes']),
        locations: _parseLocations(parsed['locations']),
        people: _parsePeople(parsed['people']),
        organizations: _parseOrganizations(parsed['organizations']),
        actionItems: _parseActionItems(parsed['actionItems']),
        tokensUsed: response.totalTokens,
        confidenceScore: _calculateConfidence(parsed),
        rawResponse: parsed,
      );
    } on AIException catch (e) {
      throw ImageSummarizationException(
        'AI analysis failed: ${e.message}',
        code: e.errorCode,
      );
    }
  }

  /// Parse the JSON response from AI
  Map<String, dynamic> _parseResponse(String text) {
    // Try to extract JSON from the response
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
      // If JSON parsing fails, create a simple summary response
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

  /// Parse date/time entities from response
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

  /// Parse a date/time string
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Parse date/time type
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

  /// Parse location entities from response
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

  /// Parse location type
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

  /// Parse people from response
  List<String> _parsePeople(dynamic data) {
    if (data == null) return [];
    
    final list = data as List<dynamic>;
    return list
        .map((item) {
          if (item is String) return item;
          if (item is Map) return item['name'] as String? ?? '';
          return '';
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// Parse organizations from response
  List<String> _parseOrganizations(dynamic data) {
    if (data == null) return [];
    
    final list = data as List<dynamic>;
    return list
        .map((item) {
          if (item is String) return item;
          if (item is Map) return item['name'] as String? ?? '';
          return '';
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// Parse action items from response
  List<String> _parseActionItems(dynamic data) {
    if (data == null) return [];
    
    final list = data as List<dynamic>;
    return list
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// Calculate overall confidence score
  double _calculateConfidence(Map<String, dynamic> parsed) {
    var totalConfidence = 0.0;
    var count = 0;

    // Average confidence from date/times
    final dateTimes = parsed['dateTimes'] as List<dynamic>?;
    if (dateTimes != null) {
      for (final dt in dateTimes) {
        if (dt is Map) {
          totalConfidence += (dt['confidence'] as num?)?.toDouble() ?? 0.8;
          count++;
        }
      }
    }

    // Average confidence from locations
    final locations = parsed['locations'] as List<dynamic>?;
    if (locations != null) {
      for (final loc in locations) {
        if (loc is Map) {
          totalConfidence += (loc['confidence'] as num?)?.toDouble() ?? 0.8;
          count++;
        }
      }
    }

    if (count == 0) return 0.85; // Default confidence
    return totalConfidence / count;
  }

  /// Consolidate response bytes
  Future<Uint8List> _consolidateBytes(HttpClientResponse response) async {
    final chunks = <List<int>>[];
    
    await for (final chunk in response) {
      chunks.add(chunk);
    }
    
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final result = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }

  /// Get MIME type from file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }
}

/// OCR-specific service for text extraction from images
class OCRService {
  final AIService _aiService;

  OCRService({required AIService aiService}) : _aiService = aiService;

  /// Extract text from an image file
  Future<String> extractTextFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ImageSummarizationException(
          'Image file not found: $filePath',
          code: 'file_not_found',
        );
      }

      final bytes = await file.readAsBytes();
      final mimeType = _getMimeType(filePath);

      return extractTextFromBytes(bytes: bytes, mimeType: mimeType);
    } catch (e) {
      if (e is ImageSummarizationException) rethrow;
      throw ImageSummarizationException('Failed to extract text: $e');
    }
  }

  /// Extract text from image bytes
  Future<String> extractTextFromBytes({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final response = await _aiService.analyzeImage(
        imageBytes: bytes,
        mimeType: mimeType,
        prompt: '''
Extract all text visible in this image. 
Maintain the original formatting and structure as much as possible.
If the image contains a document, form, or note, preserve the layout.
Return ONLY the extracted text, no additional commentary.
''',
      );

      return response.text.trim();
    } on AIException catch (e) {
      throw ImageSummarizationException(
        'OCR failed: ${e.message}',
        code: e.errorCode,
      );
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
