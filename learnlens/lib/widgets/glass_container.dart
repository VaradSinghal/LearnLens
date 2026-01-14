import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.05,
    this.color = Colors.white,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: border ?? Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
