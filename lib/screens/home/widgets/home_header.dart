import 'package:flutter/material.dart';

import '../../../core/themes.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onRemindersTap;
  final VoidCallback onRefreshTap;
  final VoidCallback onProfileTap;
  final int activeRemindersCount;

  const HomeHeader({
    super.key,
    required this.onRemindersTap,
    required this.onRefreshTap,
    required this.onProfileTap,
    this.activeRemindersCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeHeaderDelegate(
        onRemindersTap: onRemindersTap,
        onRefreshTap: onRefreshTap,
        onProfileTap: onProfileTap,
        activeRemindersCount: activeRemindersCount,
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onRemindersTap;
  final VoidCallback onRefreshTap;
  final VoidCallback onProfileTap;
  final int activeRemindersCount;

  _HomeHeaderDelegate({
    required this.onRemindersTap,
    required this.onRefreshTap,
    required this.onProfileTap,
    required this.activeRemindersCount,
  });

  @override
  double get minExtent => 60.0;

  @override
  double get maxExtent => 100.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double expandedHeight = 100.0 + topPadding;
    
    final progress = shrinkOffset / expandedHeight;
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    final titleSize = 20.0 - (clampedProgress * 5);
    final iconSize = 20.0 - (clampedProgress * 4);
    final horizontalPadding = 16.0 - (clampedProgress * 8);
    
    return RepaintBoundary(
      child: Material(
        color: AppTheme.backgroundBeachSand,
        child: SizedBox(
          height: maxExtent,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundBeachSand,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.divider.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: topPadding + 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6 + (clampedProgress * 2)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryOceanTeal, AppTheme.glassSoftTeal],
                    ),
                    borderRadius: BorderRadius.circular(10 - (clampedProgress * 4)),
                  ),
                  child: Icon(
                    Icons.waves,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "NEURANOTE",
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      color: AppTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ),
                _HeaderIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: onRemindersTap,
                  badgeCount: activeRemindersCount,
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  icon: Icons.refresh,
                  onTap: onRefreshTap,
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  icon: Icons.person_outline,
                  onTap: onProfileTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.activeRemindersCount != activeRemindersCount;
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOceanTeal.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: AppTheme.primaryOceanTeal, size: 22),
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.actionCoral,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      badgeCount > 9 ? '9+' : badgeCount.toString(),
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
