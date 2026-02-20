import 'dart:math';
import 'package:flutter/material.dart';

class OceanBackground extends StatefulWidget {
  final Widget child;
  final Color? primaryColor;
  final double waveHeight;
  final bool showBubbles;
  
  const OceanBackground({
    super.key,
    required this.child,
    this.primaryColor,
    this.waveHeight = 120,
    this.showBubbles = true,
  });

  @override
  State<OceanBackground> createState() => _OceanBackgroundState();
}

class _OceanBackgroundState extends State<OceanBackground>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal = widget.primaryColor ?? Colors.teal;
    
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            return CustomPaint(
              painter: _OceanWavePainter(
                animation: _waveController.value,
                color: teal,
                height: widget.waveHeight,
              ),
              size: Size.infinite,
            );
          },
        ),
        if (widget.showBubbles)
          AnimatedBuilder(
            animation: _bubbleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _BubblePainter(
                  animation: _bubbleController.value,
                  primaryColor: teal,
                ),
                size: Size.infinite,
              );
            },
          ),
        widget.child,
      ],
    );
  }
}

Color _colorWithOpacity(Color color, double opacity) {
  return Color.fromRGBO(
    (color.r * 255).round(),
    (color.g * 255).round(),
    (color.b * 255).round(),
    opacity.clamp(0.0, 1.0),
  );
}

class _OceanWavePainter extends CustomPainter {
  final double animation;
  final Color color;
  final double height;

