import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../model/summary_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/summary_provider.dart';
import 'widgets/summary_card.dart';
import '../widgets/ocean_animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/summary_provider.dart';
import 'widgets/summary_card.dart';
import '../widgets/ocean_animations.dart';
import '../../model/summary_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  bool _showGalleryPanel = false;
  bool _showVoicePanel = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    );
    _fabController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummaries();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadSummaries();
      }
    });
  }

  void _loadSummaries() {
    final authProvider = context.read<AuthProvider>();
    final summaryProvider = context.read<SummaryProvider>();
    debugPrint('=== HOME SCREEN: Loading summaries for user: ${authProvider.userId}');
    if (authProvider.userId != null) {
      summaryProvider.loadSummaries(authProvider.userId!);
    } else {
      debugPrint('=== HOME SCREEN: No user ID found!');
    }
  }

  Future<void> _refreshSummaries() async {
    final authProvider = context.read<AuthProvider>();
    final summaryProvider = context.read<SummaryProvider>();
    debugPrint('Refreshing summaries for user: ${authProvider.userId}');
    if (authProvider.userId != null) {
      await summaryProvider.loadSummaries(authProvider.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offWhite = const Color(0xFFF8F9FA);
    final teal = Colors.teal;

    return Scaffold(
      backgroundColor: offWhite,
      body: OceanBackground(
        primaryColor: teal,
        waveHeight: 100,
        showBubbles: true,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: _buildHeader(teal)),
                        Row(
                          children: [
                            _buildRemindersButton(teal),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.refresh,
                              teal: teal,
                              onTap: _refreshSummaries,
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.person_outline,
                              teal: teal,
                              onTap: () => context.pushNamed('profile'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Consumer<SummaryProvider>(
                        builder: (context, summaryProvider, _) {
                          if (summaryProvider.isLoading) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLoadingIndicator(teal),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading your ocean of notes...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (summaryProvider.summaries.isEmpty) {
                            return _buildEmptyState(teal);
                          }

                          return RefreshIndicator(
                            onRefresh: _refreshSummaries,
                            color: teal,
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 18,
                                crossAxisSpacing: 18,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: summaryProvider.summaries.length,
                              itemBuilder: (context, index) {
                                final summary = summaryProvider.summaries[index];
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 300 + (index * 50)),
                                  curve: Curves.easeOutBack,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Opacity(
                                        opacity: value,
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
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _buildFloatingBottomBar(teal),
              ),
              if (_showGalleryPanel) 
                _buildGalleryPanel(teal),
              if (_showVoicePanel) 
                _buildVoicePanel(teal),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MaterialColor teal) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [teal.shade400, teal.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: teal.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.waves,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimatedTitle(),
            Text(
              'Your AI-powered note companion',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator(MaterialColor teal) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 2),
        builder: (context, value, child) {
          return CustomPaint(
            painter: _OceanLoadingPainter(
              progress: value,
              color: teal,
            ),
          );
        },
      ),
    );
  }

  Widget _AnimatedTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              "NEURANOTE",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(MaterialColor teal) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingElement(
            floatDistance: 6,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.note_add_outlined,
                size: 70,
                color: teal.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Your Journey',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: teal.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap the + button to create your first ocean of notes',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureHint(Icons.image, 'Image', teal),
              const SizedBox(width: 20),
              _buildFeatureHint(Icons.mic, 'Voice', teal),
              const SizedBox(width: 20),
              _buildFeatureHint(Icons.notifications, 'Remind', teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHint(IconData icon, String label, MaterialColor teal) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: teal.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: teal, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBottomBar(MaterialColor teal) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AnimatedIconButton(
            icon: Icons.add_photo_alternate,
            label: 'Image',
            teal: teal,
            onTap: () {
              setState(() {
                _showGalleryPanel = !_showGalleryPanel;
                _showVoicePanel = false;
              });
            },
            isActive: _showGalleryPanel,
          ),
          ScaleTransition(
            scale: _fabAnimation,
            child: PulsingOceanButton(
              onPressed: () => context.pushNamed('summarize'),
              color: teal,
              size: 56,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
          _AnimatedIconButton(
            icon: Icons.mic,
            label: 'Voice',
            teal: teal,
            onTap: () {
              setState(() {
                _showVoicePanel = !_showVoicePanel;
                _showGalleryPanel = false;
              });
            },
            isActive: _showVoicePanel,
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryPanel(MaterialColor teal) {
    return _BottomExpandablePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, color: teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add from Image',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  teal: teal,
                  onTap: () {
                    setState(() => _showGalleryPanel = false);
                    context.pushNamed('summarize');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  teal: teal,
                  onTap: () {
                    setState(() => _showGalleryPanel = false);
                    context.pushNamed('summarize');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _showGalleryPanel = false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePanel(MaterialColor teal) {
    return _BottomExpandablePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Voice Recording',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FloatingElement(
            floatDistance: 5,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    teal.withValues(alpha: 0.2),
                    teal.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.graphic_eq, color: teal, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Tap to start recording",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(() => _showVoicePanel = false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _showVoicePanel = false);
                  context.pushNamed('summarize');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text("Start Recording", style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required MaterialColor teal,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required MaterialColor teal,
    required VoidCallback onTap,
    bool float = false,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: teal, size: 22),
      ),
    );
    
    if (float) {
      return FloatingElement(
        floatDistance: 4,
        child: button,
      );
    }
    return button;
  }

  Widget _buildRemindersButton(MaterialColor teal) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        final activeCount = provider.activeReminders.length;
        
        return GestureDetector(
          onTap: () => context.pushNamed('reminders'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: teal.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.notifications_outlined, color: teal, size: 24),
              ),
              if (activeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      activeCount > 9 ? '9+' : activeCount.toString(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor teal;
  final VoidCallback onTap;
  final bool isActive;

  const _AnimatedIconButton({
    required this.icon,
    required this.label,
    required this.teal,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? teal.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? teal : teal.shade400,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isActive ? teal : Colors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomExpandablePanel extends StatelessWidget {
  final Widget child;
  const _BottomExpandablePanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 100,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _OceanLoadingPainter extends CustomPainter {
  final double progress;
  final MaterialColor color;

  _OceanLoadingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -1.57,
        endAngle: 4.71,
        colors: [
          color.withOpacity(0.5),
          color,
          color.withOpacity(0.5),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      progress * 6.28,
      false,
      progressPaint,
    );

    final wavePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx - 10, center.dy);
    for (var i = 0; i <= 20; i++) {
      final x = center.dx - 10 + i;
      final y = center.dy + sin((i * 0.5) + (progress * 6.28)) * 5;
      path.lineTo(x, y);
    }
    path.lineTo(center.dx + 10, center.dy);
    path.close();

    canvas.drawCircle(center, 8, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _OceanLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
