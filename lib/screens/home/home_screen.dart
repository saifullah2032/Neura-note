import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/summary_provider.dart';
import '../../model/summary_model.dart';

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
    // Load summaries when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final summaryProvider = context.read<SummaryProvider>();
      if (authProvider.userId != null) {
        summaryProvider.subscribeTo(authProvider.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final offWhite = const Color(0xFFF8F9FA);
    final teal = Colors.teal;

    return Scaffold(
      backgroundColor: offWhite,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        "NEURANOTE",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: teal.shade800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      // Reminders button with badge
                      _buildRemindersButton(teal),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.pushNamed('profile'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: teal.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.settings, color: teal, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Grid of summaries
                  Expanded(
                    child: Consumer<SummaryProvider>(
                      builder: (context, summaryProvider, _) {
                        if (summaryProvider.isLoading) {
                          return Center(
                            child: CircularProgressIndicator(color: teal),
                          );
                        }

                        if (summaryProvider.summaries.isEmpty) {
                          return _buildEmptyState(teal);
                        }

                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: summaryProvider.summaries.length,
                          itemBuilder: (context, index) {
                            final summary = summaryProvider.summaries[index];
                            return _SummaryCard(
                              icon: summary.type == SummaryType.image
                                  ? Icons.image
                                  : Icons.mic,
                              title: summary.type == SummaryType.image
                                  ? 'Image Summary'
                                  : 'Voice Summary',
                              subtitle: summary.summarizedText.length > 50
                                  ? '${summary.summarizedText.substring(0, 50)}...'
                                  : summary.summarizedText,
                              color: teal,
                              onTap: () {
                                summaryProvider.setCurrentSummary(summary);
                                context.pushNamed('summary');
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Floating Bottom Bar ---
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery/Image Button
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate, color: teal, size: 28),
                    tooltip: 'Add Image',
                    onPressed: () {
                      setState(() {
                        _showGalleryPanel = !_showGalleryPanel;
                        _showVoicePanel = false;
                      });
                    },
                  ),

                  // New Summary Button (center, prominent)
                  GestureDetector(
                    onTap: () => context.pushNamed('summarize'),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: teal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: teal.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 30),
                    ),
                  ),

                  // Mic Button
                  IconButton(
                    icon: Icon(Icons.mic, color: teal, size: 28),
                    tooltip: 'Record Voice',
                    onPressed: () {
                      setState(() {
                        _showVoicePanel = !_showVoicePanel;
                        _showGalleryPanel = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Gallery Upload Panel ---
          if (_showGalleryPanel)
            _BottomExpandablePanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Image',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _showGalleryPanel = false);
                            context.pushNamed('summarize');
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Gallery"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _showGalleryPanel = false);
                            context.pushNamed('summarize');
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Camera"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
            ),

          // --- Voice Recording Panel ---
          if (_showVoicePanel)
            _BottomExpandablePanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voice Recording',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.graphic_eq, color: teal, size: 48),
                  ),
                  const SizedBox(height: 12),
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
                        ),
                        child: const Text("Start Recording"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

    Widget _buildEmptyState(Color teal) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 80,
            color: teal.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No summaries yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first summary',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersButton(Color teal) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        final activeCount = provider.activeReminders.length;
        
        return GestureDetector(
          onTap: () => context.pushNamed('reminders'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: teal.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, color: teal, size: 24),
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
                        minWidth: 16,
                        minHeight: 16,
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
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
