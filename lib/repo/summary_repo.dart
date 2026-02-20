import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../model/summary_model.dart';
import '../services/cloudinary_service.dart';

/// Repository for summary operations
class SummaryRepository {
  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;
  final Uuid _uuid;

  SummaryRepository({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinary,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cloudinary = cloudinary ?? CloudinaryService(),
        _uuid = uuid ?? const Uuid();

  /// Collection reference for summaries
  CollectionReference<Map<String, dynamic>> get _summariesCollection =>
      _firestore.collection('summaries');

  /// Create a new summary
  Future<SummaryModel> createSummary({
    required String userId,
    required SummaryType type,
    required String originalContentUrl,
    required String summarizedText,
    String? thumbnailUrl,
    String? rawTranscript,
    List<DateTimeEntity> extractedDateTimes = const [],
    List<LocationEntity> extractedLocations = const [],
    int tokensCost = 1,
    double? confidenceScore,
    Map<String, dynamic>? metadata,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final summary = SummaryModel(
      id: id,
      userId: userId,
      type: type,
      originalContentUrl: originalContentUrl,
      thumbnailUrl: thumbnailUrl,
      summarizedText: summarizedText,
      rawTranscript: rawTranscript,
      createdAt: now,
      hasDateTimeEntity: extractedDateTimes.isNotEmpty,
      extractedDateTimes: extractedDateTimes,
      hasLocationEntity: extractedLocations.isNotEmpty,
      extractedLocations: extractedLocations,
      tokensCost: tokensCost,
      confidenceScore: confidenceScore,
      metadata: metadata,
    );

    await _summariesCollection.doc(id).set(summary.toJson());
    return summary;
  }

  /// Get summary by ID
  Future<SummaryModel?> getSummaryById(String id) async {
    final snapshot = await _summariesCollection.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return SummaryModel.fromJson(snapshot.data()!);
  }

  /// Get all summaries for a user
  Future<List<SummaryModel>> getSummariesByUserId(
    String userId, {
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    debugPrint('SummaryRepo: Querying for userId: $userId');
    
    // Simple query without orderBy to avoid index requirement
    Query<Map<String, dynamic>> query = _summariesCollection
        .where('userId', isEqualTo: userId);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    debugPrint('SummaryRepo: Found ${snapshot.docs.length} documents');
    
    // Sort results in memory
    final results = snapshot.docs
        .map((doc) => SummaryModel.fromJson(doc.data()))
        .toList();
    
    // Sort by createdAt descending
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return results;
  }

  /// Stream of summaries for a user
  Stream<List<SummaryModel>> summariesStream(String userId, {int? limit}) {
    // Simple query without orderBy to avoid index requirement
    Query<Map<String, dynamic>> query = _summariesCollection
        .where('userId', isEqualTo: userId);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      final results = snapshot.docs
          .map((doc) => SummaryModel.fromJson(doc.data()))
          .toList();
      // Sort by createdAt descending
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    });
  }

  /// Get summaries by type
  Future<List<SummaryModel>> getSummariesByType(
    String userId,
    SummaryType type, {
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _summariesCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.value)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SummaryModel.fromJson(doc.data()))
        .toList();
  }

  /// Get summaries with actionable entities
  Future<List<SummaryModel>> getSummariesWithEntities(
    String userId, {
    bool hasDateTime = false,
    bool hasLocation = false,
  }) async {
    Query<Map<String, dynamic>> query = _summariesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (hasDateTime) {
      query = query.where('hasDateTimeEntity', isEqualTo: true);
    }

    if (hasLocation) {
      query = query.where('hasLocationEntity', isEqualTo: true);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SummaryModel.fromJson(doc.data()))
        .toList();
  }

  /// Update summary
  Future<void> updateSummary(SummaryModel summary) async {
    final updatedSummary = summary.copyWith(updatedAt: DateTime.now());
    await _summariesCollection.doc(summary.id).update(updatedSummary.toJson());
  }

  /// Update calendar sync status
  Future<void> updateCalendarSync(
    String summaryId, {
    required bool isCalendarSynced,
    String? calendarEventId,
  }) async {
    await _summariesCollection.doc(summaryId).update({
      'isCalendarSynced': isCalendarSynced,
      'calendarEventId': calendarEventId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update location reminder status
  Future<void> updateLocationReminderStatus(
    String summaryId, {
    required bool hasActiveLocationReminder,
    List<String>? activeGeofenceIds,
  }) async {
    final updates = <String, dynamic>{
      'hasActiveLocationReminder': hasActiveLocationReminder,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (activeGeofenceIds != null) {
      updates['activeGeofenceIds'] = activeGeofenceIds;
    }

    await _summariesCollection.doc(summaryId).update(updates);
  }

  /// Delete summary
  Future<void> deleteSummary(String id) async {
    // Note: Cloudinary files cannot be deleted via API without admin access
    // In production, you'd use Cloudinary Admin API or signed URLs
    
    // Delete document from Firestore
    await _summariesCollection.doc(id).delete();
  }

  /// Upload image file to Cloudinary
  Future<String> uploadImage(String userId, File imageFile) async {
    try {
      final url = await _cloudinary.uploadImage(
        imageFile,
        folder: 'neuranotte/$userId/images',
      );
      debugPrint('Image uploaded to Cloudinary: $url');
      return url;
    } catch (e) {
      debugPrint('Cloudinary upload failed, using placeholder: $e');
      // Return a placeholder URL since upload failed
      return 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
  }

  /// Upload audio file to Cloudinary
  Future<String> uploadAudio(String userId, File audioFile) async {
    try {
      final url = await _cloudinary.uploadAudio(
        audioFile,
        folder: 'neuranotte/$userId/audio',
      );
      debugPrint('Audio uploaded to Cloudinary: $url');
      return url;
    } catch (e) {
      debugPrint('Cloudinary upload failed, using placeholder: $e');
      // Return a placeholder URL since upload failed
      return 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
  }

  /// Upload thumbnail to Cloudinary
  Future<String> uploadThumbnail(String userId, File thumbnailFile) async {
    try {
      final url = await _cloudinary.uploadImage(
        thumbnailFile,
        folder: 'neuranotte/$userId/thumbnails',
      );
      return url;
    } catch (e) {
      return 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
  }

  /// Search summaries by text
  Future<List<SummaryModel>> searchSummaries(
    String userId,
    String searchQuery,
  ) async {
    // Firestore doesn't support full-text search natively
    // This is a simple approach - for production, consider Algolia or similar
    final allSummaries = await getSummariesByUserId(userId);
    final queryLower = searchQuery.toLowerCase();

    return allSummaries.where((summary) {
      return summary.summarizedText.toLowerCase().contains(queryLower) ||
          (summary.rawTranscript?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  /// Get summary count for user
  Future<int> getSummaryCount(String userId) async {
    final snapshot = await _summariesCollection
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get recent summaries
  Future<List<SummaryModel>> getRecentSummaries(
    String userId, {
    int limit = 10,
  }) async {
    return getSummariesByUserId(userId, limit: limit);
  }

  /// Batch delete summaries
  Future<void> batchDeleteSummaries(List<String> summaryIds) async {
    final batch = _firestore.batch();
    for (final id in summaryIds) {
      batch.delete(_summariesCollection.doc(id));
    }
    await batch.commit();
  }
}
