import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/themes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/summary_provider.dart';
import '../widgets/ocean_animations.dart';
import 'widgets/summary_card.dart';
import 'widgets/home_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showGalleryPanel = false;
  bool _showVoicePanel = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummaries();
    });
  }

  void _loadSummaries() {
    final authProvider = context.read<AuthProvider>();
    final summaryProvider = context.read<SummaryProvider>();
    
    if (authProvider.userId != null) {
      summaryProvider.loadSummaries(authProvider.userId!);
    }
  }

  Future<void> _refreshSummaries() async {
    final authProvider = context.read<AuthProvider>();
    final summaryProvider = context.read<SummaryProvider>();
    
    if (authProvider.userId != null) {
      await summaryProvider.loadSummaries(authProvider.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeachSand,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenWidth < 380;
          
          return Stack(
            children: [
              Positioned.fill(
                child: OceanBackground(
                  primaryColor: AppTheme.primaryOceanTeal,
                  waveHeight: isSmallScreen ? 50 : 70,
                  showBubbles: true,
                ),
              ),
              
              // Content
              _buildContent(context, isSmallScreen),
              
              // Floating Bottom Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: FloatingBottomBar(
                  isGalleryActive: _showGalleryPanel,
                  isVoiceActive: _showVoicePanel,
                  onImageTap: () {
                    setState(() {
                      _showGalleryPanel = !_showGalleryPanel;
                      _showVoicePanel = false;
                    });
                  },
                  onVoiceTap: () {
                    setState(() {
                      _showVoicePanel = !_showVoicePanel;
                      _showGalleryPanel = false;
                    });
                  },
                  onAddTap: () => context.pushNamed('summarize'),
                ),
              ),
              
              // Panels
              if (_showGalleryPanel) _buildGalleryPanel(context),
              if (_showVoicePanel) _buildVoicePanel(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<SummaryProvider>(
      builder: (context, summaryProvider, _) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Sliver Header with shrink behavior
            HomeHeader(
              onRemindersTap: () => context.pushNamed('reminders'),
              onRefreshTap: _refreshSummaries,
              onProfileTap: () => context.pushNamed('profile'),
              activeRemindersCount: 
                  context.watch<ReminderProvider>().activeReminders.length,
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            
            // Content
            if (summaryProvider.isLoading)
              SliverFillRemaining(
                child: _buildLoadingState(colorScheme, textTheme),
              )
            else if (summaryProvider.summaries.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(context, colorScheme, textTheme, isSmallScreen),
              )
            else
              _buildSummaryGrid(summaryProvider, isSmallScreen),
            
            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryGrid(SummaryProvider summaryProvider, bool isSmallScreen) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isSmallScreen ? 2 : 3,
          mainAxisSpacing: isSmallScreen ? 8 : 16,
          crossAxisSpacing: isSmallScreen ? 8 : 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final summary = summaryProvider.summaries[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: value.clamp(0.8, 1.0),
                    child: child,
                  ),
                );
              },
              child: SummaryCard(
                summary: summary,
                onTap: () {
                  summaryProvider.setCurrentSummary(summary);
                  context.pushNamed('summary');
                },
              ),
            );
          },
          childCount: summaryProvider.summaries.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppTheme.primaryOceanTeal,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your notes...',
            style: textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, bool isSmallScreen) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 24 : 28),
                decoration: BoxDecoration(
                  color: AppTheme.glassSoftTeal.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.note_add_outlined,
                  size: isSmallScreen ? 48 : 56,
                  color: AppTheme.primaryOceanTeal.withValues(alpha: 0.6),
                ),
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 16 : 24),
            
            Text(
              'Start Your Journey',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Tap the + button to create your first note',
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isSmallScreen ? 24 : 32),
            
            // Feature Hints
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FeatureHint(icon: Icons.image, label: 'Image'),
                SizedBox(width: isSmallScreen ? 8 : 16),
                _FeatureHint(icon: Icons.mic, label: 'Voice'),
                SizedBox(width: isSmallScreen ? 8 : 16),
                _FeatureHint(icon: Icons.notifications, label: 'Remind'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryPanel(BuildContext context) {
    return _ExpandablePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, color: AppTheme.primaryOceanTeal, size: 18),
              const SizedBox(width: 8),
              Text(
                'Add from Image',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _showGalleryPanel = false);
                      context.pushNamed('summarize');
                    },
                    icon: const Icon(Icons.photo_library, size: 16),
                    label: const Text('Gallery'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _showGalleryPanel = false);
                      context.pushNamed('summarize');
                    },
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Camera'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showGalleryPanel = false),
            child: Text(
              "Cancel",
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePanel(BuildContext context) {
    return _ExpandablePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: AppTheme.primaryOceanTeal, size: 18),
              const SizedBox(width: 8),
              Text(
                'Voice Recording',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryOceanTeal.withValues(alpha: 0.1),
                  AppTheme.primaryOceanTeal.withValues(alpha: 0.03),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.graphic_eq, color: AppTheme.primaryOceanTeal, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            "Tap to start recording",
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(() => _showVoicePanel = false),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _showVoicePanel = false);
                    context.pushNamed('summarize');
                  },
                  child: const Text("Start Recording"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOceanTeal.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.primaryOceanTeal, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ExpandablePanel extends StatelessWidget {
  final Widget child;

  const _ExpandablePanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 90,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class FloatingBottomBar extends StatelessWidget {
  final bool isGalleryActive;
  final bool isVoiceActive;
  final VoidCallback onImageTap;
  final VoidCallback onVoiceTap;
  final VoidCallback onAddTap;

  const FloatingBottomBar({
    super.key,
    required this.isGalleryActive,
    required this.isVoiceActive,
    required this.onImageTap,
    required this.onVoiceTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primarySkyBlue,
        border: Border.all(color: Colors.black, width: 3.0),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: const Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Navigation bar content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomBarButton(
                  icon: Icons.image_outlined,
                  isActive: isGalleryActive,
                  onTap: onImageTap,
                ),
                _BottomBarButton(
                  icon: Icons.mic_none,
                  isActive: isVoiceActive,
                  onTap: onVoiceTap,
                ),
                SizedBox(width: 56), // Space for FAB
              ],
            ),
          ),
          // Neo-Brutalist FAB
          Positioned(
            bottom: 8,
            child: _WaveNotchFAB(onTap: onAddTap),
          ),
        ],
      ),
    );
  }
}

class _WaveNotchFAB extends StatelessWidget {
  final VoidCallback onTap;

  const _WaveNotchFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.accentSandGold,
          border: Border.all(color: Colors.black, width: 3.0),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomBarButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_BottomBarButton> createState() => _BottomBarButtonState();
}

class _BottomBarButtonState extends State<_BottomBarButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isActive 
                    ? AppTheme.primarySkyBlue
                    : Colors.transparent,
                border: widget.isActive
                    ? Border.all(color: Colors.black, width: 2.0)
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                widget.icon,
                color: widget.isActive ? Colors.black : AppTheme.primarySkyBlue,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
