import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/voice_recording_service.dart';

/// Provider for the voice recording service
final voiceRecordingServiceProvider = Provider<VoiceRecordingService>((ref) {
  final service = VoiceRecordingService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Widget for recording voice messages
class VoiceRecorderWidget extends ConsumerStatefulWidget {
  final void Function(VoiceRecordingResult recording)? onRecordingComplete;
  final VoidCallback? onCancel;

  const VoiceRecorderWidget({
    super.key,
    this.onRecordingComplete,
    this.onCancel,
  });

  @override
  ConsumerState<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends ConsumerState<VoiceRecorderWidget> {
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  Timer? _durationTimer;
  double _amplitude = 0.0;
  StreamSubscription<double>? _amplitudeSubscription;

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecording) {
      return IconButton(
        onPressed: _startRecording,
        icon: const Icon(Icons.mic),
        tooltip: 'Record voice message',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cancel button
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Cancel',
          ),

          // Recording indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 8),

          // Duration
          Text(
            _formatDuration(_duration),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),

          const SizedBox(width: 8),

          // Amplitude visualization
          SizedBox(
            width: 60,
            height: 20,
            child: CustomPaint(
              painter: _AmplitudePainter(_amplitude),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          IconButton(
            onPressed: _stopRecording,
            icon: const Icon(Icons.send, color: Colors.red),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    final service = ref.read(voiceRecordingServiceProvider);

    final hasPermission = await service.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required'),
          ),
        );
      }
      return;
    }

    final started = await service.startRecording();
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start recording'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _duration = Duration.zero;
    });

    // Start duration timer
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            _duration = service.recordingDuration;
          });
        }
      },
    );

    // Listen to amplitude
    _amplitudeSubscription = service.amplitudeStream.listen((amplitude) {
      if (mounted) {
        setState(() {
          _amplitude = amplitude;
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();

    final service = ref.read(voiceRecordingServiceProvider);
    final result = await service.stopRecording();

    setState(() {
      _isRecording = false;
      _duration = Duration.zero;
      _amplitude = 0.0;
    });

    if (result != null) {
      widget.onRecordingComplete?.call(result);
    }
  }

  Future<void> _cancelRecording() async {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();

    final service = ref.read(voiceRecordingServiceProvider);
    await service.cancelRecording();

    setState(() {
      _isRecording = false;
      _duration = Duration.zero;
      _amplitude = 0.0;
    });

    widget.onCancel?.call();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for amplitude visualization
class _AmplitudePainter extends CustomPainter {
  final double amplitude;

  _AmplitudePainter(this.amplitude);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 5;
    final barWidth = size.width / (barCount * 2 - 1);

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 2 + barWidth / 2;

      // Create varying heights based on position and amplitude
      final baseHeight = 0.3 + (i == 2 ? 0.4 : (i == 1 || i == 3 ? 0.2 : 0));
      final height = size.height * (baseHeight + amplitude * 0.5) * 0.8;

      final y1 = (size.height - height) / 2;
      final y2 = y1 + height;

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmplitudePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude;
  }
}

/// Inline voice recorder that appears in the message input area
class InlineVoiceRecorder extends ConsumerStatefulWidget {
  final void Function(VoiceRecordingResult recording) onRecordingComplete;
  final VoidCallback onCancel;

  const InlineVoiceRecorder({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  ConsumerState<InlineVoiceRecorder> createState() => _InlineVoiceRecorderState();
}

class _InlineVoiceRecorderState extends ConsumerState<InlineVoiceRecorder> {
  Duration _duration = Duration.zero;
  Timer? _durationTimer;
  double _amplitude = 0.0;
  StreamSubscription<double>? _amplitudeSubscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final service = ref.read(voiceRecordingServiceProvider);

    final started = await service.startRecording();
    if (!started) {
      widget.onCancel();
      return;
    }

    setState(() {
      _initialized = true;
    });

    // Start duration timer
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            _duration = service.recordingDuration;
          });
        }
      },
    );

    // Listen to amplitude
    _amplitudeSubscription = service.amplitudeStream.listen((amplitude) {
      if (mounted) {
        setState(() {
          _amplitude = amplitude;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Cancel button
          IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),

          // Recording indicator and duration
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                // Waveform visualization
                SizedBox(
                  width: 80,
                  height: 24,
                  child: CustomPaint(
                    painter: _AmplitudePainter(_amplitude),
                  ),
                ),
              ],
            ),
          ),

          // Send button
          IconButton(
            onPressed: _send,
            icon: const Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();

    final service = ref.read(voiceRecordingServiceProvider);
    final result = await service.stopRecording();

    if (result != null) {
      widget.onRecordingComplete(result);
    } else {
      widget.onCancel();
    }
  }

  Future<void> _cancel() async {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();

    final service = ref.read(voiceRecordingServiceProvider);
    await service.cancelRecording();

    widget.onCancel();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
