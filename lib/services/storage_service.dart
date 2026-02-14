import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Exception thrown when storage operations fail
class StorageException implements Exception {
  final String message;
  final String? code;

  const StorageException(this.message, [this.code]);

  @override
  String toString() => 'StorageException: $message (code: $code)';
}

/// Upload progress callback
typedef UploadProgressCallback = void Function(double progress);

/// Service responsible for handling Firebase Storage operations
class StorageService {
  final FirebaseStorage _storage;
  final Uuid _uuid;

  StorageService({
    FirebaseStorage? storage,
    Uuid? uuid,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _uuid = uuid ?? const Uuid();

  // Storage paths
  static const String _imagesPath = 'images';
  static const String _audioPath = 'audio';
  static const String _thumbnailsPath = 'thumbnails';

  /// Upload an image file to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadImage(
    File file, {
    required String userId,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final fileName = _generateFileName(file.path, 'img');
      final ref = _storage.ref().child('$_imagesPath/$userId/$fileName');
      
      return await _uploadFile(
        ref,
        file,
        contentType: _getImageContentType(file.path),
        onProgress: onProgress,
      );
    } on FirebaseException catch (e) {
      throw StorageException(
        'Failed to upload image: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw StorageException('Failed to upload image: $e');
    }
  }

  /// Upload an audio file to Firebase Storage
  /// Returns the download URL of the uploaded audio
  Future<String> uploadAudio(
    File file, {
    required String userId,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final fileName = _generateFileName(file.path, 'aud');
      final ref = _storage.ref().child('$_audioPath/$userId/$fileName');
      
      return await _uploadFile(
        ref,
        file,
        contentType: _getAudioContentType(file.path),
        onProgress: onProgress,
      );
    } on FirebaseException catch (e) {
      throw StorageException(
        'Failed to upload audio: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw StorageException('Failed to upload audio: $e');
    }
  }

  /// Upload a thumbnail image
  /// Returns the download URL of the uploaded thumbnail
  Future<String> uploadThumbnail(
    File file, {
    required String userId,
    required String summaryId,
  }) async {
    try {
      final extension = path.extension(file.path);
      final fileName = '${summaryId}_thumb$extension';
      final ref = _storage.ref().child('$_thumbnailsPath/$userId/$fileName');
      
      return await _uploadFile(
        ref,
        file,
        contentType: _getImageContentType(file.path),
      );
    } on FirebaseException catch (e) {
      throw StorageException(
        'Failed to upload thumbnail: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw StorageException('Failed to upload thumbnail: $e');
    }
  }

  /// Upload a file with progress tracking
  Future<String> _uploadFile(
    Reference ref,
    File file, {
    String? contentType,
    UploadProgressCallback? onProgress,
  }) async {
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = ref.putFile(file, metadata);

    // Track upload progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    // Wait for upload to complete
    await uploadTask;

    // Return download URL
    return await ref.getDownloadURL();
  }

  /// Delete a file from Firebase Storage by URL
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      // Ignore if file doesn't exist
      if (e.code != 'object-not-found') {
        throw StorageException(
          'Failed to delete file: ${e.message}',
          e.code,
        );
      }
    } catch (e) {
      throw StorageException('Failed to delete file: $e');
    }
  }

  /// Delete multiple files from Firebase Storage
  Future<void> deleteFiles(List<String> urls) async {
    await Future.wait(
      urls.map((url) => deleteFile(url)),
      eagerError: false,
    );
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      return await ref.getMetadata();
    } on FirebaseException catch (e) {
      throw StorageException(
        'Failed to get file metadata: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw StorageException('Failed to get file metadata: $e');
    }
  }

  /// Get file download URL from storage path
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        'Failed to get download URL: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw StorageException('Failed to get download URL: $e');
    }
  }

  /// List all files in a user's images folder
  Future<List<Reference>> listUserImages(String userId) async {
    try {
      final ref = _storage.ref().child('$_imagesPath/$userId');
      final result = await ref.listAll();
      return result.items;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Failed to list images: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw StorageException('Failed to list images: $e');
    }
  }

  /// List all files in a user's audio folder
  Future<List<Reference>> listUserAudio(String userId) async {
    try {
      final ref = _storage.ref().child('$_audioPath/$userId');
      final result = await ref.listAll();
      return result.items;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Failed to list audio: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw StorageException('Failed to list audio: $e');
    }
  }

  /// Delete all files for a user
  Future<void> deleteAllUserFiles(String userId) async {
    try {
      // Delete images
      final imageRefs = await listUserImages(userId);
      for (final ref in imageRefs) {
        await ref.delete();
      }

      // Delete audio
      final audioRefs = await listUserAudio(userId);
      for (final ref in audioRefs) {
        await ref.delete();
      }

      // Delete thumbnails
      try {
        final thumbnailRef = _storage.ref().child('$_thumbnailsPath/$userId');
        final thumbnailResult = await thumbnailRef.listAll();
        for (final ref in thumbnailResult.items) {
          await ref.delete();
        }
      } catch (_) {
        // Ignore if thumbnails folder doesn't exist
      }
    } on FirebaseException catch (e) {
      throw StorageException(
        'Failed to delete user files: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw StorageException('Failed to delete user files: $e');
    }
  }

  /// Generate a unique filename with timestamp
  String _generateFileName(String originalPath, String prefix) {
    final extension = path.extension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = _uuid.v4().substring(0, 8);
    return '${prefix}_${timestamp}_$uniqueId$extension';
  }

  /// Get content type for image files
  String _getImageContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  /// Get content type for audio files
  String _getAudioContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.m4a':
        return 'audio/m4a';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
        return 'audio/ogg';
      case '.webm':
        return 'audio/webm';
      default:
        return 'audio/m4a';
    }
  }
}
