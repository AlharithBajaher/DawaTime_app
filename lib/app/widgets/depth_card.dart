import 'package:flutter/material.dart';

import '../theme/app_metrics.dart';

class DepthCard extends StatelessWidget {
  const DepthCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.radius = AppRadius.xl,
    this.gradient,
    this.color,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A90B8).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.82),
            blurRadius: 6,
            offset: const Offset(-3, -3),
            spreadRadius: -2,
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
