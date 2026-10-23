import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final LinearGradient? borderGradient;
  final Color backgroundColor;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.onTap,
    this.borderGradient,
    this.backgroundColor = AppColors.charcoalSurface,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = borderGradient ?? AppColors.cardBorderGlow;

    final content = Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius - 1.2),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2), // Gradient border thickness
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1.2),
        child: content,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}
