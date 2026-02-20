import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/env_config.dart';
import '../../model/summary_model.dart';
import '../../model/reminder_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/summary_provider.dart';
import '../../repo/summary_repo.dart';
import '../../services/audio_service.dart';
import '../../services/speech_to_text_service.dart';
import '../../services/summarization_orchestrator.dart';
import '../widgets/entity_chip.dart';
import '../widgets/location_picker.dart';
import '../widgets/ocean_animations.dart';

class SummarizeScreen extends StatefulWidget {
  const SummarizeScreen({super.key});

  @override
  State<SummarizeScreen> createState() => _SummarizeScreenState();
}

class _SummarizeScreenState extends State<SummarizeScreen>
    with SingleTickerProviderStateMixin {
  final Color _offWhite = const Color(0xFFF8F9FA);
  final Color _teal = Colors.teal;
  
  // Audio service for recording
  late AudioService _audioService;
  
  // Input state
  File? _selectedImage;
  File? _recordedAudio;
  bool _isRecording = false;
  
  // Processing state
  bool _isProcessing = false;
  SummarizationStage? _currentStage;
  double _progress = 0;
  String? _statusMessage;
  
  // Result state
  SummarizationPipelineResult? _result;
  String? _errorMessage;
  
  // Entity selection state
  DateTimeEntity? _selectedDateTimeEntity;
  LocationEntity? _selectedLocationEntity;
  
  // Animation controller for recording pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Load existing summary if coming from home screen tap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingSummary();
    });
  }

  void _loadExistingSummary() {
    final summaryProvider = context.read<SummaryProvider>();
    final currentSummary = summaryProvider.currentSummary;
    debugPrint('Checking for existing summary: $currentSummary');
    if (currentSummary != null) {
      // Convert SummaryModel to SummarizationPipelineResult
      _result = SummarizationPipelineResult(
        summaryId: currentSummary.id,
        type: currentSummary.type,
        originalContentUrl: currentSummary.originalContentUrl,
        summary: currentSummary.summarizedText,
        thumbnailUrl: currentSummary.thumbnailUrl,
        transcript: currentSummary.rawTranscript,
        dateTimes: currentSummary.extractedDateTimes,
        locations: currentSummary.extractedLocations,
        tokensUsed: currentSummary.tokensCost,
        confidenceScore: currentSummary.confidenceScore ?? 1.0,
        processingTime: Duration.zero,
        metadata: currentSummary.metadata,
      );
      setState(() {});
      debugPrint('Loaded existing summary: ${_result!.summary.substring(0, 50)}...');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      body: OceanBackground(
        primaryColor: _teal,
        waveHeight: 80,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isProcessing
                    ? _buildProcessingView()
                    : _result != null
                        ? _buildResultView()
                        : _buildInputView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: _teal, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _result != null ? "SUMMARY" : "NEW NOTE",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          if (_result != null)
            TextButton(
              onPressed: _resetState,
              child: Text(
                'New',
                style: GoogleFonts.poppins(
                  color: _teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image capture section
          _buildImageSection(),
          const SizedBox(height: 24),
          
          // OR divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Voice recording section
          _buildVoiceSection(),
          
          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
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

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image preview or placeholder
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: _teal.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add image',
                          style: GoogleFonts.poppins(
                            color: _teal.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _teal,
                      side: BorderSide(color: _teal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedImage != null ? _processImage : null,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Summarize'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Voice Recording',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRecording
                ? 'Recording... Tap to stop'
                : _recordedAudio != null
                    ? 'Recording ready'
                    : 'Tap the microphone to start',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Recording button
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : _teal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : _teal).withOpacity(0.3),
                          blurRadius: _isRecording ? 20 : 12,
                          spreadRadius: _isRecording ? 4 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_recordedAudio != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _processAudio,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Summarize Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI Loading Animation or progress indicator
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(_teal),
                    backgroundColor: _teal.withOpacity(0.2),
                  ),
                  Icon(
                    _getStageIcon(),
                    size: 40,
                    color: _teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _currentStage?.displayName ?? 'Processing...',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade700,
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_teal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _teal.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        result.type == SummaryType.image
                            ? Icons.image
                            : Icons.mic,
                        color: _teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.type == SummaryType.image
                                ? 'Image Summary'
                                : 'Voice Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Processed in ${result.processingTime.inSeconds}s',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Summary text with entity highlighting
                if (result.hasDateTimeEntities || result.hasLocationEntities)
                  HighlightedText(
                    text: result.summary,
                    dateTimeEntities: result.dateTimes,
                    locationEntities: result.locations,
                    onDateTimeTap: (entity) => _selectDateTimeEntity(entity),
                    onLocationTap: (entity) => _selectLocationEntity(entity),
                  )
                else
                  Text(
                    result.summary,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                      height: 1.6,
                    ),
                  ),
                  
                // Transcript (for voice)
                if (result.transcript != null) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(
                      'Full Transcript',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      Text(
                        result.transcript!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Extracted entities section
          if (result.hasAnyEntities) ...[
            const SizedBox(height: 24),
            _buildEntitiesSection(result),
          ],
          
          // Action buttons
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEntitiesSection(SummarizationPipelineResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Entities',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            'Tap to create a reminder',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          
          // Date/Time entities
          if (result.hasDateTimeEntities) ...[
            EntitySection(
              title: 'Dates & Times',
              icon: Icons.calendar_today,
              color: Colors.blue,
              children: result.dateTimes.map((entity) {
                return EntityChip.dateTime(
                  entity: entity,
                  isSelected: _selectedDateTimeEntity == entity,
                  onTap: () => _selectDateTimeEntity(entity),
                );
              }).toList(),
            ),
            if (result.hasLocationEntities) const SizedBox(height: 20),
          ],
          
          // Location entities
          if (result.hasLocationEntities)
            EntitySection(
              title: 'Locations',
              icon: Icons.location_on,
              color: Colors.orange,
              children: result.locations.map((entity) {
                return EntityChip.location(
                  entity: entity,
                  isSelected: _selectedLocationEntity == entity,
                  onTap: () => _selectLocationEntity(entity),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasDateEntity = _selectedDateTimeEntity != null;
    final hasLocationEntity = _selectedLocationEntity != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick reminder buttons based on selected entities
        if (hasDateEntity || hasLocationEntity)
          ReminderTypeSelector(
            hasDateTimeEntities: hasDateEntity,
            hasLocationEntities: hasLocationEntity,
            onCalendarTap: hasDateEntity ? _createCalendarReminder : null,
            onLocationTap: hasLocationEntity ? _showLocationPicker : null,
          ),
          
        const SizedBox(height: 16),
        
        // Save summary button
        ElevatedButton.icon(
          onPressed: _saveSummary,
          icon: const Icon(Icons.save),
          label: const Text('Save Summary'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // View reminders button
        OutlinedButton.icon(
          onPressed: () => context.pushNamed('reminders'),
          icon: const Icon(Icons.notifications_outlined),
          label: const Text('View Reminders'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _teal,
            side: BorderSide(color: _teal),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  IconData _getStageIcon() {
    switch (_currentStage) {
      case SummarizationStage.uploading:
        return Icons.cloud_upload;
      case SummarizationStage.transcribing:
        return Icons.hearing;
      case SummarizationStage.analyzing:
        return Icons.psychology;
      case SummarizationStage.extractingEntities:
        return Icons.search;
      case SummarizationStage.resolvingLocations:
        return Icons.location_searching;
      case SummarizationStage.finalizing:
        return Icons.check_circle_outline;
      case SummarizationStage.complete:
        return Icons.done_all;
      case SummarizationStage.error:
        return Icons.error_outline;
      default:
        return Icons.auto_awesome;
    }
  }

  void _resetState() {
    setState(() {
      _selectedImage = null;
      _recordedAudio = null;
      _isProcessing = false;
      _currentStage = null;
      _progress = 0;
      _statusMessage = null;
      _result = null;
      _errorMessage = null;
      _selectedDateTimeEntity = null;
      _selectedLocationEntity = null;
    });
  }

  // ============================================================
  // IMAGE HANDLING
  // ============================================================

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _errorMessage = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _errorMessage = null;
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;
    
    debugPrint('Processing image: ${_selectedImage!.path}');
    debugPrint('HuggingFace API Key: ${envConfig.huggingFaceApiKey.isNotEmpty ? "SET" : "NOT SET"}');
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Use environment config for API keys
      final orchestrator = SummarizationOrchestrator(
        config: SummarizationConfig(
          googleMapsApiKey: envConfig.googleMapsApiKey,
          groqApiKey: envConfig.groqApiKey,
          huggingFaceApiKey: envConfig.huggingFaceApiKey,
          speechProvider: SpeechToTextProvider.whisper,
        ),
      );

      debugPrint('Starting image summarization...');
      final result = await orchestrator.summarizeImage(
        filePath: _selectedImage!.path,
        userId: context.read<AuthProvider>().userId,
        onProgress: (stage, progress, message) {
          debugPrint('Stage: $stage, Progress: $progress, Message: $message');
          setState(() {
            _currentStage = stage;
            _progress = progress;
            _statusMessage = message;
          });
        },
      );
      
      debugPrint('Image summarization complete. Result: ${result.summary.substring(0, result.summary.length > 100 ? 100 : result.summary.length)}...');

      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Image summarization error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // AUDIO HANDLING
  // ============================================================

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() async {
    try {
      // Check permission
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Microphone permission denied';
        });
        return;
      }
      
      // Start recording
      await _audioService.startRecording();
      
      setState(() {
        _isRecording = true;
        _errorMessage = null;
      });
      _pulseController.repeat(reverse: true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start recording: $e';
      });
    }
  }

  void _stopRecording() async {
    try {
      // Stop recording and get the file
      final audioFile = await _audioService.stopRecording();
      
      _pulseController.stop();
      _pulseController.reset();
      
      if (audioFile != null) {
        setState(() {
          _isRecording = false;
          _recordedAudio = audioFile;
        });
      } else {
        setState(() {
          _isRecording = false;
          _errorMessage = 'Recording failed - no audio file created';
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorMessage = 'Failed to stop recording: $e';
      });
    }
  }

  Future<void> _processAudio() async {
    if (_recordedAudio == null) {
      debugPrint('No audio file recorded');
      _showError('No audio file recorded');
      return;
    }
    
    debugPrint('Processing audio file: ${_recordedAudio!.path}');
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Use environment config for API keys
      debugPrint('Groq API Key: ${envConfig.groqApiKey.isNotEmpty ? "SET" : "NOT SET"}');
      
      final orchestrator = SummarizationOrchestrator(
        config: SummarizationConfig(
          googleMapsApiKey: envConfig.googleMapsApiKey,
          groqApiKey: envConfig.groqApiKey,
          huggingFaceApiKey: envConfig.huggingFaceApiKey,
          speechProvider: SpeechToTextProvider.whisper,
        ),
      );

      debugPrint('Starting audio summarization...');
      final result = await orchestrator.summarizeAudio(
        filePath: _recordedAudio!.path,
        userId: context.read<AuthProvider>().userId,
        onProgress: (stage, progress, message) {
          debugPrint('Stage: $stage, Progress: $progress, Message: $message');
          setState(() {
            _currentStage = stage;
            _progress = progress;
            _statusMessage = message;
          });
        },
      );
      
      debugPrint('Audio summarization complete. Result: ${result.summary.substring(0, result.summary.length > 100 ? 100 : result.summary.length)}...');

      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Audio processing error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // ENTITY SELECTION
  // ============================================================

  void _selectDateTimeEntity(DateTimeEntity entity) {
    setState(() {
      _selectedDateTimeEntity =
          _selectedDateTimeEntity == entity ? null : entity;
    });
  }

  void _selectLocationEntity(LocationEntity entity) {
    setState(() {
      _selectedLocationEntity =
          _selectedLocationEntity == entity ? null : entity;
    });
  }

  // ============================================================
  // REMINDER CREATION
  // ============================================================

  Future<void> _createCalendarReminder() async {
    if (_selectedDateTimeEntity == null || _result == null) return;

    final authProvider = context.read<AuthProvider>();
    final reminderProvider = context.read<ReminderProvider>();
    
    if (authProvider.user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Calendar Reminder',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a reminder for:',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, y • h:mm a')
                        .format(_selectedDateTimeEntity!.parsedDateTime),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: _teal)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _teal),
            child: Text('Create', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await reminderProvider.createCalendarReminderFromEntity(
        summaryId: _result!.summaryId,
        userId: authProvider.user!.uid,
        dateTimeEntity: _selectedDateTimeEntity!,
        title: _result!.summary.split('\n').first.substring(0, 
            _result!.summary.split('\n').first.length.clamp(0, 50)),
        description: _result!.summary,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  result.calendarEventCreated
                      ? 'Reminder created & synced to calendar'
                      : 'Reminder created',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _selectedDateTimeEntity = null);
      }
    }
  }

  void _showLocationPicker() {
    if (_selectedLocationEntity == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerSheet(
        initialEntity: _selectedLocationEntity,
        onConfirm: _createLocationReminder,
      ),
    );
  }

  Future<void> _createLocationReminder(
    GeoLocation location,
    double radius,
    GeofenceTriggerType triggerType,
  ) async {
    if (_result == null) return;

    final authProvider = context.read<AuthProvider>();
    final reminderProvider = context.read<ReminderProvider>();
    
    if (authProvider.user == null) return;

    final result = await reminderProvider.createLocationReminder(
      summaryId: _result!.summaryId,
      userId: authProvider.user!.uid,
      title: _result!.summary.split('\n').first.substring(0,
          _result!.summary.split('\n').first.length.clamp(0, 50)),
      description: _result!.summary,
      targetLocation: location,
      radiusInMeters: radius,
      triggerType: triggerType,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Location reminder created',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _selectedLocationEntity = null);
    }
  }

  Future<void> _saveSummary() async {
    if (_result == null) {
      _showError('No summary to save');
      return;
    }

    try {
      // Get the user ID
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) {
        _showError('Please sign in to save');
        return;
      }

      debugPrint('Saving summary for user: $userId');

      // Show saving indicator
      setState(() {
        _isProcessing = true;
      });

      // Use SummaryRepository to save directly
      final summaryRepo = SummaryRepository();
      final savedSummary = await summaryRepo.createSummary(
        userId: userId,
        type: _result!.type,
        originalContentUrl: _result!.originalContentUrl,
        summarizedText: _result!.summary,
        thumbnailUrl: _result!.thumbnailUrl,
        rawTranscript: _result!.transcript,
        extractedDateTimes: _result!.dateTimes,
        extractedLocations: _result!.locations,
        tokensCost: _result!.tokensUsed,
        confidenceScore: _result!.confidenceScore,
        metadata: _result!.metadata,
      );

      debugPrint('Summary saved with ID: ${savedSummary.id}');

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Summary saved successfully!', style: GoogleFonts.poppins()),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Redirect to home after successful save
        context.goNamed('home');
      }
    } catch (e, stackTrace) {
      debugPrint('Save error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to save: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: GoogleFonts.poppins())),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
