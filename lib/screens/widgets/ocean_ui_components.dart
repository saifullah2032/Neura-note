import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

// ============================================================================
// NEO-BRUTALIST OCEAN UI COMPONENTS
// ============================================================================
// High contrast, industrial-tactile design components
// Thick black borders (3.0 width), hard shadows, 4px border radius
// ============================================================================

// Color Constants
const Color _pureBlack = Color(0xFF000000);
const Color _pureSalt = Color(0xFFFBFBFB);
const Color _skyBlue = Color(0xFFC6E7FF);
const Color _seafoam = Color(0xFFD4F6FF);
const Color _sandGold = Color(0xFFFFDDAE);

// ============================================================================
// NEO CONTAINER - Core Neo-Brutalist wrapper component
// ============================================================================

class NeoContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BoxShadow? shadow;

  const NeoContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor = _pureBlack,
    this.borderWidth = 3.0,
    this.borderRadius = 4.0,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? _pureSalt,
        border: Border.all(
          color: borderColor ?? _pureBlack,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow != null ? [shadow!] : _defaultNeoBrutalistShadow(),
      ),
      child: child,
    );
  }

  static List<BoxShadow> _defaultNeoBrutalistShadow() {
    return [
      BoxShadow(
        color: _pureBlack,
        offset: const Offset(5, 5),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }
}

// ============================================================================
// SINKING BUTTON - Stateful Neo-Brutalist button with physical press feel
// ============================================================================

class SinkingButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isLoading;
  final IconData? icon;
  final MainAxisAlignment mainAxisAlignment;

  const SinkingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = _sandGold,
    this.textColor = _pureBlack,
    this.width,
    this.height,
    this.isLoading = false,
    this.icon,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  State<SinkingButton> createState() => _SinkingButtonState();
}

