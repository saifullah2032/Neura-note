import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/reminder_model.dart';
import '../../model/summary_model.dart';

/// A bottom sheet widget for picking/confirming a location for a reminder
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Set Location Reminder',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get reminded when you arrive at this location',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Location Search/Display
              _buildLocationField(),
              const SizedBox(height: 24),

              // Radius Slider
              _buildRadiusSlider(),
              const SizedBox(height: 24),

              // Trigger Type Selection
              _buildTriggerTypeSelection(),
              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedLocation != null ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    'Create Reminder',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
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

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a location...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
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
                      ? Icon(Icons.check_circle, color: Colors.green.shade400)
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: GoogleFonts.poppins(fontSize: 15),
            onSubmitted: _searchLocation,
          ),
        ),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
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
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (_selectedLocation!.address != null)
                        Text(
                          _selectedLocation!.address!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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

  Widget _buildRadiusSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trigger Radius',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_radius.toInt()}m',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.teal,
            inactiveTrackColor: Colors.teal.withOpacity(0.2),
            thumbColor: Colors.teal,
            overlayColor: Colors.teal.withOpacity(0.1),
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
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
            ),
            Text(
              '1km',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTriggerTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trigger When',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTriggerOption(
              GeofenceTriggerType.enter,
              Icons.login,
              'Arriving',
            ),
            const SizedBox(width: 12),
            _buildTriggerOption(
              GeofenceTriggerType.exit,
              Icons.logout,
              'Leaving',
            ),
            const SizedBox(width: 12),
            _buildTriggerOption(
              GeofenceTriggerType.dwell,
              Icons.schedule,
              'Staying',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTriggerOption(GeofenceTriggerType type, IconData icon, String label) {
    final isSelected = _triggerType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _triggerType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.teal : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.teal : Colors.grey.shade400,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.teal : Colors.grey.shade600,
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

    // TODO: Implement actual geocoding using GeocodingService
    // For now, use the initial entity if available
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
      // Mock location for demo
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

/// A compact reminder type selector for quick creation
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
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
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
