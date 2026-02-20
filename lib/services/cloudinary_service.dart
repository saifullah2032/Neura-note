import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:neuranotteai/core/constants.dart';

/// Exception for Cloudinary errors
class CloudinaryException implements Exception {
  final String message;
  final int? statusCode;

  const CloudinaryException(this.message, {this.statusCode});

  @override
  String toString() => 'CloudinaryException: $message';
}

/// Service for uploading files to Cloudinary
class CloudinaryService {
  final String cloudName;
  final String apiKey;
  final String apiSecret;
  final http.Client _client;

  CloudinaryService({
    String? cloudName,
    String? apiKey,
    String? apiSecret,
    http.Client? client,
  })  : cloudName = cloudName ?? AppConstants.cloudinaryCloudName,
        apiKey = apiKey ?? AppConstants.cloudinaryApiKey,
        apiSecret = apiSecret ?? AppConstants.cloudinaryApiSecret,
        _client = client ?? http.Client();

  /// Upload an image to Cloudinary
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    return _uploadFile(imageFile, 'image', folder: folder ?? 'neuranotte');
  }

  /// Upload an audio file to Cloudinary
  Future<String> uploadAudio(File audioFile, {String? folder}) async {
    return _uploadFile(audioFile, 'video', folder: folder ?? 'neuranotte/audio');
  }

  /// Upload a file to Cloudinary
  Future<String> _uploadFile(File file, String resourceType, {String? folder}) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      
      // Generate signature
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signatureData = {
        'api_key': apiKey,
        'timestamp': timestamp.toString(),
        if (folder != null) 'folder': folder,
      };
      
      // Create signature string
      final signatureString = signatureData.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&') + apiSecret;
      
      // Generate SHA1 signature
      final signature = sha1.convert(utf8.encode(signatureString)).toString();

      // Build the URL
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

      // Create the multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add the file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));
      
      // Add form fields
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      if (folder != null) request.fields['folder'] = folder;

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = response.body;
        final data = json.decode(jsonResponse);
        return data['secure_url'] as String;
      } else {
        throw CloudinaryException(
          'Upload failed: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw CloudinaryException('Network error: ${e.message}');
    } catch (e) {
      if (e is CloudinaryException) rethrow;
      throw CloudinaryException('Upload failed: $e');
    }
  }

  /// Upload file from bytes
  Future<String> uploadFromBytes(Uint8List bytes, String fileName, {String? folder}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signatureData = {
        'api_key': apiKey,
        'timestamp': timestamp.toString(),
        if (folder != null) 'folder': folder,
      };
      
      final signatureString = signatureData.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&') + apiSecret;
      
      final signature = sha1.convert(utf8.encode(signatureString)).toString();

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      if (folder != null) request.fields['folder'] = folder;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'] as String;
      } else {
        throw CloudinaryException(
          'Upload failed: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CloudinaryException) rethrow;
      throw CloudinaryException('Upload failed: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
