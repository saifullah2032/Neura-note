import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/themes.dart';
import '../../core/fluid_components.dart';
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
import '../widgets/image_summarization_input.dart';
import '../widgets/voice_summarization_input.dart';

class SummarizeScreen extends StatefulWidget {
  const SummarizeScreen({super.key});

  @override
  State<SummarizeScreen> createState() => _SummarizeScreenState();
}

class _SummarizeScreenState extends State<SummarizeScreen>
    with SingleTickerProviderStateMixin {
  late AudioService _audioService;
  
  File? _selectedImage;
  File? _recordedAudio;
  bool _isRecording = false;
  
  bool _isProcessing = false;
  SummarizationStage? _currentStage;
  double _progress = 0;
  String? _statusMessage;
  
  SummarizationPipelineResult? _result;
  String? _errorMessage;
  
  DateTimeEntity? _selectedDateTimeEntity;
  LocationEntity? _selectedLocationEntity;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingSummary();
    });
  }

  void _loadExistingSummary() {
    final summaryProvider = context.read<SummaryProvider>();
    final currentSummary = summaryProvider.currentSummary;
    if (currentSummary != null) {
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
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: OceanBackground(
        primaryColor: colorScheme.primary,
        waveHeight: 80,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, colorScheme, textTheme),
              Expanded(
                child: _isProcessing
                    ? _buildProcessingView(colorScheme, textTheme)
                    : _result != null
                        ? _buildResultView(context, colorScheme, textTheme)
                        : _buildInputView(context, colorScheme, textTheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
               color: colorScheme.surface,
                 borderRadius: BorderRadius.circular(4),
                 boxShadow: [
                   BoxShadow(
                     color: colorScheme.primary.withValues(alpha: 0.08),
                     blurRadius: 0,
                     offset: const Offset(0, 2),
                   ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.primary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _result != null ? "SUMMARY" : "NEW NOTE",
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          if (_result != null)
            TextButton(
              onPressed: _resetState,
              child: Text(
                'New',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputView(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageSummarizationInputWithPicker(
            onImageSelected: (file) {
              setState(() {
                _selectedImage = file;
                _errorMessage = null;
              });
            },
            onProcessImage: (File file) => _processImageWithFile(file),
            isProcessing: _isProcessing,
          ),
          
          const SizedBox(height: 16),
          
          VoiceSummarizationInputWithRecorder(
            onProcessAudio: (File file) => _processAudio(file),
            isProcessing: _isProcessing,
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
               color: colorScheme.error.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(4),
                 border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
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

  Widget _buildProcessingView(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  Icon(
                    _getStageIcon(),
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _currentStage?.displayName ?? 'Processing...',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusMessage!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final result = _result!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OceanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(
                         color: colorScheme.primary.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(4),
                       ),
                      child: Icon(
                        result.type == SummaryType.image
                            ? Icons.image
                            : Icons.mic,
                        color: colorScheme.primary,
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
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Processed in ${result.processingTime.inSeconds}s',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                
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
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
               
                if (result.transcript != null) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(
                      'Full Transcript',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      Text(
                        result.transcript!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          if (result.hasAnyEntities) ...[
            const SizedBox(height: 24),
            _buildEntitiesSection(context, result, colorScheme, textTheme),
          ],
          
          const SizedBox(height: 24),
          _buildActionButtons(context, colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildEntitiesSection(BuildContext context, SummarizationPipelineResult result, ColorScheme colorScheme, TextTheme textTheme) {
    return OceanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Entities',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            'Tap to create a reminder',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          
          if (result.hasDateTimeEntities) ...[
             EntitySection(
               title: 'Dates & Times',
               icon: Icons.calendar_today,
               color: AppTheme.primarySkyBlue,
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
          
           if (result.hasLocationEntities)
             EntitySection(
               title: 'Locations',
               icon: Icons.location_on,
               color: AppTheme.accentSandGold,
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

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final hasDateEntity = _selectedDateTimeEntity != null;
    final hasLocationEntity = _selectedLocationEntity != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasDateEntity || hasLocationEntity)
          ReminderTypeSelector(
            hasDateTimeEntities: hasDateEntity,
            hasLocationEntities: hasLocationEntity,
            onCalendarTap: hasDateEntity ? _createCalendarReminder : null,
            onLocationTap: hasLocationEntity ? _showLocationPicker : null,
          ),
        
        const SizedBox(height: 16),
        
        LiquidButton(
          onPressed: _saveSummary,
          backgroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Save Summary',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        OutlinedButton.icon(
          onPressed: () => context.pushNamed('reminders'),
          icon: const Icon(Icons.notifications_outlined),
          label: const Text('View Reminders'),
           style: OutlinedButton.styleFrom(
             foregroundColor: colorScheme.primary,
             side: BorderSide(color: colorScheme.primary),
             padding: const EdgeInsets.symmetric(vertical: 16),
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(4),
             ),
           ),
        ),
      ],
    );
  }

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

  Future<void> _processImageWithFile(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _selectedImage = imageFile;
    });

    try {
      final orchestrator = SummarizationOrchestrator(
        config: SummarizationConfig(
          googleMapsApiKey: envConfig.googleMapsApiKey,
          groqApiKey: envConfig.groqApiKey,
          huggingFaceApiKey: envConfig.huggingFaceApiKey,
          speechProvider: SpeechToTextProvider.whisper,
        ),
      );

      final result = await orchestrator.summarizeImage(
        filePath: imageFile.path,
        userId: context.read<AuthProvider>().userId,
        onProgress: (stage, progress, message) {
          setState(() {
            _currentStage = stage;
            _progress = progress;
            _statusMessage = message;
          });
        },
      );
      
      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _processAudio(File audioFile) async {
    if (audioFile == null) return;
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final orchestrator = SummarizationOrchestrator(
        config: SummarizationConfig(
          googleMapsApiKey: envConfig.googleMapsApiKey,
          groqApiKey: envConfig.groqApiKey,
          huggingFaceApiKey: envConfig.huggingFaceApiKey,
          speechProvider: SpeechToTextProvider.whisper,
        ),
      );

      final result = await orchestrator.summarizeAudio(
        filePath: audioFile.path,
        userId: context.read<AuthProvider>().userId,
        onProgress: (stage, progress, message) {
          setState(() {
            _currentStage = stage;
            _progress = progress;
            _statusMessage = message;
          });
        },
      );
      
      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

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

  Future<void> _createCalendarReminder() async {
    if (_selectedDateTimeEntity == null || _result == null) return;

    final authProvider = context.read<AuthProvider>();
    final reminderProvider = context.read<ReminderProvider>();
    
    if (authProvider.user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        
        return AlertDialog(
          title: Text(
            'Create Calendar Reminder',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a reminder for:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: AppTheme.primarySkyBlue.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(4),
                 ),
                child: Row(
                  children: [
                     const Icon(Icons.calendar_today, color: AppTheme.primarySkyBlue),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, y • h:mm a')
                          .format(_selectedDateTimeEntity!.parsedDateTime),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        );
      },
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
              const Text('Location reminder created'),
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
    if (_result == null) return;

    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) {
        _showError('Please sign in to save');
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      final summaryRepo = SummaryRepository();
      await summaryRepo.createSummary(
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
                const Text('Summary saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.goNamed('home');
      }
    } catch (e) {
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
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
