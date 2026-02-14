import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Exception thrown when audio operations fail
class AudioException implements Exception {
  final String message;
  final String? code;

  const AudioException(this.message, [this.code]);

  @override
  String toString() => 'AudioException: $message (code: $code)';
}

/// Audio recording state
enum RecordingState {
  idle,
  recording,
  paused,
  stopped,
}

/// Audio format for recording
enum AudioFormat {
  m4a,
  wav,
  aac,
}

/// Service responsible for handling audio recording operations
class AudioService {
  final AudioRecorder _recorder;
  final Uuid _uuid;

  RecordingState _state = RecordingState.idle;
  String? _currentFilePath;
  DateTime? _recordingStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;

  StreamController<double>? _amplitudeController;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _durationTimer;
  StreamController<Duration>? _durationController;

  AudioService({
    AudioRecorder? recorder,
    Uuid? uuid,
  })  : _recorder = recorder ?? AudioRecorder(),
        _uuid = uuid ?? const Uuid();

  /// Get current recording state
  RecordingState get state => _state;

  /// Check if currently recording
  bool get isRecording => _state == RecordingState.recording;

  /// Check if recording is paused
  bool get isPaused => _state == RecordingState.paused;

  /// Check if recorder is idle
  bool get isIdle => _state == RecordingState.idle;

  /// Get the current recording file path
  String? get currentFilePath => _currentFilePath;

  /// Stream of amplitude values (0.0 to 1.0) for waveform visualization
  Stream<double> get amplitudeStream {
    _amplitudeController ??= StreamController<double>.broadcast();
    return _amplitudeController!.stream;
  }

  /// Stream of recording duration
  Stream<Duration> get durationStream {
    _durationController ??= StreamController<Duration>.broadcast();
    return _durationController!.stream;
  }

