/// API response status
enum ApiStatus {
  success,
  error,
  loading,
  idle,
}

/// Generic API response wrapper
class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? message;
  final String? errorCode;
  final Map<String, dynamic>? errors; // Field-level errors
  final int? statusCode;
  final DateTime timestamp;

  const ApiResponse({
    required this.status,
    this.data,
    this.message,
    this.errorCode,
    this.errors,
    this.statusCode,
    required this.timestamp,
  });

  /// Create a success response
  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      status: ApiStatus.success,
      data: data,
      message: message,
      statusCode: statusCode ?? 200,
      timestamp: DateTime.now(),
    );
  }

  /// Create an error response
  factory ApiResponse.error({
    required String message,
    String? errorCode,
    Map<String, dynamic>? errors,
    int? statusCode,
  }) {
    return ApiResponse(
      status: ApiStatus.error,
      message: message,
      errorCode: errorCode,
      errors: errors,
      statusCode: statusCode ?? 500,
      timestamp: DateTime.now(),
    );
  }

  /// Create a loading response
  factory ApiResponse.loading({String? message}) {
    return ApiResponse(
      status: ApiStatus.loading,
      message: message ?? 'Loading...',
      timestamp: DateTime.now(),
    );
  }

  /// Create an idle response
  factory ApiResponse.idle() {
    return ApiResponse(
      status: ApiStatus.idle,
      timestamp: DateTime.now(),
    );
  }

  /// Check if response is successful
  bool get isSuccess => status == ApiStatus.success;

  /// Check if response is error
  bool get isError => status == ApiStatus.error;

  /// Check if response is loading
  bool get isLoading => status == ApiStatus.loading;

  /// Check if response is idle
  bool get isIdle => status == ApiStatus.idle;

  /// Check if response has data
  bool get hasData => data != null;

  /// Check if response has errors
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  /// Get error for specific field
  String? getFieldError(String field) {
    if (errors == null) return null;
    return errors![field] as String?;
  }

  /// Transform the data using a mapper function
  ApiResponse<R> map<R>(R Function(T data) mapper) {
    return ApiResponse<R>(
      status: status,
      data: data != null ? mapper(data as T) : null,
      message: message,
      errorCode: errorCode,
      errors: errors,
      statusCode: statusCode,
      timestamp: timestamp,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(status: $status, message: $message, hasData: $hasData)';
  }
}

