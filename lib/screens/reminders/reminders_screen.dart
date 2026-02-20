import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../model/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/ocean_animations.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final Color _offWhite = const Color(0xFFF8F9FA);
  final Color _teal = Colors.teal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReminders() {
    final authProvider = context.read<AuthProvider>();
    final reminderProvider = context.read<ReminderProvider>();
    
    if (authProvider.user != null) {
      reminderProvider.loadReminders(authProvider.user!.uid);
    }
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
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
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
            "REMINDERS",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Consumer<ReminderProvider>(
            builder: (context, provider, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.activeReminders.length} active',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.teal.shade600,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Calendar'),
          Tab(text: 'Location'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: _teal),
          );
        }

        if (provider.state == ReminderState.error) {
          return _buildErrorState(provider.errorMessage ?? 'An error occurred');
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildRemindersList(provider.reminders),
            _buildRemindersList(provider.calendarReminders),
            _buildRemindersList(provider.locationReminders),
          ],
        );
      },
    );
  }

  Widget _buildRemindersList(List<ReminderModel> reminders) {
    if (reminders.isEmpty) {
      return _buildEmptyState();
    }

    // Group reminders by status
    final activeReminders = reminders.where((r) => r.isActive).toList();
    final completedReminders = reminders.where(
      (r) => r.status == ReminderStatus.completed || 
             r.status == ReminderStatus.triggered
    ).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (activeReminders.isNotEmpty) ...[
          _buildSectionHeader('Active', activeReminders.length),
          const SizedBox(height: 12),
          ...activeReminders.map((r) => _ReminderCard(
            reminder: r,
            onTap: () => _showReminderDetails(r),
            onComplete: () => _completeReminder(r.id),
            onDismiss: () => _dismissReminder(r.id),
          )),
        ],
        if (completedReminders.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader('Completed', completedReminders.length),
          const SizedBox(height: 12),
          ...completedReminders.map((r) => _ReminderCard(
            reminder: r,
            onTap: () => _showReminderDetails(r),
            onDelete: () => _deleteReminder(r.id),
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.teal.shade800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
            child: Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: _teal.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create summaries to detect\ndates and locations for reminders',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadReminders,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.pushNamed('summarize'),
      backgroundColor: _teal,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'New Summary',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showReminderDetails(ReminderModel reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderDetailSheet(reminder: reminder),
    );
  }

  Future<void> _completeReminder(String reminderId) async {
    final provider = context.read<ReminderProvider>();
    await provider.markAsCompleted(reminderId);
  }

  Future<void> _dismissReminder(String reminderId) async {
    final provider = context.read<ReminderProvider>();
    await provider.markAsDismissed(reminderId);
  }

  Future<void> _deleteReminder(String reminderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Reminder',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this reminder?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: _teal)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<ReminderProvider>();
      await provider.deleteReminder(reminderId);
    }
  }
}

/// Reminder Card Widget
class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    this.onComplete,
    this.onDismiss,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCalendar = reminder.isCalendarReminder;
    final teal = Colors.teal;
    final isActive = reminder.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isCalendar ? Colors.blue : Colors.orange)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCalendar ? Icons.calendar_today : Icons.location_on,
                        color: isCalendar ? Colors.blue : Colors.orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                              decoration: isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getSubtitle(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),
                if (isActive && (onComplete != null || onDismiss != null)) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onDismiss != null)
                        TextButton(
                          onPressed: onDismiss,
                          child: Text(
                            'Dismiss',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (onComplete != null)
                        ElevatedButton(
                          onPressed: onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Complete',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (!isActive && onDelete != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                      tooltip: 'Delete',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    if (reminder.isCalendarReminder && reminder.scheduledDateTime != null) {
      return DateFormat('MMM d, y • h:mm a').format(reminder.scheduledDateTime!);
    } else if (reminder.isLocationReminder && reminder.targetLocation != null) {
      return reminder.targetLocation!.displayName;
    }
    return reminder.description;
  }

  Widget _buildStatusChip() {
    Color bgColor;
    Color textColor;
    String label;

    switch (reminder.status) {
      case ReminderStatus.pending:
        bgColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal;
        label = 'Active';
        break;
      case ReminderStatus.triggered:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Triggered';
        break;
      case ReminderStatus.completed:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Done';
        break;
      case ReminderStatus.dismissed:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = 'Dismissed';
        break;
      case ReminderStatus.expired:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'Expired';
        break;
      case ReminderStatus.cancelled:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Reminder Detail Bottom Sheet
class _ReminderDetailSheet extends StatelessWidget {
  final ReminderModel reminder;

  const _ReminderDetailSheet({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
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
                  const SizedBox(height: 24),
                  // Type indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (reminder.isCalendarReminder
                                  ? Colors.blue
                                  : Colors.orange)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          reminder.isCalendarReminder
                              ? Icons.calendar_today
                              : Icons.location_on,
                          color: reminder.isCalendarReminder
                              ? Colors.blue
                              : Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.isCalendarReminder
                                  ? 'Calendar Reminder'
                                  : 'Location Reminder',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              reminder.title,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  _buildDetailRow(
                    Icons.description_outlined,
                    'Description',
                    reminder.description,
                  ),
                  const SizedBox(height: 16),
                  // Date/Time or Location
                  if (reminder.isCalendarReminder &&
                      reminder.scheduledDateTime != null)
                    _buildDetailRow(
                      Icons.access_time,
                      'Scheduled',
                      DateFormat('EEEE, MMMM d, y\nh:mm a')
                          .format(reminder.scheduledDateTime!),
                    ),
                  if (reminder.isLocationReminder &&
                      reminder.targetLocation != null) ...[
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'Location',
                      reminder.targetLocation!.displayName,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.radar,
                      'Radius',
                      '${reminder.radiusInMeters.toInt()} meters',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.notifications_active_outlined,
                      'Trigger',
                      _getTriggerTypeLabel(reminder.triggerType),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Status
                  _buildDetailRow(
                    Icons.info_outline,
                    'Status',
                    _getStatusLabel(reminder.status),
                  ),
                  const SizedBox(height: 16),
                  // Created at
                  _buildDetailRow(
                    Icons.schedule_outlined,
                    'Created',
                    DateFormat('MMM d, y • h:mm a').format(reminder.createdAt),
                  ),
                  if (reminder.triggeredAt != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.notifications_outlined,
                      'Triggered',
                      DateFormat('MMM d, y • h:mm a')
                          .format(reminder.triggeredAt!),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTriggerTypeLabel(GeofenceTriggerType type) {
    switch (type) {
      case GeofenceTriggerType.enter:
        return 'When entering the area';
      case GeofenceTriggerType.exit:
        return 'When leaving the area';
      case GeofenceTriggerType.dwell:
        return 'When staying in the area';
    }
  }

  String _getStatusLabel(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.pending:
        return 'Active and waiting';
      case ReminderStatus.triggered:
        return 'Notification sent';
      case ReminderStatus.completed:
        return 'Marked as done';
      case ReminderStatus.dismissed:
        return 'Dismissed by user';
      case ReminderStatus.expired:
        return 'Time has passed';
      case ReminderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
