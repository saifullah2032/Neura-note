import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/themes.dart';
import '../../core/fluid_components.dart';
import '../../services/audio_service.dart';
import '../widgets/ocean_animations.dart';

class VoiceSummarizationInput extends StatefulWidget {
  final File? recordedAudio;
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final Function(File) onProcessAudio;

  const VoiceSummarizationInput({
    super.key,
    this.recordedAudio,
    this.isRecording = false,
    this.isProcessing = false,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onProcessAudio,
  });

  @override
  State<VoiceSummarizationInput> createState() => _VoiceSummarizationInputState();
}

class _VoiceSummarizationInputState extends State<VoiceSummarizationInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceSummarizationInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return OceanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: colorScheme.primary.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(4),
                 ),
                child: Icon(
                  Icons.mic,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Voice Summary',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.isRecording
                ? 'Recording... Tap to stop'
                : widget.recordedAudio != null
                    ? 'Recording ready'
                    : 'Tap the microphone to start recording',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: GestureDetector(
              onTap: widget.isRecording ? widget.onStopRecording : widget.onStartRecording,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.isRecording ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: widget.isRecording ? colorScheme.error : colorScheme.primary,
                        shape: BoxShape.circle,
                         boxShadow: [
                           BoxShadow(
                             color: (widget.isRecording ? colorScheme.error : colorScheme.primary)
                                 .withValues(alpha: 0.3),
                             blurRadius: 0,
                             spreadRadius: widget.isRecording ? 4 : 2,
                           ),
                         ],
                      ),
                      child: Icon(
                        widget.isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          if (widget.recordedAudio != null && !widget.isRecording) ...[
            const SizedBox(height: 24),
            LiquidButton(
              onPressed: !widget.isProcessing 
                  ? () => widget.onProcessAudio(widget.recordedAudio!)
                  : null,
              backgroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: widget.isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Summarize Recording',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class VoiceSummarizationInputWithRecorder extends StatefulWidget {
  final Function(File) onProcessAudio;
  final bool isProcessing;

  const VoiceSummarizationInputWithRecorder({
    super.key,
    required this.onProcessAudio,
    this.isProcessing = false,
  });

  @override
  State<VoiceSummarizationInputWithRecorder> createState() => _VoiceSummarizationInputWithRecorderState();
}

class _VoiceSummarizationInputWithRecorderState extends State<VoiceSummarizationInputWithRecorder> {
  final AudioService _audioService = AudioService();
  File? _recordedAudio;
  bool _isRecording = false;

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone permission denied')),
          );
        }
        return;
      }
      
      await _audioService.startRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final audioFile = await _audioService.stopRecording();
      setState(() {
        _isRecording = false;
        _recordedAudio = audioFile;
      });
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  void _processAudio() {
    if (_recordedAudio != null) {
      widget.onProcessAudio(_recordedAudio!);
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VoiceSummarizationInput(
      recordedAudio: _recordedAudio,
      isRecording: _isRecording,
      isProcessing: widget.isProcessing,
      onStartRecording: () => _startRecording(),
      onStopRecording: () => _stopRecording(),
      onProcessAudio: (File file) => widget.onProcessAudio(file),
    );
  }
}
