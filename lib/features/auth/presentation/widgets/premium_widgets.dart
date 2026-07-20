import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Staggered Entrance Animation that fades in and slides up its child after a delay.
class FadeInSlideUp extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;

  const FadeInSlideUp({
    super.key,
    required this.child,
    required this.delayMs,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<FadeInSlideUp> createState() => _FadeInSlideUpState();
}

class _FadeInSlideUpState extends State<FadeInSlideUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _timer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A premium button that animates scaling down on tap.
class BouncingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? child;

  const BouncingButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.child,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultBgColor = AppColors.primary;
    final defaultTextColor = AppColors.black;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: (widget.isLoading || widget.onPressed == null)
          ? null
          : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? (widget.backgroundColor ?? defaultBgColor).withOpacity(0.5)
                : (widget.backgroundColor ?? defaultBgColor),
            borderRadius: BorderRadius.circular(16),
            border: widget.backgroundColor == Colors.transparent
                ? Border.all(color: AppColors.border, width: 1.0)
                : null,
            boxShadow: [
              if (widget.onPressed != null &&
                  !widget.isLoading &&
                  widget.backgroundColor != Colors.transparent)
                BoxShadow(
                  color: (widget.backgroundColor ?? defaultBgColor)
                      .withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : (widget.child ??
                  Text(
                    widget.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.textColor ?? defaultTextColor,
                    ),
                  )),
        ),
      ),
    );
  }
}

/// A beautiful logo with a rounded rectangular gold border and gold text inside,
/// complete with a slow breathing/pulse scale animation.
class FinTrackLogo extends StatefulWidget {
  const FinTrackLogo({super.key});

  @override
  State<FinTrackLogo> createState() => _FinTrackLogoState();
}

class _FinTrackLogoState extends State<FinTrackLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.35).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutSine),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(_glowAnimation.value),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'FT',
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A premium text input field styling labels above the field, and providing
/// an animated outline border with glow on focus.
class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final bool enabled;

  final List<TextInputFormatter>? inputFormatters;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
    this.inputFormatters,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _errorText != null;

    Color borderColor = AppColors.border;
    List<BoxShadow> glowShadows = [];

    if (hasError) {
      borderColor = AppColors.expense; // Red error border
      glowShadows = [
        BoxShadow(
          color: AppColors.expense.withOpacity(0.1),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
    } else if (_isFocused) {
      borderColor = AppColors.primary; // Active border color
      glowShadows = [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.18),
          blurRadius: 10,
          spreadRadius: 1.5,
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium upper-case label
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: hasError
                ? AppColors.expense
                : (_isFocused ? AppColors.primary : AppColors.secondaryText),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        // Animated input field wrapper
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: glowShadows,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            inputFormatters: widget.inputFormatters,
            onChanged: widget.onChanged,
            validator: (value) {
              final result = widget.validator?.call(value);
              // Safely trigger state update for error outline
              if (result != _errorText) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _errorText = result;
                    });
                  }
                });
              }
              return result;
            },
            decoration: InputDecoration(
              filled: false, // Prevents TextFormField from drawing its own background
              fillColor: Colors.transparent,
              hintText: widget.hintText,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: AppColors.disabledText.withOpacity(0.6),
                fontSize: 15,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              // We hide default borders, and let the AnimatedContainer handle them
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              // We set height of error to 0 so standard error text is not shown directly inside the border
              errorStyle: const TextStyle(height: 0),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _errorText!,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.expense,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
