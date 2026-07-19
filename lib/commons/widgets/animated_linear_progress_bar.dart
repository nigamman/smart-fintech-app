import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AnimatedLinearProgressBar extends StatefulWidget {
  final double progress;
  final double minHeight;
  final Color? valueColor;
  final Color? backgroundColor;

  const AnimatedLinearProgressBar({
    super.key,
    required this.progress,
    this.minHeight = 6.0,
    this.valueColor,
    this.backgroundColor,
  });

  @override
  State<AnimatedLinearProgressBar> createState() => _AnimatedLinearProgressBarState();
}

class _AnimatedLinearProgressBarState extends State<AnimatedLinearProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Sequence: 0.0 -> 1.0 (Full) -> target progress
    _animation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: widget.progress).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_controller);

    _controller.forward();
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
        return LinearProgressIndicator(
          value: _animation.value.clamp(0.0, 1.0),
          minHeight: widget.minHeight,
          backgroundColor: widget.backgroundColor ?? AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor ?? AppColors.primary),
        );
      },
    );
  }
}
