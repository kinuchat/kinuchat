import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service for recording voice messages
class VoiceRecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  /// Stream of recording amplitude for waveform visualization
  final _amplitudeController = StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  Timer? _amplitudeTimer;

  /// Whether currently recording
  bool get isRecording => _isRecording;

  /// Current recording duration
  Duration get recordingDuration {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Check if recording permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Request recording permission
  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording a voice message
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    // Check permission
    if (!await hasPermission()) {
      debugPrint('Recording permission not granted');
      return false;
    }

    try {
      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/voice_$timestamp.m4a';

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // AAC for good quality/size ratio
        bitRate: 128000, // 128kbps
        sampleRate: 44100,
        numChannels: 1, // Mono for voice
      );

      // Start recording
      await _recorder.start(config, path: _currentRecordingPath!);

      _isRecording = true;
      _recordingStartTime = DateTime.now();

      // Start amplitude monitoring for waveform
      _startAmplitudeMonitoring();

      return true;
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return false;
    }
  }

  /// Stop recording and return the recorded file
  Future<VoiceRecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      _stopAmplitudeMonitoring();

      final path = await _recorder.stop();
      final duration = recordingDuration;

      _isRecording = false;
      _recordingStartTime = null;

      if (path == null || path.isEmpty) {
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        return null;
      }

      return VoiceRecordingResult(
        file: file,
        duration: duration,
      );
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      _isRecording = false;
      _recordingStartTime = null;
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      _stopAmplitudeMonitoring();
      await _recorder.stop();

      // Delete the partial recording
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to cancel recording: $e');
    } finally {
      _isRecording = false;
      _recordingStartTime = null;
      _currentRecordingPath = null;
    }
  }

  /// Pause recording (if supported)
  Future<void> pauseRecording() async {
    if (!_isRecording) return;
    try {
      await _recorder.pause();
    } catch (e) {
      debugPrint('Failed to pause recording: $e');
    }
  }

  /// Resume recording (if supported)
  Future<void> resumeRecording() async {
    try {
      await _recorder.resume();
    } catch (e) {
      debugPrint('Failed to resume recording: $e');
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) async {
        try {
          final amplitude = await _recorder.getAmplitude();
          // Normalize to 0-1 range (amplitude.current is typically -160 to 0 dB)
          final normalized = ((amplitude.current + 160) / 160).clamp(0.0, 1.0);
          _amplitudeController.add(normalized);
        } catch (e) {
          // Ignore amplitude errors
        }
      },
    );
  }

  void _stopAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
  }

  /// Dispose resources
  void dispose() {
    _stopAmplitudeMonitoring();
    _amplitudeController.close();
    _recorder.dispose();
  }
}

/// Result of a voice recording
class VoiceRecordingResult {
  final File file;
  final Duration duration;

  VoiceRecordingResult({
    required this.file,
    required this.duration,
  });

  /// Duration in milliseconds
  int get durationMs => duration.inMilliseconds;
}
