import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../model/summary_model.dart';
import '../repo/summary_repo.dart';

/// State for summary operations
enum SummaryState {
  initial,
  loading,
  loaded,
  error,
  uploading,
  summarizing,
}

/// Provider for summary state management
class SummaryProvider extends ChangeNotifier {
  final SummaryRepository _summaryRepository;

  SummaryState _state = SummaryState.initial;
  List<SummaryModel> _summaries = [];
  SummaryModel? _currentSummary;
  String? _errorMessage;
  double _uploadProgress = 0;
  StreamSubscription<List<SummaryModel>>? _summariesSubscription;

  SummaryProvider({SummaryRepository? summaryRepository})
      : _summaryRepository = summaryRepository ?? SummaryRepository();

  // Getters
  SummaryState get state => _state;
  List<SummaryModel> get summaries => _summaries;
  SummaryModel? get currentSummary => _currentSummary;
  String? get errorMessage => _errorMessage;
  double get uploadProgress => _uploadProgress;
  bool get isLoading => _state == SummaryState.loading;
  bool get isUploading => _state == SummaryState.uploading;
  bool get isSummarizing => _state == SummaryState.summarizing;

  // Filtered getters
  List<SummaryModel> get imageSummaries =>
      _summaries.where((s) => s.type == SummaryType.image).toList();
  
  List<SummaryModel> get voiceSummaries =>
      _summaries.where((s) => s.type == SummaryType.voice).toList();
  
  List<SummaryModel> get summariesWithEntities =>
      _summaries.where((s) => s.hasActionableEntities).toList();

  List<SummaryModel> get recentSummaries =>
      _summaries.take(10).toList();

