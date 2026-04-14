import 'package:flutter/material.dart';

import '../../model/reminder_model.dart';
import '../../model/summary_model.dart';

class LocationPickerSheet extends StatefulWidget {
  final LocationEntity? initialEntity;
  final Function(GeoLocation location, double radius, GeofenceTriggerType trigger) onConfirm;

  const LocationPickerSheet({
    super.key,
    this.initialEntity,
    required this.onConfirm,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late TextEditingController _searchController;
  double _radius = 200;
  GeofenceTriggerType _triggerType = GeofenceTriggerType.enter;
  GeoLocation? _selectedLocation;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.initialEntity?.resolvedAddress ?? widget.initialEntity?.originalText ?? '',
    );
    if (widget.initialEntity?.hasCoordinates == true) {
      _selectedLocation = GeoLocation(
        latitude: widget.initialEntity!.latitude!,
        longitude: widget.initialEntity!.longitude!,
        address: widget.initialEntity!.resolvedAddress,
        placeName: widget.initialEntity!.originalText,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Set Location Reminder',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get reminded when you arrive at this location',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              _buildLocationField(colorScheme, textTheme),
              const SizedBox(height: 24),

              _buildRadiusSlider(colorScheme, textTheme),
              const SizedBox(height: 24),

              _buildTriggerTypeSelection(colorScheme, textTheme),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedLocation != null ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    'Create Reminder',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a location...',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(Icons.location_on, color: Colors.orange.shade400),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _selectedLocation != null
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: textTheme.bodyMedium,
            onSubmitted: _searchLocation,
          ),
        ),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLocation!.placeName ?? 'Selected Location',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (_selectedLocation!.address != null)
                        Text(
                          _selectedLocation!.address!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadiusSlider(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trigger Radius',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_radius.toInt()}m',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.1),
            trackHeight: 6,
          ),
          child: Slider(
            value: _radius,
            min: 50,
            max: 1000,
            divisions: 19,
            onChanged: (value) {
              setState(() => _radius = value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '50m',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '1km',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTriggerTypeSelection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trigger When',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTriggerOption(
              GeofenceTriggerType.enter,
              Icons.login,
              'Arriving',
              colorScheme,
            ),
            const SizedBox(width: 12),
            _buildTriggerOption(
              GeofenceTriggerType.exit,
              Icons.logout,
              'Leaving',
              colorScheme,
            ),
            const SizedBox(width: 12),
            _buildTriggerOption(
              GeofenceTriggerType.dwell,
              Icons.schedule,
              'Staying',
              colorScheme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTriggerOption(GeofenceTriggerType type, IconData icon, String label, ColorScheme colorScheme) {
    final isSelected = _triggerType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _triggerType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (widget.initialEntity?.hasCoordinates == true) {
      setState(() {
        _selectedLocation = GeoLocation(
          latitude: widget.initialEntity!.latitude!,
          longitude: widget.initialEntity!.longitude!,
          address: widget.initialEntity!.resolvedAddress ?? query,
          placeName: widget.initialEntity!.originalText,
        );
        _isSearching = false;
      });
    } else {
      setState(() {
        _selectedLocation = GeoLocation(
          latitude: 37.7749,
          longitude: -122.4194,
          address: query,
          placeName: query,
        );
        _isSearching = false;
      });
    }
  }

  void _onConfirm() {
    if (_selectedLocation != null) {
      widget.onConfirm(_selectedLocation!, _radius, _triggerType);
      Navigator.pop(context);
    }
  }
}

class ReminderTypeSelector extends StatelessWidget {
  final bool hasDateTimeEntities;
  final bool hasLocationEntities;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onLocationTap;

  const ReminderTypeSelector({
    super.key,
    this.hasDateTimeEntities = false,
    this.hasLocationEntities = false,
    this.onCalendarTap,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hasDateTimeEntities)
          Expanded(
            child: _buildOption(
              icon: Icons.calendar_today,
              label: 'Calendar',
              color: Colors.blue,
              onTap: onCalendarTap,
            ),
          ),
        if (hasDateTimeEntities && hasLocationEntities)
          const SizedBox(width: 12),
        if (hasLocationEntities)
          Expanded(
            child: _buildOption(
              icon: Icons.location_on,
              label: 'Location',
              color: Colors.orange,
              onTap: onLocationTap,
            ),
          ),
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
