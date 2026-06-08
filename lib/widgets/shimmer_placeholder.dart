import 'package:flutter/material.dart';

class ShimmerPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData? icon;
  final bool enabled;

  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.icon,
    this.enabled = true,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ShimmerPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        if (!_controller.isAnimating) {
          _controller.repeat(reverse: true);
        }
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E1E24) : const Color(0xFFE2E2E9);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacityVal = _animation.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: baseColor.withOpacity(opacityVal),
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
          ),
          child: Center(
            child: Icon(
              widget.icon ?? Icons.image_outlined,
              // ignore: deprecated_member_use
              color: (isDark ? Colors.white10 : Colors.black12).withOpacity(opacityVal),
              size: 32,
            ),
          ),
        );
      },
    );
  }
}
