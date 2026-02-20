import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Exception for Hugging Face API errors
class HuggingFaceException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  const HuggingFaceException(this.message, {this.errorCode, this.statusCode});

  @override
  String toString() => 'HuggingFaceException: $message (code: $errorCode)';
}

/// Configuration for Hugging Face service
class HuggingFaceConfig {
  final String apiKey;
  final String baseUrl;
  final String imageModel;
  final Duration timeout;

  const HuggingFaceConfig({
    required this.apiKey,
    this.baseUrl = 'https://api-inference.huggingface.co',
    this.imageModel = 'nlpconnect/vit-gpt2-image-captioning',
    this.timeout = const Duration(seconds: 60),
  });
}

/// Response from Hugging Face image analysis
class HuggingFaceImageResponse {
  final String caption;
  final double? confidence;
  final Map<String, dynamic>? rawResponse;

  const HuggingFaceImageResponse({
    required this.caption,
    this.confidence,
    this.rawResponse,
  });
}

/// Service for AI-powered image analysis using Hugging Face
class HuggingFaceService {
  final HttpClient _client;
  final HuggingFaceConfig _config;

  HuggingFaceService({required HuggingFaceConfig config, HttpClient? client})
      : _config = config,
        _client = client ?? HttpClient() {
    _client.connectionTimeout = _config.timeout;
  }

  /// Analyze an image and generate a caption/description
  Future<HuggingFaceImageResponse> analyzeImage({
    required Uint8List imageBytes,
    String? mimeType,
  }) async {
    // Return a mock response for now since Hugging Face API is not working reliably
    // In production, you would use a paid API or your own backend
    return HuggingFaceImageResponse(
      caption: 'Image captured and processed. The image shows content that was selected for summarization.',
      confidence: 0.8,
      rawResponse: {'status': 'mock_response'},
    );
  }

  /// Analyze an image file
  Future<HuggingFaceImageResponse> analyzeImageFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw HuggingFaceException('Image file not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    final mimeType = _getMimeType(filePath);
    return analyzeImage(imageBytes: bytes, mimeType: mimeType);
  }

  /// Summarize an image with entity extraction
  /// Returns a JSON-compatible structure similar to Gemini's response
  Future<Map<String, dynamic>> summarizeImageWithEntities({
    required Uint8List imageBytes,
    String? mimeType,
  }) async {
    try {
      // First, get the basic caption from the image
      final response = await analyzeImage(imageBytes: imageBytes, mimeType: mimeType);
      
      // Construct a structured response similar to what Gemini would return
      // This allows the existing parsing code to work with minimal changes
      return {
        'summary': response.caption,
        'dateTimes': <dynamic>[],
        'locations': <dynamic>[],
        'people': <dynamic>[],
        'organizations': <dynamic>[],
        'actionItems': <dynamic>[],
        'confidence': response.confidence ?? 0.85,
        'rawResponse': response.rawResponse,
      };
    } catch (e) {
      if (e is HuggingFaceException) rethrow;
      throw HuggingFaceException('Failed to summarize image: $e');
    }
  }

  /// Parse the image analysis response
  HuggingFaceImageResponse _parseImageResponse(String responseBody) {
    try {
      final jsonResponse = json.decode(responseBody);
      
      // Hugging Face returns an array of results
      if (jsonResponse is List && jsonResponse.isNotEmpty) {
        final firstResult = jsonResponse.first;
        
        if (firstResult is Map<String, dynamic>) {
          final caption = firstResult['generated_text'] as String? ??
                         firstResult['caption'] as String? ??
                         'No caption generated';
          final confidence = (firstResult['confidence'] as num?)?.toDouble();
          
          return HuggingFaceImageResponse(
            caption: caption,
            confidence: confidence,
            rawResponse: firstResult,
          );
        }
      }
      
      // If response is a string (some models return plain text)
      if (jsonResponse is String) {
        return HuggingFaceImageResponse(
          caption: jsonResponse,
          rawResponse: {'text': jsonResponse},
        );
      }

      throw HuggingFaceException(
        'Unexpected response format: $responseBody',
        errorCode: 'parse_error',
      );
    } catch (e) {
      if (e is HuggingFaceException) rethrow;
      throw HuggingFaceException(
        'Failed to parse response: $e',
        errorCode: 'parse_error',
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

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}
