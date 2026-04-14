import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/themes.dart';

// ============================================================================
// SWAYING CORAL - Sine Wave Animation (3s period, 5° magnitude)
// ============================================================================

class SwayingCoral extends StatefulWidget {
  final bool isLeft;
  final Color primaryColor;
  final Color secondaryColor;
  final double height;

  const SwayingCoral({
    super.key,
    this.isLeft = true,
    this.primaryColor = AppTheme.glassSoftTeal,
    this.secondaryColor = AppTheme.primaryOceanTeal,
    this.height = 150,
  });

  @override
  State<SwayingCoral> createState() => _SwayingCoralState();
}

class _SwayingCoralState extends State<SwayingCoral>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 3 second period
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _SwayingCoralPainter(
            animation: _controller.value,
            isLeft: widget.isLeft,
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor,
          ),
          size: Size(widget.isLeft ? 120 : 120, widget.height),
        );
      },
    );
  }
}

class _SwayingCoralPainter extends CustomPainter {
  final double animation;
  final bool isLeft;
  final Color primaryColor;
  final Color secondaryColor;

  _SwayingCoralPainter({
    required this.animation,
    required this.isLeft,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 5 degree magnitude = ~0.087 radians
    const double maxAngle = 0.087; // ~5 degrees
    
    // Draw coral branches
    _drawCoralBranches(canvas, size, maxAngle);
    // Draw sea grass
    _drawSeaGrass(canvas, size, maxAngle);
  }

  void _drawCoralBranches(Canvas canvas, Size size, double maxAngle) {
    final paint1 = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = secondaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Draw 5 coral branches
    for (int i = 0; i < 5; i++) {
      final baseX = isLeft 
          ? 20.0 + (i * 20) 
          : size.width - 20.0 - (i * 20);
      
      // Sine wave for swaying - 3 second period
      final swayOffset = sin((animation * 2 * pi) + (i * 0.5)) * maxAngle;
      final height = size.height * (0.3 + (i % 3) * 0.15);

      final path = Path();
      path.moveTo(baseX - 6, size.height);
      
      // Apply rotation transform for sway
      canvas.save();
      canvas.translate(baseX, size.height);
      canvas.rotate(swayOffset);
      canvas.translate(-baseX, -size.height);
      
      path.quadraticBezierTo(
        baseX + (swayOffset * 50),
        size.height - height * 0.5,
        baseX + (swayOffset * 30),
        size.height - height,
      );
      path.quadraticBezierTo(
        baseX + (swayOffset * 50),
        size.height - height * 0.5,
        baseX + 6,
        size.height,
      );
      path.close();
      
      canvas.drawPath(path, i % 2 == 0 ? paint1 : paint2);
      canvas.restore();
    }
  }

  void _drawSeaGrass(Canvas canvas, Size size, double maxAngle) {
    final grassPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Draw sea grass strands
    for (int i = 0; i < 6; i++) {
      final baseX = isLeft 
          ? 15.0 + (i * 18) 
          : size.width - 15.0 - (i * 18);
      
      // Different phase for natural movement
      final swayOffset = sin((animation * 2 * pi * 0.7) + (i * 0.4)) * maxAngle * 0.8;
      final grassHeight = size.height * (0.25 + (i % 4) * 0.1);

      final path = Path();
      path.moveTo(baseX - 2, size.height);
      
      canvas.save();
      canvas.translate(baseX, size.height);
      canvas.rotate(swayOffset);
      canvas.translate(-baseX, -size.height);
      
      path.quadraticBezierTo(
        baseX + (swayOffset * 30),
        size.height - grassHeight * 0.5,
        baseX + (swayOffset * 20),
        size.height - grassHeight,
      );
      path.quadraticBezierTo(
        baseX + (swayOffset * 30),
        size.height - grassHeight * 0.5,
        baseX + 2,
        size.height,
      );
      path.close();
      
      canvas.drawPath(path, grassPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SwayingCoralPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

// ============================================================================
// UNDERWATER CURRENT BACKGROUND
// ============================================================================

class UnderwaterCurrentBackground extends StatefulWidget {
  final Widget child;

  const UnderwaterCurrentBackground({
    super.key,
    required this.child,
  });

  @override
  State<UnderwaterCurrentBackground> createState() => _UnderwaterCurrentBackgroundState();
}

class _UnderwaterCurrentBackgroundState extends State<UnderwaterCurrentBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient base
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryOceanTeal.withValues(alpha: 0.05),
                AppTheme.glassSoftTeal.withValues(alpha: 0.08),
                AppTheme.backgroundBeachSand,
              ],
            ),
          ),
        ),
        // Animated orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _FloatingOrbsPainter(animation: _controller.value),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _FloatingOrbsPainter extends CustomPainter {
  final double animation;

  _FloatingOrbsPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      _Orb(size.width * 0.15, size.height * 0.25, 50, AppTheme.primaryOceanTeal, 0.08),
      _Orb(size.width * 0.75, size.height * 0.2, 65, AppTheme.glassSoftTeal, 0.06),
      _Orb(size.width * 0.4, size.height * 0.55, 40, AppTheme.primaryOceanTeal, 0.05),
      _Orb(size.width * 0.85, size.height * 0.7, 35, AppTheme.glassLightPeach, 0.04),
    ];

    for (final orb in orbs) {
      final yOffset = sin((animation * 2 * pi) + orb.phase) * 15;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: orb.opacity),
            orb.color.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(orb.x, orb.y + yOffset),
          radius: orb.radius,
        ));

      canvas.drawCircle(
        Offset(orb.x, orb.y + yOffset),
        orb.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingOrbsPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _Orb {
  final double x;
  final double y;
  final double radius;
  final Color color;
  final double opacity;
  final double phase;

  _Orb(this.x, this.y, this.radius, this.color, this.opacity, [this.phase = 0]);
}
