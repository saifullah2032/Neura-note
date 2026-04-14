import 'package:flutter/material.dart';
import '../../../core/themes.dart';
import '../../../core/fluid_components.dart';
import '../../../model/summary_model.dart';

class SummaryCard extends StatelessWidget {
  final SummaryModel summary;
  final VoidCallback onTap;

  const SummaryCard({
    super.key, 
    required this.summary, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isImage = summary.type == SummaryType.image;

    return RepaintBoundary(
      child: Hero(
        tag: 'summary_${summary.id}',
        child: OceanCard(
          onTap: onTap,
          padding: EdgeInsets.zero,
          blurSigma: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/Audio Preview Area
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: isImage
                      ? _buildImagePreview(colorScheme)
                      : _buildAudioPreview(colorScheme),
                ),
              ),
              
              // Content Area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Label
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isImage ? Icons.image_outlined : Icons.mic_outlined,
                              size: 10,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isImage ? 'Image' : 'Voice',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          _buildConfidenceIndicator(colorScheme),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Summary Text
                      Expanded(
                        child: Text(
                          summary.summarizedText.length > 60
                              ? '${summary.summarizedText.substring(0, 60)}...'
                              : summary.summarizedText,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 9,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(summary.createdAt),
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 8,
                              color: colorScheme.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    if (summary.thumbnailUrl != null && summary.thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Image.network(
          summary.thumbnailUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(colorScheme),
        ),
      );
    }
    return _buildPlaceholderIcon(colorScheme);
  }

  Widget _buildPlaceholderIcon(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined, 
            size: 36, 
            color: colorScheme.primary.withValues(alpha: 0.3)
          ),
          const SizedBox(height: 4),
          Text(
            'No preview',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 10,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic, size: 22, color: colorScheme.primary),
          ),
          const SizedBox(height: 4),
          if (summary.rawTranscript != null && summary.rawTranscript!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(summary.rawTranscript!.length),
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 9,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(ColorScheme colorScheme) {
    final confidence = summary.confidenceScore ?? 0.0;
    Color color;
    String label;

    if (confidence >= 0.8) {
      color = AppTheme.success;
      label = 'High';
    } else if (confidence >= 0.5) {
      color = AppTheme.warning;
      label = 'Med';
    } else {
      color = colorScheme.outline;
      label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
