import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:neuranotteai/model/api_response_model.dart';

/// Exception thrown when API operations fail
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode, code: $errorCode)';
}

/// HTTP methods
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
}

/// Retry configuration
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final List<int> retryStatusCodes;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.retryStatusCodes = const [408, 429, 500, 502, 503, 504],
  });
}

/// Service responsible for handling HTTP API calls
class ApiService {
  final HttpClient _client;
  final String? _baseUrl;
  final Duration _timeout;
  final RetryConfig _retryConfig;
  final Map<String, String> _defaultHeaders;

  String? _authToken;

  ApiService({
    HttpClient? client,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 30),
    RetryConfig retryConfig = const RetryConfig(),
    Map<String, String>? defaultHeaders,
  })  : _client = client ?? HttpClient(),
        _baseUrl = baseUrl,
        _timeout = timeout,
        _retryConfig = retryConfig,
        _defaultHeaders = defaultHeaders ?? {} {
    _client.connectionTimeout = _timeout;
  }

  /// Set the authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Clear the authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Summarize an image using AI
  Future<ApiResponse<SummarizationResponse>> summarizeImage(String imageUrl) async {
    return _makeRequest<SummarizationResponse>(
      method: HttpMethod.post,
      endpoint: '/summarize/image',
      body: {'imageUrl': imageUrl},
      parser: (json) => SummarizationResponse.fromJson(json),
    );
  }

  /// Summarize audio using AI
  Future<ApiResponse<SummarizationResponse>> summarizeAudio(String audioUrl) async {
    return _makeRequest<SummarizationResponse>(
      method: HttpMethod.post,
      endpoint: '/summarize/audio',
      body: {'audioUrl': audioUrl},
      parser: (json) => SummarizationResponse.fromJson(json),
    );
  }

  /// Extract entities from text
  Future<ApiResponse<List<ExtractedEntity>>> extractEntities(String text) async {
    return _makeRequest<List<ExtractedEntity>>(
      method: HttpMethod.post,
      endpoint: '/extract/entities',
      body: {'text': text},
      parser: (json) => (json['entities'] as List)
          .map((e) => ExtractedEntity.fromJson(e))
          .toList(),
    );
  }

  /// Perform a generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    required T Function(Map<String, dynamic>) parser,
  }) {
    return _makeRequest<T>(
      method: HttpMethod.get,
      endpoint: endpoint,
      queryParams: queryParams,
      parser: parser,
    );
  }

  /// Perform a generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    required T Function(Map<String, dynamic>) parser,
  }) {
    return _makeRequest<T>(
      method: HttpMethod.post,
      endpoint: endpoint,
      body: body,
      parser: parser,
    );
  }

  /// Perform a generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    required T Function(Map<String, dynamic>) parser,
  }) {
    return _makeRequest<T>(
      method: HttpMethod.put,
      endpoint: endpoint,
      body: body,
      parser: parser,
    );
  }

  /// Perform a generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) parser,
  }) {
    return _makeRequest<T>(
      method: HttpMethod.delete,
      endpoint: endpoint,
      parser: parser,
    );
  }

  /// Make an HTTP request with retry logic
  Future<ApiResponse<T>> _makeRequest<T>({
    required HttpMethod method,
    required String endpoint,
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    int retryCount = 0;
    Duration delay = _retryConfig.initialDelay;

    while (true) {
      try {
        final response = await _executeRequest(
          method: method,
          endpoint: endpoint,
          queryParams: queryParams,
          body: body,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final responseBody = await _readResponse(response);
          final jsonData = json.decode(responseBody) as Map<String, dynamic>;
          
          return ApiResponse.success(
            data: parser(jsonData),
            statusCode: response.statusCode,
          );
        }

        // Check if we should retry
        if (_retryConfig.retryStatusCodes.contains(response.statusCode) &&
            retryCount < _retryConfig.maxRetries) {
          retryCount++;
          await Future.delayed(delay);
          delay = Duration(
            milliseconds: (delay.inMilliseconds * _retryConfig.backoffMultiplier).round(),
          );
          continue;
        }

        // Parse error response
        final responseBody = await _readResponse(response);
        String errorMessage;
        String? errorCode;
        
        try {
          final errorJson = json.decode(responseBody) as Map<String, dynamic>;
          errorMessage = errorJson['message'] as String? ?? 'Unknown error';
          errorCode = errorJson['code'] as String?;
        } catch (_) {
          errorMessage = responseBody.isNotEmpty ? responseBody : 'Request failed';
        }

        return ApiResponse.error(
          message: errorMessage,
          errorCode: errorCode,
          statusCode: response.statusCode,
        );
      } on SocketException catch (e) {
        if (retryCount < _retryConfig.maxRetries) {
          retryCount++;
          await Future.delayed(delay);
          delay = Duration(
            milliseconds: (delay.inMilliseconds * _retryConfig.backoffMultiplier).round(),
          );
          continue;
        }
        return ApiResponse.error(
          message: 'Network error: ${e.message}',
          errorCode: 'network_error',
        );
      } on TimeoutException {
        if (retryCount < _retryConfig.maxRetries) {
          retryCount++;
          await Future.delayed(delay);
          delay = Duration(
            milliseconds: (delay.inMilliseconds * _retryConfig.backoffMultiplier).round(),
          );
          continue;
        }
        return ApiResponse.error(
          message: 'Request timed out',
          errorCode: 'timeout',
        );
      } catch (e) {
        return ApiResponse.error(
          message: 'Request failed: $e',
          errorCode: 'unknown_error',
        );
      }
    }
  }

  /// Execute a single HTTP request
  Future<HttpClientResponse> _executeRequest({
    required HttpMethod method,
    required String endpoint,
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    // Build URI
    Uri uri;
    if (_baseUrl != null) {
      final baseUri = Uri.parse(_baseUrl);
      uri = baseUri.replace(
        path: '${baseUri.path}$endpoint',
        queryParameters: queryParams,
      );
    } else {
      uri = Uri.parse(endpoint);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
    }

    // Create request
    HttpClientRequest request;
    switch (method) {
      case HttpMethod.get:
        request = await _client.getUrl(uri);
        break;
      case HttpMethod.post:
        request = await _client.postUrl(uri);
        break;
      case HttpMethod.put:
        request = await _client.putUrl(uri);
        break;
      case HttpMethod.patch:
        request = await _client.patchUrl(uri);
        break;
      case HttpMethod.delete:
        request = await _client.deleteUrl(uri);
        break;
    }

    // Add headers
    _addHeaders(request);

    // Add body
    if (body != null && (method == HttpMethod.post || 
        method == HttpMethod.put || 
        method == HttpMethod.patch)) {
      request.headers.contentType = ContentType.json;
      request.write(json.encode(body));
    }

    // Send request with timeout
    return request.close().timeout(_timeout);
  }

  /// Add default and auth headers to request
  void _addHeaders(HttpClientRequest request) {
    // Add default headers
    _defaultHeaders.forEach((key, value) {
      request.headers.add(key, value);
    });

    // Add content type
    request.headers.add('Accept', 'application/json');

    // Add auth token if available
    if (_authToken != null) {
      request.headers.add('Authorization', 'Bearer $_authToken');
    }
  }

  /// Read response body as string
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

  /// Check if the API is reachable
  Future<bool> healthCheck() async {
    try {
      final response = await _makeRequest<Map<String, dynamic>>(
        method: HttpMethod.get,
        endpoint: '/health',
        parser: (json) => json,
      );
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Configuration for the API service
class ApiConfig {
  final String baseUrl;
  final Duration timeout;
  final RetryConfig retryConfig;
  final Map<String, String> headers;

  const ApiConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.retryConfig = const RetryConfig(),
    this.headers = const {},
  });

  /// Development configuration
  factory ApiConfig.development() {
    return const ApiConfig(
      baseUrl: 'http://localhost:3000/api/v1',
      timeout: Duration(seconds: 60),
    );
  }

  /// Production configuration
  factory ApiConfig.production() {
    return const ApiConfig(
      baseUrl: 'https://api.neuranote.ai/v1',
      timeout: Duration(seconds: 30),
    );
  }
}