  _OceanWavePainter({
    required this.animation,
    required this.color,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final path = Path();
      final yOffset = height * i * 0.4;
      final amplitude = 12.0 + (i * 4);
      final frequency = 0.008 + (i * 0.002);
      final phase = animation * 2 * pi + (i * pi / 3);

      path.moveTo(0, size.height);
      path.lineTo(0, size.height - height + yOffset);

      for (var x = 0.0; x <= size.width; x += 2) {
        final y = sin((x * frequency) + phase) * amplitude +
            sin((x * frequency * 2) + phase * 1.5) * (amplitude * 0.5);
        path.lineTo(x, size.height - height + yOffset + y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      final layerOpacity = (0.05 + (i * 0.03)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = _colorWithOpacity(color, layerOpacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OceanWavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _BubblePainter extends CustomPainter {
  final double animation;
  final Color primaryColor;

  _BubblePainter({
    required this.animation,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final bubbles = <_Bubble>[];
    
    for (var i = 0; i < 10; i++) {
      bubbles.add(_Bubble(
        x: random.nextDouble() * size.width,
        baseY: random.nextDouble() * size.height,
        radius: 2 + random.nextDouble() * 5,
        speed: 0.15 + random.nextDouble() * 0.35,
        opacity: 0.06 + random.nextDouble() * 0.12,
      ));
    }

    final paint = Paint()..style = PaintingStyle.fill;

    for (final bubble in bubbles) {
      final cyclePosition = (animation * bubble.speed + bubble.baseY / size.height) % 1.0;
      final y = cyclePosition * (size.height + 30) - 15;
      
      final safeOpacity = bubble.opacity.clamp(0.0, 1.0);
      paint.color = _colorWithOpacity(primaryColor, safeOpacity);
      canvas.drawCircle(Offset(bubble.x, y), bubble.radius, paint);
      
      paint.color = _colorWithOpacity(Colors.white, (safeOpacity * 0.35).clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(bubble.x - bubble.radius * 0.3, y - bubble.radius * 0.3),
        bubble.radius * 0.25,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _Bubble {
  final double x;
  final double baseY;
  final double radius;
  final double speed;
  final double opacity;

  _Bubble({
    required this.x,
    required this.baseY,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}

class AnimatedWaveContainer extends StatefulWidget {
  final Widget child;
  final Color waveColor;
  final double height;
  
  const AnimatedWaveContainer({
    super.key,
    required this.child,
    this.waveColor = Colors.teal,
    this.height = 100,
  });

  @override
  State<AnimatedWaveContainer> createState() => _AnimatedWaveContainerState();
}

class _AnimatedWaveContainerState extends State<AnimatedWaveContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
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
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _SingleWavePainter(
                  animation: _controller.value,
                  color: widget.waveColor,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _SingleWavePainter extends CustomPainter {
  final double animation;
  final Color color;

  _SingleWavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _colorWithOpacity(color, 0.25)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.3);

    for (var x = 0.0; x <= size.width; x++) {
      final y = sin((x * 0.02) + (animation * 2 * pi)) * 8 +
          sin((x * 0.04) + (animation * 2 * pi * 1.5)) * 4;
      path.lineTo(x, size.height * 0.3 + y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SingleWavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class PulsingOceanButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final double size;
  
  const PulsingOceanButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.size = 56,
  });

  @override
  State<PulsingOceanButton> createState() => _PulsingOceanButtonState();
}

class _PulsingOceanButtonState extends State<PulsingOceanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.teal;
    final glowOpacity = _glowAnimation.value.clamp(0.0, 1.0);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: _colorWithOpacity(color, glowOpacity),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                customBorder: const CircleBorder(),
                child: Center(child: widget.child),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomBeachWave extends StatefulWidget {
  final double height;
  final Color? primaryColor;
  final Color? secondaryColor;
  
  const CustomBeachWave({
    super.key,
    this.height = 220,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<CustomBeachWave> createState() => _CustomBeachWaveState();
}

class _CustomBeachWaveState extends State<CustomBeachWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF006064);
    final secondaryColor = widget.secondaryColor ?? const Color(0xFF4DB6AC);
    
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BeachWavePainter(
              animation: _controller.value,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _BeachWavePainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color secondaryColor;

  _BeachWavePainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawDeepWave(canvas, size);
    _drawMiddleWave(canvas, size);
    _drawSurfaceWave(canvas, size);
    _drawFoam(canvas, size);
  }

  void _drawDeepWave(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    
    for (double x = 0; x <= size.width; x += 1) {
      final y = sin((x * 0.01) + (animation * 2 * pi)) * 15 +
          sin((x * 0.02) + (animation * 2 * pi * 1.3)) * 8;
      path.lineTo(x, size.height - 40 + y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMiddleWave(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    
    for (double x = 0; x <= size.width; x += 1) {
      final y = sin((x * 0.015) + (animation * 2 * pi * 0.8) + pi / 4) * 12 +
          sin((x * 0.025) + (animation * 2 * pi)) * 6;
      path.lineTo(x, size.height - 70 + y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSurfaceWave(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          secondaryColor.withValues(alpha: 0.5),
          secondaryColor.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);
    
    for (double x = 0; x <= size.width; x += 1) {
      final y = sin((x * 0.02) + (animation * 2 * pi * 1.2)) * 10 +
          sin((x * 0.035) + (animation * 2 * pi * 0.7)) * 5;
      path.lineTo(x, size.height - 100 + y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFoam(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    
    for (double x = 0; x <= size.width; x += 1) {
      final y = sin((x * 0.025) + (animation * 2 * pi * 1.5) + pi / 2) * 8 +
          sin((x * 0.05) + (animation * 2 * pi)) * 3;
      path.lineTo(x, size.height - 115 + y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BeachWavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  
  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey.shade300;
    final highlightColor = widget.highlightColor ?? Colors.white;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final s1 = (_animation.value - 0.3).clamp(0.0, 1.0);
        final s2 = _animation.value.clamp(0.0, 1.0);
        final s3 = (_animation.value + 0.3).clamp(0.0, 1.0);
        
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [s1, s2, s3],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class FloatingElement extends StatefulWidget {
  final Widget child;
  final double floatDistance;
  final Duration duration;
  
  const FloatingElement({
    super.key,
    required this.child,
    this.floatDistance = 8,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<FloatingElement> createState() => _FloatingElementState();
}

class _FloatingElementState extends State<FloatingElement>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value * widget.floatDistance),
          child: widget.child,
        );
      },
    );
  }
}

class OceanGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  
  const OceanGradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      const Color(0xFFF8F9FA),
      const Color(0xFFE0F7FA),
      const Color(0xFFB2EBF2),
    ];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors ?? defaultColors,
        ),
      ),
      child: child,
    );
  }
}
