import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/themes.dart';
import '../../core/fluid_components.dart';
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
              _buildTabBar(colorScheme, textTheme),
              Expanded(child: _buildTabContent(colorScheme, textTheme)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(colorScheme, textTheme),
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
              child: Icon(Icons.arrow_back, color: colorScheme.primary, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "REMINDERS",
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Consumer<ReminderProvider>(
            builder: (context, provider, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                   color: colorScheme.primary.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(4),
                 ),
                child: Text(
                  '${provider.activeReminders.length} active',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
       decoration: BoxDecoration(
         color: colorScheme.surface,
         borderRadius: BorderRadius.circular(4),
         boxShadow: [
           BoxShadow(
             color: colorScheme.primary.withValues(alpha: 0.05),
             blurRadius: 0,
             offset: const Offset(0, 2),
           ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
         indicator: BoxDecoration(
           color: colorScheme.primary,
           borderRadius: BorderRadius.circular(4),
         ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.primary,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
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

  Widget _buildTabContent(ColorScheme colorScheme, TextTheme textTheme) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        if (provider.state == ReminderState.error) {
          return _buildErrorState(provider.errorMessage ?? 'An error occurred', colorScheme, textTheme);
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildRemindersList(provider.reminders, colorScheme, textTheme),
            _buildRemindersList(provider.calendarReminders, colorScheme, textTheme),
            _buildRemindersList(provider.locationReminders, colorScheme, textTheme),
          ],
        );
      },
    );
  }

  Widget _buildRemindersList(List<ReminderModel> reminders, ColorScheme colorScheme, TextTheme textTheme) {
    if (reminders.isEmpty) {
      return _buildEmptyState(colorScheme, textTheme);
    }

    final activeReminders = reminders.where((r) => r.isActive).toList();
    final completedReminders = reminders.where(
      (r) => r.status == ReminderStatus.completed || 
             r.status == ReminderStatus.triggered
    ).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (activeReminders.isNotEmpty) ...[
          _buildSectionHeader('Active', activeReminders.length, colorScheme, textTheme),
          const SizedBox(height: 12),
          ...activeReminders.map((r) => _ReminderCard(
            reminder: r,
            colorScheme: colorScheme,
            textTheme: textTheme,
            onTap: () => _showReminderDetails(r, colorScheme, textTheme),
            onComplete: () => _completeReminder(r.id),
            onDismiss: () => _dismissReminder(r.id),
          )),
        ],
        if (completedReminders.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader('Completed', completedReminders.length, colorScheme, textTheme),
          const SizedBox(height: 12),
          ...completedReminders.map((r) => _ReminderCard(
            reminder: r,
            colorScheme: colorScheme,
            textTheme: textTheme,
            onTap: () => _showReminderDetails(r, colorScheme, textTheme),
            onDelete: () => _deleteReminder(r.id),
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
         decoration: BoxDecoration(
             color: colorScheme.primary.withValues(alpha: 0.1),
             borderRadius: BorderRadius.circular(4),
           ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders yet',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create summaries to detect\ndates and locations for reminders',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: colorScheme.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          LiquidButton(
            onPressed: _loadReminders,
            backgroundColor: colorScheme.primary,
            child: Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(ColorScheme colorScheme, TextTheme textTheme) {
    return FloatingActionButton.extended(
      onPressed: () => context.pushNamed('summarize'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      icon: const Icon(Icons.add),
      label: Text(
        'New',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showReminderDetails(ReminderModel reminder, ColorScheme colorScheme, TextTheme textTheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderDetailSheet(
        reminder: reminder, 
        colorScheme: colorScheme, 
        textTheme: textTheme
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Reminder',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this reminder?',
          style: textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: Text('Delete'),
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

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
    this.onComplete,
    this.onDismiss,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCalendar = reminder.isCalendarReminder;
    final isActive = reminder.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: OceanCard(
        onTap: onTap,
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
                         .withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(4),
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
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          decoration: isActive ? null : TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSubtitle(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(colorScheme),
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
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (onComplete != null)
                    LiquidButton(
                      onPressed: onComplete,
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Complete',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
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
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  tooltip: 'Delete',
                ),
              ),
            ],
          ],
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

  Widget _buildStatusChip(ColorScheme colorScheme) {
    Color bgColor;
    Color textColor;
    String label;

    switch (reminder.status) {
      case ReminderStatus.pending:
        bgColor = colorScheme.primary.withValues(alpha: 0.1);
        textColor = colorScheme.primary;
        label = 'Active';
      case ReminderStatus.triggered:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        label = 'Triggered';
      case ReminderStatus.completed:
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        label = 'Done';
      case ReminderStatus.dismissed:
        bgColor = colorScheme.outline.withValues(alpha: 0.1);
        textColor = colorScheme.outline;
        label = 'Dismissed';
      case ReminderStatus.expired:
        bgColor = colorScheme.error.withValues(alpha: 0.1);
        textColor = colorScheme.error;
        label = 'Expired';
      case ReminderStatus.cancelled:
        bgColor = colorScheme.outline.withValues(alpha: 0.1);
        textColor = colorScheme.outline;
        label = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
       decoration: BoxDecoration(
         color: bgColor,
         borderRadius: BorderRadius.circular(4),
       ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _ReminderDetailSheet extends StatelessWidget {
  final ReminderModel reminder;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ReminderDetailSheet({
    required this.reminder,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: (reminder.isCalendarReminder
                                   ? Colors.blue
                                   : Colors.orange)
                               .withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(4),
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
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              reminder.title,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    Icons.description_outlined,
                    'Description',
                    reminder.description,
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  if (reminder.isCalendarReminder && reminder.scheduledDateTime != null)
                    _buildDetailRow(
                      Icons.access_time,
                      'Scheduled',
                      DateFormat('EEEE, MMMM d, y\nh:mm a')
                          .format(reminder.scheduledDateTime!),
                      colorScheme,
                      textTheme,
                    ),
                  if (reminder.isLocationReminder && reminder.targetLocation != null) ...[
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'Location',
                      reminder.targetLocation!.displayName,
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.radar,
                      'Radius',
                      '${reminder.radiusInMeters.toInt()} meters',
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.notifications_active_outlined,
                      'Trigger',
                      _getTriggerTypeLabel(reminder.triggerType),
                      colorScheme,
                      textTheme,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.info_outline,
                    'Status',
                    _getStatusLabel(reminder.status),
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.schedule_outlined,
                    'Created',
                    DateFormat('MMM d, y • h:mm a').format(reminder.createdAt),
                    colorScheme,
                    textTheme,
                  ),
                  if (reminder.triggeredAt != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.notifications_outlined,
                      'Triggered',
                      DateFormat('MMM d, y • h:mm a')
                          .format(reminder.triggeredAt!),
                      colorScheme,
                      textTheme,
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

  Widget _buildDetailRow(IconData icon, String label, String value, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
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