class _SinkingButtonState extends State<SinkingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    _pressController.reverse();
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (widget.onPressed == null || widget.isLoading) return;
    _pressController.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        // Interpolate between idle (5px offset) and pressed (4px offset with translation)
        final idleShadow = BoxShadow(
          color: _pureBlack,
          offset: const Offset(5, 5),
          blurRadius: 0,
          spreadRadius: 0,
        );

        final pressedShadow = BoxShadow(
          color: _pureBlack,
          offset: const Offset(4, 4),
          blurRadius: 0,
          spreadRadius: 0,
        );

        final shadowLerp = BoxShadow.lerp(
          idleShadow,
          pressedShadow,
          _pressController.value,
        );

        final translationY = 5 - (4 * _pressController.value);

        return GestureDetector(
          onTapDown: isDisabled ? null : _onTapDown,
          onTapUp: isDisabled ? null : _onTapUp,
          onTapCancel: isDisabled ? null : _onTapCancel,
          child: Transform.translate(
            offset: Offset(0, translationY),
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.shade300
                    : (widget.backgroundColor ?? _sandGold),
                border: Border.all(
                  color: _pureBlack,
                  width: 3.0,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [shadowLerp!],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: widget.mainAxisAlignment,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.textColor ?? _pureBlack,
                        ),
                      ),
                    )
                  else ...[
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: isDisabled ? Colors.grey : widget.textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDisabled ? Colors.grey : widget.textColor,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// TOKEN BADGE - High-contrast badge for AI token economy display
// ============================================================================

class TokenBadge extends StatelessWidget {
  final int tokenCount;
  final String? label;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool isCompact;

  const TokenBadge({
    super.key,
    required this.tokenCount,
    this.label,
    this.onTap,
    this.backgroundColor = _sandGold,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeoContainer(
        backgroundColor: backgroundColor,
        borderColor: _pureBlack,
        borderWidth: 2.5,
        borderRadius: 4.0,
        padding: isCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shadow: BoxShadow(
          color: _pureBlack,
          offset: const Offset(3, 3),
          blurRadius: 0,
          spreadRadius: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flash_on,
              color: _pureBlack,
              size: isCompact ? 16 : 20,
            ),
            const SizedBox(width: 8),
            Text(
              '$tokenCount',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: isCompact ? 12 : 14,
                fontWeight: FontWeight.w900,
                color: _pureBlack,
                letterSpacing: 0.2,
              ),
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: _pureBlack,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// OCEAN TRANSITIONS - Hard-cut page transitions
// ============================================================================

class OceanTransitions {
  static const Curve brutalistSnap = Curves.easeInOut;
  static const Curve heavyPress = Curves.easeOutQuart;

  static Route<T> fadeSlide<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      reverseTransitionDuration: duration ?? const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: brutalistSnap,
          reverseCurve: brutalistSnap,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> scaleFade<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      reverseTransitionDuration: duration ?? const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: brutalistSnap,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> oceanWave<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 400),
      reverseTransitionDuration: duration ?? const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: brutalistSnap,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: brutalistSnap),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.15),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}

// ============================================================================
// OCEAN BOTTOM BAR - Neo-Brutalist navigation
// ============================================================================

class OceanBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<OceanBottomNavItem> items;
  final ValueChanged<int> onTap;

  const OceanBottomBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: NeoContainer(
        backgroundColor: _pureSalt,
        borderColor: _pureBlack,
        borderWidth: 3.0,
        borderRadius: 4.0,
        padding: const EdgeInsets.all(8),
        shadow: BoxShadow(
          color: _pureBlack,
          offset: const Offset(5, 5),
          blurRadius: 0,
          spreadRadius: 0,
        ),
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              return _OceanNavItem(
                item: items[index],
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class OceanBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const OceanBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class _OceanNavItem extends StatefulWidget {
  final OceanBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _OceanNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_OceanNavItem> createState() => _OceanNavItemState();
}

class _OceanNavItemState extends State<_OceanNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isSelected ? _skyBlue : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected ? _pureBlack : Colors.transparent,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  widget.isSelected
                      ? (widget.item.activeIcon ?? widget.item.icon)
                      : widget.item.icon,
                  color: _pureBlack,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      widget.isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: _pureBlack,
                  fontFamily: 'DM Sans',
                  letterSpacing: 0.1,
                ),
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STAGGERED SLIDE FADE - Animation component
// ============================================================================

class StaggeredSlideFade extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const StaggeredSlideFade({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.beginOffset = const Offset(0.0, 0.15),
  });

  @override
  State<StaggeredSlideFade> createState() => _StaggeredSlideFadeState();
}

class _StaggeredSlideFadeState extends State<StaggeredSlideFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
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
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ============================================================================
// OCEAN BACKGROUND ANIMATION - Rive wave background (layered behind UI)
// ============================================================================

class OceanBackgroundAnimation extends StatefulWidget {
  final String? riveAsset;
  final Widget? child;
  final bool showWave;
  final double opacity;

  const OceanBackgroundAnimation({
    super.key,
    this.riveAsset,
    this.child,
    this.showWave = true,
    this.opacity = 0.4,
  });

  @override
  State<OceanBackgroundAnimation> createState() =>
      _OceanBackgroundAnimationState();
}

class _OceanBackgroundAnimationState extends State<OceanBackgroundAnimation> {
  rive.Artboard? _artboard;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.riveAsset != null) {
      _initRive();
    }
  }

  Future<void> _initRive() async {
    try {
      final file = await rive.RiveFile.asset(widget.riveAsset!);
      final artboard = file.mainArtboard;
      final controller =
          rive.StateMachineController.fromArtboard(artboard, 'Wave State');
      if (controller != null) {
        artboard.addController(controller);
        _artboard = artboard;
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('Failed to load Rive: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.showWave && _artboard != null && _isPlaying)
          Positioned.fill(
            child: Opacity(
              opacity: widget.opacity,
              child: rive.Rive(
                artboard: _artboard!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

// ============================================================================
// OCEAN LOADING OVERLAY - Neo-Brutalist loading state
// ============================================================================

class OceanLoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const OceanLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  State<OceanLoadingOverlay> createState() => _OceanLoadingOverlayState();
}

class _OceanLoadingOverlayState extends State<OceanLoadingOverlay> {
  rive.Artboard? _artboard;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRive();
  }

  Future<void> _initRive() async {
    try {
      final file = await rive.RiveFile.asset('assets/animations/loading-lg.riv');
      final artboard = file.mainArtboard;
      artboard.addController(rive.SimpleAnimation('Animation 1'));
      _artboard = artboard;
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Failed to load Rive animation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: _pureSalt.withValues(alpha: 0.85),
                child: Center(
                  child: NeoContainer(
                    backgroundColor: _pureSalt,
                    borderColor: _pureBlack,
                    borderWidth: 3.0,
                    borderRadius: 4.0,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isInitialized && _artboard != null)
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: rive.Rive(artboard: _artboard!),
                          )
                        else
                          const SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _pureBlack,
                              ),
                            ),
                          ),
                        if (widget.message != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            widget.message!,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _pureBlack,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// OCEAN TEXT FIELD - Neo-Brutalist input
// ============================================================================

class OceanTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const OceanTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  @override
  State<OceanTextField> createState() => _OceanTextFieldState();
}

class _OceanTextFieldState extends State<OceanTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _focusAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
      animation: _focusAnimation,
      builder: (context, child) {
        return NeoContainer(
          backgroundColor: _seafoam, // #D4F6FF
          borderColor: _pureBlack,
          borderWidth: 3.0,
          borderRadius: 4.0,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          shadow: BoxShadow(
            color: _pureBlack,
            offset: Offset(4 + (_focusAnimation.value * 1), 4),
            blurRadius: 0,
            spreadRadius: 0,
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            validator: widget.validator,
            onTap: () {
              setState(() => _isFocused = true);
              _controller.forward();
            },
            onEditingComplete: () {
              setState(() => _isFocused = false);
              _controller.reverse();
            },
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _pureBlack,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              labelText: widget.labelText,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _pureBlack,
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(
                        widget.suffixIcon,
                        color: _pureBlack,
                        size: 20,
                      ),
                      onPressed: widget.onSuffixTap,
                    )
                  : null,
              hintStyle: const TextStyle(
                fontFamily: 'DM Sans',
                color: Color(0xFF999999),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              labelStyle: const TextStyle(
                fontFamily: 'DM Sans',
                color: _pureBlack,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// OCEAN HEADER - Neo-Brutalist header component
// ============================================================================

class OceanHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBackButton;
  final VoidCallback? onBack;

  const OceanHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          if (showBackButton)
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _pureBlack,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.transparent,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: _pureBlack,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _pureBlack,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF666666),
                      letterSpacing: 0.1,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ============================================================================
// OCEAN SHIMMER - Loading skeleton
// ============================================================================

class OceanShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const OceanShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 4,
  });

  @override
  State<OceanShimmer> createState() => _OceanShimmerState();
}

class _OceanShimmerState extends State<OceanShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _pureBlack,
              width: 2.0,
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE8E8E8),
                Color(0xFFF5F5F5),
                Color(0xFFE8E8E8),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}
