import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/summary_model.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: color, width: 1.5)
                : Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    final style = baseStyle ??
        TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 15,
          color: colorScheme.onSurface,
          height: 1.6,
        );

    final spans = _buildSpans(style);

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _buildSpans(TextStyle baseStyle) {
    final List<_HighlightRange> ranges = [];

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

    ranges.sort((a, b) => a.start.compareTo(b.start));

    final cleanedRanges = <_HighlightRange>[];
    for (final range in ranges) {
      if (cleanedRanges.isEmpty || range.start >= cleanedRanges.last.end) {
        cleanedRanges.add(range);
      }
    }

    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (final range in cleanedRanges) {
      if (range.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, range.start),
          style: baseStyle,
        ));
      }

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
              color: color.withValues(alpha: 0.12),
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
