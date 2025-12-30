import 'package:flutter/material.dart';

class AnimatedHeart extends StatefulWidget {
  const AnimatedHeart({
    super.key,
    required this.isActive,
    required this.onChanged,
    this.size = 24,
    this.activeColor = Colors.redAccent,
    this.inactiveColor,
    this.duration = const Duration(milliseconds: 220),
    this.padding = const EdgeInsets.all(8),
  });

  final bool isActive;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color activeColor;
  final Color? inactiveColor;
  final Duration duration;
  final EdgeInsets padding;

  @override
  State<AnimatedHeart> createState() => _AnimatedHeartState();
}

class _AnimatedHeartState extends State<AnimatedHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        // Use a monotonic curve to keep t within 0..1 and avoid TweenSequence assertions.
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onChanged(!widget.isActive);
    _startAnimation();
  }

  void _startAnimation() {
    _controller.stop();
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _handleTap,
        child: Padding(
          padding: widget.padding,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Icon(
                  widget.isActive ? Icons.favorite : Icons.favorite_border,
                  color: widget.isActive
                      ? widget.activeColor
                      : widget.inactiveColor,
                  size: widget.size,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