/// Paginated API response
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? nextCursor;
  final String? previousCursor;

  const PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.nextCursor,
    this.previousCursor,
  });

  /// Get total number of pages
  int get totalPages => (totalCount / pageSize).ceil();

  /// Check if on first page
  bool get isFirstPage => page == 1;

  /// Check if on last page
  bool get isLastPage => !hasNextPage;

  /// Check if list is empty
  bool get isEmpty => items.isEmpty;

  /// Check if list is not empty
  bool get isNotEmpty => items.isNotEmpty;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => itemFromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
      nextCursor: json['nextCursor'] as String?,
      previousCursor: json['previousCursor'] as String?,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) itemToJson) {
    return {
      'items': items.map((e) => itemToJson(e)).toList(),
      'totalCount': totalCount,
      'page': page,
      'pageSize': pageSize,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
      'nextCursor': nextCursor,
      'previousCursor': previousCursor,
    };
  }

  /// Create an empty paginated response
  factory PaginatedResponse.empty({int pageSize = 20}) {
    return PaginatedResponse(
      items: [],
      totalCount: 0,
      page: 1,
      pageSize: pageSize,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
}

/// AI Summarization response
class SummarizationResponse {
  final String summary;
  final double confidenceScore;
  final List<ExtractedEntity> entities;
  final int tokensUsed;
  final Duration processingTime;
  final String? rawOutput;
  final Map<String, dynamic>? metadata;

  const SummarizationResponse({
    required this.summary,
    required this.confidenceScore,
    required this.entities,
    required this.tokensUsed,
    required this.processingTime,
    this.rawOutput,
    this.metadata,
  });

  /// Check if any date/time entities were found
  bool get hasDateTimeEntities =>
      entities.any((e) => e.type == EntityType.dateTime);

  /// Check if any location entities were found
  bool get hasLocationEntities =>
      entities.any((e) => e.type == EntityType.location);

  /// Get all date/time entities
  List<ExtractedEntity> get dateTimeEntities =>
      entities.where((e) => e.type == EntityType.dateTime).toList();

  /// Get all location entities
  List<ExtractedEntity> get locationEntities =>
      entities.where((e) => e.type == EntityType.location).toList();

  factory SummarizationResponse.fromJson(Map<String, dynamic> json) {
    return SummarizationResponse(
      summary: json['summary'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      entities: (json['entities'] as List<dynamic>?)
              ?.map((e) => ExtractedEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tokensUsed: json['tokensUsed'] as int,
      processingTime: Duration(
        milliseconds: json['processingTimeMs'] as int? ?? 0,
      ),
      rawOutput: json['rawOutput'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'confidenceScore': confidenceScore,
      'entities': entities.map((e) => e.toJson()).toList(),
      'tokensUsed': tokensUsed,
      'processingTimeMs': processingTime.inMilliseconds,
      'rawOutput': rawOutput,
      'metadata': metadata,
    };
  }
}

/// Type of extracted entity
enum EntityType {
  dateTime,
  location,
  person,
  organization,
  event,
  other,
}

extension EntityTypeExtension on EntityType {
  String get value {
    switch (this) {
      case EntityType.dateTime:
        return 'dateTime';
      case EntityType.location:
        return 'location';
      case EntityType.person:
        return 'person';
      case EntityType.organization:
        return 'organization';
      case EntityType.event:
        return 'event';
      case EntityType.other:
        return 'other';
    }
  }

  static EntityType fromString(String value) {
    switch (value) {
      case 'dateTime':
        return EntityType.dateTime;
      case 'location':
        return EntityType.location;
      case 'person':
        return EntityType.person;
      case 'organization':
        return EntityType.organization;
      case 'event':
        return EntityType.event;
      default:
        return EntityType.other;
    }
  }
}

/// Generic extracted entity from AI
class ExtractedEntity {
  final EntityType type;
  final String text;
  final String? normalizedValue;
  final double confidence;
  final int startIndex;
  final int endIndex;
  final Map<String, dynamic>? metadata;

  const ExtractedEntity({
    required this.type,
    required this.text,
    this.normalizedValue,
    required this.confidence,
    required this.startIndex,
    required this.endIndex,
    this.metadata,
  });

  factory ExtractedEntity.fromJson(Map<String, dynamic> json) {
    return ExtractedEntity(
      type: EntityTypeExtension.fromString(json['type'] as String),
      text: json['text'] as String,
      normalizedValue: json['normalizedValue'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      startIndex: json['startIndex'] as int,
      endIndex: json['endIndex'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'text': text,
      'normalizedValue': normalizedValue,
      'confidence': confidence,
      'startIndex': startIndex,
      'endIndex': endIndex,
      'metadata': metadata,
    };
  }
}

/// Error response model for detailed error handling
class ErrorResponse {
  final String code;
  final String message;
  final String? details;
  final Map<String, List<String>>? fieldErrors;
  final String? traceId;

  const ErrorResponse({
    required this.code,
    required this.message,
    this.details,
    this.fieldErrors,
    this.traceId,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as String?,
      fieldErrors: (json['fieldErrors'] as Map<String, dynamic>?)?.map(
        (key, value) =>
            MapEntry(key, (value as List<dynamic>).cast<String>()),
      ),
      traceId: json['traceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'details': details,
      'fieldErrors': fieldErrors,
      'traceId': traceId,
    };
  }

  @override
  String toString() {
    return 'ErrorResponse(code: $code, message: $message)';
  }
}