  /// Subscribe to summaries for a user
  void subscribeTo(String userId) {
    _summariesSubscription?.cancel();
    _setState(SummaryState.loading);

    _summariesSubscription = _summaryRepository.summariesStream(userId).listen(
      (summaries) {
        _summaries = summaries;
        _setState(SummaryState.loaded);
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  /// Load summaries for a user
  Future<void> loadSummaries(String userId, {int? limit}) async {
    try {
      _setState(SummaryState.loading);
      _clearError();

      _summaries = await _summaryRepository.getSummariesByUserId(
        userId,
        limit: limit,
      );
      
      _setState(SummaryState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Load more summaries (pagination)
  Future<void> loadMoreSummaries(String userId) async {
    if (_summaries.isEmpty) return;

    try {
      // In a real implementation, we'd track the last document for pagination
      final moreSummaries = await _summaryRepository.getSummariesByUserId(
        userId,
        limit: 20,
      );

      // Filter out duplicates
      final existingIds = _summaries.map((s) => s.id).toSet();
      final newSummaries = moreSummaries.where((s) => !existingIds.contains(s.id));
      
      _summaries = [..._summaries, ...newSummaries];
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Get summary by ID
  Future<SummaryModel?> getSummaryById(String id) async {
    try {
      // Check cache first
      final cached = _summaries.firstWhere(
        (s) => s.id == id,
        orElse: () => throw StateError('Not found'),
      );
      return cached;
    } catch (_) {
      // Not in cache, fetch from repository
      try {
        return await _summaryRepository.getSummaryById(id);
      } catch (e) {
        _setError(e.toString());
        return null;
      }
    }
  }

  /// Set current summary for viewing/editing
  void setCurrentSummary(SummaryModel? summary) {
    _currentSummary = summary;
    notifyListeners();
  }

  /// Upload image and create summary
  Future<SummaryModel?> uploadImageAndSummarize({
    required String userId,
    required File imageFile,
    required String summarizedText,
    List<DateTimeEntity> extractedDateTimes = const [],
    List<LocationEntity> extractedLocations = const [],
    int tokensCost = 1,
  }) async {
    try {
      _setState(SummaryState.uploading);
      _uploadProgress = 0;
      _clearError();

      // Upload image
      final imageUrl = await _summaryRepository.uploadImage(userId, imageFile);
      _uploadProgress = 0.5;
      notifyListeners();

      _setState(SummaryState.summarizing);

      // Create summary
      final summary = await _summaryRepository.createSummary(
        userId: userId,
        type: SummaryType.image,
        originalContentUrl: imageUrl,
        summarizedText: summarizedText,
        extractedDateTimes: extractedDateTimes,
        extractedLocations: extractedLocations,
        tokensCost: tokensCost,
      );

      _uploadProgress = 1.0;
      _summaries = [summary, ..._summaries];
      _currentSummary = summary;
      _setState(SummaryState.loaded);

      return summary;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Upload audio and create summary
  Future<SummaryModel?> uploadAudioAndSummarize({
    required String userId,
    required File audioFile,
    required String summarizedText,
    String? rawTranscript,
    List<DateTimeEntity> extractedDateTimes = const [],
    List<LocationEntity> extractedLocations = const [],
    int tokensCost = 1,
  }) async {
    try {
      _setState(SummaryState.uploading);
      _uploadProgress = 0;
      _clearError();

      // Upload audio
      final audioUrl = await _summaryRepository.uploadAudio(userId, audioFile);
      _uploadProgress = 0.5;
      notifyListeners();

      _setState(SummaryState.summarizing);

      // Create summary
      final summary = await _summaryRepository.createSummary(
        userId: userId,
        type: SummaryType.voice,
        originalContentUrl: audioUrl,
        summarizedText: summarizedText,
        rawTranscript: rawTranscript,
        extractedDateTimes: extractedDateTimes,
        extractedLocations: extractedLocations,
        tokensCost: tokensCost,
      );

      _uploadProgress = 1.0;
      _summaries = [summary, ..._summaries];
      _currentSummary = summary;
      _setState(SummaryState.loaded);

      return summary;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Update calendar sync status
  Future<bool> updateCalendarSync(
    String summaryId, {
    required bool isCalendarSynced,
    String? calendarEventId,
  }) async {
    try {
      await _summaryRepository.updateCalendarSync(
        summaryId,
        isCalendarSynced: isCalendarSynced,
        calendarEventId: calendarEventId,
      );

      // Update local cache
      final index = _summaries.indexWhere((s) => s.id == summaryId);
      if (index != -1) {
        _summaries[index] = _summaries[index].copyWith(
          isCalendarSynced: isCalendarSynced,
          calendarEventId: calendarEventId,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Update location reminder status
  Future<bool> updateLocationReminderStatus(
    String summaryId, {
    required bool hasActiveLocationReminder,
    List<String>? activeGeofenceIds,
  }) async {
    try {
      await _summaryRepository.updateLocationReminderStatus(
        summaryId,
        hasActiveLocationReminder: hasActiveLocationReminder,
        activeGeofenceIds: activeGeofenceIds,
      );

      // Update local cache
      final index = _summaries.indexWhere((s) => s.id == summaryId);
      if (index != -1) {
        _summaries[index] = _summaries[index].copyWith(
          hasActiveLocationReminder: hasActiveLocationReminder,
          activeGeofenceIds: activeGeofenceIds,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Delete summary
  Future<bool> deleteSummary(String id) async {
    try {
      await _summaryRepository.deleteSummary(id);

      // Remove from local cache
      _summaries.removeWhere((s) => s.id == id);
      if (_currentSummary?.id == id) {
        _currentSummary = null;
      }
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Search summaries
  Future<List<SummaryModel>> searchSummaries(
    String userId,
    String query,
  ) async {
    try {
      return await _summaryRepository.searchSummaries(userId, query);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Get summaries by type
  Future<void> loadSummariesByType(String userId, SummaryType type) async {
    try {
      _setState(SummaryState.loading);
      _clearError();

      _summaries = await _summaryRepository.getSummariesByType(userId, type);
      _setState(SummaryState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Get summary count
  Future<int> getSummaryCount(String userId) async {
    try {
      return await _summaryRepository.getSummaryCount(userId);
    } catch (e) {
      return _summaries.length;
    }
  }

  /// Clear all summaries (for logout)
  void clear() {
    _summariesSubscription?.cancel();
    _summaries = [];
    _currentSummary = null;
    _errorMessage = null;
    _uploadProgress = 0;
    _state = SummaryState.initial;
    notifyListeners();
  }

  /// Set state and notify listeners
  void _setState(SummaryState state) {
    _state = state;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _state = SummaryState.error;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _summariesSubscription?.cancel();
    super.dispose();
  }
}
