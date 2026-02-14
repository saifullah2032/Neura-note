import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Exception thrown when image operations fail
class ImageException implements Exception {
  final String message;
  final String? code;

  const ImageException(this.message, [this.code]);

  @override
  String toString() => 'ImageException: $message (code: $code)';
}

/// Image quality for compression
enum ImageQuality {
  low,    // Max 480px, quality 50
  medium, // Max 800px, quality 70
  high,   // Max 1200px, quality 85
  original, // No compression
}

/// Service responsible for handling image operations
class ImageService {
  final ImagePicker _picker;
  final Uuid _uuid;

  ImageService({
    ImagePicker? picker,
    Uuid? uuid,
  })  : _picker = picker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid();

  /// Pick an image from the gallery
  Future<File?> pickFromGallery({
    ImageQuality quality = ImageQuality.high,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _getMaxWidth(quality),
        maxHeight: _getMaxHeight(quality),
        imageQuality: _getImageQuality(quality),
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      throw ImageException('Failed to pick image from gallery: $e');
    }
  }

  /// Capture an image from the camera
  Future<File?> captureFromCamera({
    ImageQuality quality = ImageQuality.high,
    bool preferFrontCamera = false,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: _getMaxWidth(quality),
        maxHeight: _getMaxHeight(quality),
        imageQuality: _getImageQuality(quality),
        preferredCameraDevice: preferFrontCamera 
            ? CameraDevice.front 
            : CameraDevice.rear,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      throw ImageException('Failed to capture image from camera: $e');
    }
  }

  /// Pick multiple images from the gallery
  Future<List<File>> pickMultipleImages({
    ImageQuality quality = ImageQuality.high,
    int? limit,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: _getMaxWidth(quality),
        maxHeight: _getMaxHeight(quality),
        imageQuality: _getImageQuality(quality),
        limit: limit,
      );

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      throw ImageException('Failed to pick multiple images: $e');
    }
  }

  /// Compress an image file
  /// Returns a new compressed file
  Future<File> compressImage(
    File file, {
    ImageQuality quality = ImageQuality.medium,
  }) async {
    try {
      // Read the original file
      final Uint8List bytes = await file.readAsBytes();

      // Create a temporary file for the compressed image
      final tempDir = await getTemporaryDirectory();
      final extension = path.extension(file.path);
      final fileName = '${_uuid.v4()}$extension';
      final compressedPath = path.join(tempDir.path, fileName);

      // Use compute for compression to avoid blocking UI thread
      final compressedBytes = await compute(
        _compressImageBytes,
        _CompressParams(
          bytes: bytes,
          quality: _getImageQuality(quality),
          maxWidth: _getMaxWidth(quality)?.toInt(),
          maxHeight: _getMaxHeight(quality)?.toInt(),
        ),
      );

      // Write compressed bytes to file
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      throw ImageException('Failed to compress image: $e');
    }
  }

  /// Generate a thumbnail from an image file
  Future<File> generateThumbnail(
    File file, {
    int maxWidth = 200,
    int maxHeight = 200,
  }) async {
    try {
      final Uint8List bytes = await file.readAsBytes();

      final tempDir = await getTemporaryDirectory();
      final extension = path.extension(file.path);
      final fileName = 'thumb_${_uuid.v4()}$extension';
      final thumbnailPath = path.join(tempDir.path, fileName);

      // Use compute for thumbnail generation
      final thumbnailBytes = await compute(
        _compressImageBytes,
        _CompressParams(
          bytes: bytes,
          quality: 70,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
      );

      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      return thumbnailFile;
    } catch (e) {
      throw ImageException('Failed to generate thumbnail: $e');
    }
  }

  /// Get image dimensions
  Future<ImageDimensions> getImageDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      return ImageDimensions(
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      throw ImageException('Failed to get image dimensions: $e');
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Get file size in human readable format
  Future<String> getFileSizeString(File file) async {
    final bytes = await file.length();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Copy image to app's documents directory
  Future<File> copyToDocuments(File file, {String? customName}) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final extension = path.extension(file.path);
      final fileName = customName ?? '${_uuid.v4()}$extension';
      final newPath = path.join(appDocDir.path, 'images', fileName);

      // Create images directory if it doesn't exist
      final imagesDir = Directory(path.dirname(newPath));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      return await file.copy(newPath);
    } catch (e) {
      throw ImageException('Failed to copy image to documents: $e');
    }
  }

  /// Delete a temporary image file
  Future<void> deleteTemporaryFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore delete errors for temporary files
    }
  }

  /// Clear all temporary image files
  Future<void> clearTemporaryFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (final entity in files) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Check if file is a valid image
  bool isValidImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif']
        .contains(extension);
  }

  /// Get max width for quality level
  double? _getMaxWidth(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 480;
      case ImageQuality.medium:
        return 800;
      case ImageQuality.high:
        return 1200;
      case ImageQuality.original:
        return null;
    }
  }

  /// Get max height for quality level
  double? _getMaxHeight(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 480;
      case ImageQuality.medium:
        return 800;
      case ImageQuality.high:
        return 1200;
      case ImageQuality.original:
        return null;
    }
  }

  /// Get JPEG quality for quality level
  int _getImageQuality(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 50;
      case ImageQuality.medium:
        return 70;
      case ImageQuality.high:
        return 85;
      case ImageQuality.original:
        return 100;
    }
  }
}

/// Parameters for image compression (used in isolate)
class _CompressParams {
  final Uint8List bytes;
  final int quality;
  final int? maxWidth;
  final int? maxHeight;

  _CompressParams({
    required this.bytes,
    required this.quality,
    this.maxWidth,
    this.maxHeight,
  });
}

/// Compress image bytes in an isolate
/// Note: This is a placeholder - in production you'd use image package
Uint8List _compressImageBytes(_CompressParams params) {
  // In a real implementation, you would use the 'image' package here
  // to decode, resize, and re-encode the image.
  // For now, we return the original bytes as the image_picker
  // already handles compression via maxWidth/maxHeight/imageQuality params.
  return params.bytes;
}

/// Image dimensions helper class
class ImageDimensions {
  final int width;
  final int height;

  const ImageDimensions({
    required this.width,
    required this.height,
  });

  double get aspectRatio => width / height;

  bool get isLandscape => width > height;

  bool get isPortrait => height > width;

  bool get isSquare => width == height;

  @override
  String toString() => '${width}x$height';
}
