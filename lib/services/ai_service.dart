import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Exception thrown when AI operations fail
class AIException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  const AIException(this.message, {this.errorCode, this.statusCode});

  @override
  String toString() => 'AIException: $message (code: $errorCode)';
}

/// Configuration for AI service
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
class AIGenerationResponse {
  final String text;
  final String? reasoning; // New field for internal thoughts/logic
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

  /// Helper to parse JSON text directly from response
  Map<String, dynamic> toMap() => json.decode(text);
}

/// Service for AI-powered operations using Google Gemini API
class AIService {
  final HttpClient _client;
  final AIConfig _config;

  static const String _baseUrl = 'generativelanguage.googleapis.com';
  static const String _apiVersion = 'v1';

  AIService({required AIConfig config, HttpClient? client})
    : _config = config,
      _client = client ?? HttpClient() {
    _client.connectionTimeout = _config.timeout;
  }

  /// Generate text completion from a prompt
  Future<AIGenerationResponse> generateText(
    String prompt, {
    bool forceJson = false,
  }) async {
    final effectivePrompt = forceJson
        ? '$prompt\n\nReturn ONLY a valid JSON object. No conversation, no markdown backticks.'
        : prompt;

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': effectivePrompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': _config.temperature,
        'maxOutputTokens': _config.maxTokens,
        'topP': 0.95,
        'topK': 40,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    };

    return _makeRequest(requestBody);
  }

  /// Generate response from an image with optional prompt
  Future<AIGenerationResponse> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String prompt = 'Analyze this image and provide a detailed summary.',
    bool forceJson = false,
  }) async {
    final base64Image = base64Encode(imageBytes);
    final finalPrompt = forceJson
        ? '$prompt\n\nReturn ONLY a valid JSON object.'
        : prompt;

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': finalPrompt},
            {
              'inlineData': {'mimeType': mimeType, 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': _config.temperature,
        'maxOutputTokens': _config.maxTokens,
      },
    };

    return _makeRequest(requestBody);
  }

  Future<AIGenerationResponse> analyzeImageFile({
    required String filePath,
    String prompt = 'Analyze this image and provide a detailed summary.',
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw AIException('Image file not found: $filePath');
    }
    final bytes = await file.readAsBytes();
    final mimeType = _getMimeType(filePath);
    return analyzeImage(imageBytes: bytes, mimeType: mimeType, prompt: prompt);
  }

  Future<AIGenerationResponse> summarizeText(String text) async {
    final prompt = 'Summarize this text concisely: $text';
    return generateText(prompt);
  }

  Future<AIGenerationResponse> extractEntities(String text) async {
    final prompt = 'Extract dates, locations, and organizations as JSON: $text';
    return generateText(prompt, forceJson: true);
  }

  Future<AIGenerationResponse> summarizeImageWithEntities({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    const prompt =
        'Analyze this image and extract summary, dates, and action items as JSON.';
    return analyzeImage(
      imageBytes: imageBytes,
      mimeType: mimeType,
      prompt: prompt,
      forceJson: true,
    );
  }

  Future<AIGenerationResponse> summarizeTranscriptWithEntities(
    String transcript,
  ) async {
    final prompt =
        '''
Analyze this transcript and provide a summary, entities, and action items as JSON.
Transcript: $transcript

Structure:
{
  "summary": "string",
  "dateTimes": [{"originalText": "string", "type": "string"}],
  "locations": [{"originalText": "string", "type": "string"}],
  "people": [{"name": "string", "role": "string"}],
  "organizations": [{"name": "string", "type": "string"}],
  "actionItems": ["string"]
}
''';
    return generateText(prompt, forceJson: true);
  }

  Future<AIGenerationResponse> _makeRequest(Map<String, dynamic> body) async {
    try {
      final uri = Uri.https(
        _baseUrl,
        '/$_apiVersion/models/${_config.model}:generateContent',
        {'key': _config.apiKey},
      );
      final request = await _client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(json.encode(body));
      final response = await request.close().timeout(_config.timeout);
      final responseBody = await _readResponse(response);
      if (response.statusCode != 200) {
        throw _parseError(responseBody, response.statusCode);
      }
      return _parseResponse(json.decode(responseBody));
    } on TimeoutException {
      throw const AIException('Request timed out', errorCode: 'timeout');
    } catch (e) {
      if (e is AIException) rethrow;
      throw AIException('AI request failed: $e');
    }
  }

  /// Updated with safer type-checking for reasoning parts
  AIGenerationResponse _parseResponse(Map<String, dynamic> jsonResponse) {
    final candidates = jsonResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty)
      throw const AIException('No response generated');

    final candidate = candidates.first;
    final parts = candidate['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty)
      throw const AIException('No content in response');

    String text = "";
    String? reasoning;

    for (var part in parts) {
      if (part.containsKey('text')) {
        final content = part['text'];
        if (content is String) {
          text += content;
        } else if (content is Map) {
          reasoning = content['reasoning_content'] ?? content.toString();
        }
      } else if (part.containsKey('reasoningFeedback')) {
        reasoning = part['reasoningFeedback']['text']?.toString();
      }
    }

    if (text.contains('```json')) {
      text = text.split('```json')[1].split('```')[0].trim();
    } else if (text.contains('```')) {
      text = text.split('```')[1].split('```')[0].trim();
    }

    final usage = jsonResponse['usageMetadata'] ?? {};
    return AIGenerationResponse(
      text: text,
      reasoning: reasoning,
      promptTokens: usage['promptTokenCount'] ?? 0,
      completionTokens: usage['candidatesTokenCount'] ?? 0,
      finishReason: candidate['finishReason'],
      metadata: usage,
    );
  }

  AIException _parseError(String body, int statusCode) {
    try {
      final json = jsonDecode(body);
      return AIException(
        json['error']?['message'] ?? 'Unknown error',
        statusCode: statusCode,
      );
    } catch (_) {
      return AIException('Status $statusCode', statusCode: statusCode);
    }
  }

  Future<String> _readResponse(HttpClientResponse response) async {
    return response.transform(utf8.decoder).join();
  }

  String _getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  void dispose() => _client.close();
}
