import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuranotteai/model/summary_model.dart';

class SummaryCard extends StatelessWidget {
  final SummaryModel summary;
  final VoidCallback onTap;

  const SummaryCard({super.key, required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final teal = Colors.teal;
    final isImage = summary.type == SummaryType.image;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: teal.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: teal.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image or Audio icon area
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9F8),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: isImage
                      ? _buildImagePreview()
                      : _buildAudioPreview(teal),
                ),
              ),
              // Content area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type label with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isImage
                                  ? Icons.image_outlined
                                  : Icons.mic_outlined,
                              size: 12,
                              color: teal,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isImage ? 'Image' : 'Voice',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: teal,
                            ),
                          ),
                          const Spacer(),
                          _buildConfidenceIndicator(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Summary text preview
                      Expanded(
                        child: Text(
                          summary.summarizedText.length > 80
                              ? '${summary.summarizedText.substring(0, 80)}...'
                              : summary.summarizedText,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Date
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 10,
                            color: Colors.black26,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(summary.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.black26,
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

  Widget _buildImagePreview() {
    if (summary.thumbnailUrl != null && summary.thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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
                color: Colors.teal,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
        ),
      );
    }
    return _buildPlaceholderIcon();
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 36, color: Colors.teal.shade200),
          const SizedBox(height: 4),
          Text(
            'No preview',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.teal.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(Color teal) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic, size: 28, color: teal),
          ),
          const SizedBox(height: 8),
          if (summary.rawTranscript != null &&
              summary.rawTranscript!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDuration(summary.rawTranscript!.length),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final confidence = summary.confidenceScore ?? 0.0;
    Color color;
    String label;

    if (confidence >= 0.8) {
      color = Colors.green;
      label = 'High';
    } else if (confidence >= 0.5) {
      color = Colors.orange;
      label = 'Med';
    } else {
      color = Colors.grey;
      label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
            style: GoogleFonts.poppins(
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
