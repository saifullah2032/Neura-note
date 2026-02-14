import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../model/summary_model.dart';

/// A chip widget that displays an extracted entity (date/time or location)
class EntityChip extends StatelessWidget {
  final bool isDateTime;
  final DateTimeEntity? dateTimeEntity;
  final LocationEntity? locationEntity;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showAddIcon;

  const EntityChip.dateTime({
    super.key,
    required DateTimeEntity entity,
    this.onTap,
    this.isSelected = false,
    this.showAddIcon = true,
  })  : isDateTime = true,
        dateTimeEntity = entity,
        locationEntity = null;

  const EntityChip.location({
    super.key,
    required LocationEntity entity,
    this.onTap,
    this.isSelected = false,
    this.showAddIcon = true,
  })  : isDateTime = false,
        dateTimeEntity = null,
        locationEntity = entity;

  @override
  Widget build(BuildContext context) {
    final color = isDateTime ? Colors.blue : Colors.orange;
    final icon = isDateTime ? Icons.calendar_today : Icons.location_on;
    final label = _getLabel();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: color, width: 1.5)
                : Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDateTime ? Colors.blue.shade700 : Colors.orange.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showAddIcon && onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  size: 18,
                  color: color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getLabel() {
    if (isDateTime && dateTimeEntity != null) {
      final dt = dateTimeEntity!.parsedDateTime;
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final dateOnly = DateTime(dt.year, dt.month, dt.day);

      if (dateOnly == DateTime(now.year, now.month, now.day)) {
        return 'Today ${DateFormat.jm().format(dt)}';
      } else if (dateOnly == tomorrow) {
        return 'Tomorrow ${DateFormat.jm().format(dt)}';
      } else {
        return DateFormat('MMM d, h:mm a').format(dt);
      }
    } else if (!isDateTime && locationEntity != null) {
      return locationEntity!.resolvedAddress ?? locationEntity!.originalText;
    }
    return '';
  }
}

/// A section widget that displays extracted entities with a header
class EntitySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const EntitySection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}

/// Widget that highlights text entities within a paragraph
class HighlightedText extends StatelessWidget {
  final String text;
  final List<DateTimeEntity> dateTimeEntities;
  final List<LocationEntity> locationEntities;
  final TextStyle? baseStyle;
  final Function(DateTimeEntity)? onDateTimeTap;
  final Function(LocationEntity)? onLocationTap;

  const HighlightedText({
    super.key,
    required this.text,
    this.dateTimeEntities = const [],
    this.locationEntities = const [],
    this.baseStyle,
    this.onDateTimeTap,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ??
        GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.grey.shade800,
          height: 1.6,
        );

    // Build spans with highlights
    final spans = _buildSpans(style);

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _buildSpans(TextStyle baseStyle) {
    final List<_HighlightRange> ranges = [];

    // Collect all entity ranges
    for (final entity in dateTimeEntities) {
      final index = text.toLowerCase().indexOf(entity.originalText.toLowerCase());
      if (index != -1) {
        ranges.add(_HighlightRange(
          start: index,
          end: index + entity.originalText.length,
          type: _HighlightType.dateTime,
          dateTimeEntity: entity,
        ));
      }
    }

    for (final entity in locationEntities) {
      final index = text.toLowerCase().indexOf(entity.originalText.toLowerCase());
      if (index != -1) {
        ranges.add(_HighlightRange(
          start: index,
          end: index + entity.originalText.length,
          type: _HighlightType.location,
          locationEntity: entity,
        ));
      }
    }

    // Sort by start position
    ranges.sort((a, b) => a.start.compareTo(b.start));

    // Remove overlapping ranges
    final cleanedRanges = <_HighlightRange>[];
    for (final range in ranges) {
      if (cleanedRanges.isEmpty || range.start >= cleanedRanges.last.end) {
        cleanedRanges.add(range);
      }
    }

    // Build spans
    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (final range in cleanedRanges) {
      // Add normal text before this range
      if (range.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, range.start),
          style: baseStyle,
        ));
      }

      // Add highlighted text
      final highlightedText = text.substring(range.start, range.end);
      final color = range.type == _HighlightType.dateTime ? Colors.blue : Colors.orange;

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () {
            if (range.type == _HighlightType.dateTime && onDateTimeTap != null) {
              onDateTimeTap!(range.dateTimeEntity!);
            } else if (range.type == _HighlightType.location && onLocationTap != null) {
              onLocationTap!(range.locationEntity!);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  range.type == _HighlightType.dateTime
                      ? Icons.calendar_today
                      : Icons.location_on,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  highlightedText,
                  style: baseStyle.copyWith(
                    color: range.type == _HighlightType.dateTime
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      currentIndex = range.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

enum _HighlightType { dateTime, location }

class _HighlightRange {
  final int start;
  final int end;
  final _HighlightType type;
  final DateTimeEntity? dateTimeEntity;
  final LocationEntity? locationEntity;

  _HighlightRange({
    required this.start,
    required this.end,
    required this.type,
    this.dateTimeEntity,
    this.locationEntity,
  });
}