  /// Get current recording duration
  Duration get currentDuration {
    if (_recordingStartTime == null) return Duration.zero;
    
    final elapsed = DateTime.now().difference(_recordingStartTime!);
    
    if (_state == RecordingState.paused && _pauseStartTime != null) {
      final pauseElapsed = DateTime.now().difference(_pauseStartTime!);
      return elapsed - _pausedDuration - pauseElapsed;
    }
    
    return elapsed - _pausedDuration;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording audio
  Future<void> startRecording({
    AudioFormat format = AudioFormat.m4a,
    int sampleRate = 44100,
    int bitRate = 128000,
    int numChannels = 1,
  }) async {
    if (_state == RecordingState.recording) {
      throw AudioException('Already recording');
    }

    // Check permission
    if (!await hasPermission()) {
      throw AudioException('Microphone permission not granted', 'permission_denied');
    }

    try {
      // Generate unique file path
      final tempDir = await getTemporaryDirectory();
      final extension = _getExtension(format);
      final fileName = 'recording_${_uuid.v4()}.$extension';
      _currentFilePath = path.join(tempDir.path, fileName);

      // Configure recording
      final config = RecordConfig(
        encoder: _getEncoder(format),
        sampleRate: sampleRate,
        bitRate: bitRate,
        numChannels: numChannels,
      );

      // Start recording
      await _recorder.start(config, path: _currentFilePath!);

      _state = RecordingState.recording;
      _recordingStartTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _pauseStartTime = null;

      // Start amplitude monitoring
      _startAmplitudeMonitoring();
      
      // Start duration tracking
      _startDurationTracking();
    } catch (e) {
      _state = RecordingState.idle;
      _currentFilePath = null;
      throw AudioException('Failed to start recording: $e');
    }
  }

  /// Stop recording and return the recorded file
  Future<File?> stopRecording() async {
    if (_state == RecordingState.idle) {
      return null;
    }

    try {
      // Stop amplitude monitoring
      _stopAmplitudeMonitoring();
      _stopDurationTracking();

      // Stop recording
      final filePath = await _recorder.stop();

      _state = RecordingState.stopped;

      if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          return file;
        }
      }

      // Fallback to stored path
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          return file;
        }
      }

      return null;
    } catch (e) {
      throw AudioException('Failed to stop recording: $e');
    } finally {
      _reset();
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_state != RecordingState.recording) {
      throw AudioException('Not currently recording');
    }

    try {
      await _recorder.pause();
      _state = RecordingState.paused;
      _pauseStartTime = DateTime.now();
      
      _stopAmplitudeMonitoring();
    } catch (e) {
      throw AudioException('Failed to pause recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_state != RecordingState.paused) {
      throw AudioException('Recording is not paused');
    }

    try {
      await _recorder.resume();
      _state = RecordingState.recording;
      
      // Calculate paused duration
      if (_pauseStartTime != null) {
        _pausedDuration += DateTime.now().difference(_pauseStartTime!);
        _pauseStartTime = null;
      }
      
      _startAmplitudeMonitoring();
    } catch (e) {
      throw AudioException('Failed to resume recording: $e');
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    try {
      _stopAmplitudeMonitoring();
      _stopDurationTracking();

      if (_state == RecordingState.recording || _state == RecordingState.paused) {
        await _recorder.stop();
      }

      // Delete the file if it exists
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore cancellation errors
    } finally {
      _reset();
    }
  }

  /// Get audio file duration
  Future<Duration?> getAudioDuration(File file) async {
    // Note: The record package doesn't provide duration reading.
    // In production, you'd use a package like 'just_audio' or 'audioplayers'
    // to get the actual duration.
    return null;
  }

  /// Copy audio file to app documents
  Future<File> copyToDocuments(File file, {String? customName}) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final extension = path.extension(file.path);
      final fileName = customName ?? '${_uuid.v4()}$extension';
      final newPath = path.join(appDocDir.path, 'audio', fileName);

      // Create audio directory if it doesn't exist
      final audioDir = Directory(path.dirname(newPath));
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      return await file.copy(newPath);
    } catch (e) {
      throw AudioException('Failed to copy audio to documents: $e');
    }
  }

  /// Delete temporary audio files
  Future<void> clearTemporaryFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final entity in files) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (fileName.startsWith('recording_')) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await cancelRecording();
    await _amplitudeController?.close();
    await _durationController?.close();
    _recorder.dispose();
  }

  /// Start monitoring amplitude for waveform visualization
  void _startAmplitudeMonitoring() {
    _amplitudeController ??= StreamController<double>.broadcast();

    _amplitudeSubscription = _recorder.onAmplitudeChanged(
      const Duration(milliseconds: 100),
    ).listen((amplitude) {
      // Normalize amplitude from dB to 0.0-1.0 range
      // Typical values: -160 (silence) to 0 (max)
      final normalized = ((amplitude.current + 160) / 160).clamp(0.0, 1.0);
      _amplitudeController?.add(normalized);
    });
  }

  /// Stop amplitude monitoring
  void _stopAmplitudeMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
  }

  /// Start duration tracking
  void _startDurationTracking() {
    _durationController ??= StreamController<Duration>.broadcast();
    
    _durationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (_state == RecordingState.recording) {
          _durationController?.add(currentDuration);
        }
      },
    );
  }

  /// Stop duration tracking
  void _stopDurationTracking() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// Reset all state
  void _reset() {
    _state = RecordingState.idle;
    _currentFilePath = null;
    _recordingStartTime = null;
    _pausedDuration = Duration.zero;
    _pauseStartTime = null;
  }

  /// Get file extension for format
  String _getExtension(AudioFormat format) {
    switch (format) {
      case AudioFormat.m4a:
        return 'm4a';
      case AudioFormat.wav:
        return 'wav';
      case AudioFormat.aac:
        return 'aac';
    }
  }

  /// Get encoder for format
  AudioEncoder _getEncoder(AudioFormat format) {
    switch (format) {
      case AudioFormat.m4a:
        return AudioEncoder.aacLc;
      case AudioFormat.wav:
        return AudioEncoder.wav;
      case AudioFormat.aac:
        return AudioEncoder.aacLc;
    }
  }
}
