import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant {
  primaryGradient,
  primaryViolet,
  secondaryOutline,
  coralAction,
}

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final double height;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primaryGradient,
    this.height = 48.0,
    this.width,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonContent;

    if (widget.variant == AppButtonVariant.secondaryOutline) {
      buttonContent = SizedBox(
        height: widget.height,
        width: widget.width,
        child: OutlinedButton(
          onPressed: widget.isLoading ? null : _handleTap,
          child: _buildInner(AppColors.textLavender),
        ),
      );
    } else if (widget.variant == AppButtonVariant.coralAction) {
      buttonContent = SizedBox(
        height: widget.height,
        width: widget.width,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.coralAccent,
            foregroundColor: AppColors.white,
          ),
          onPressed: widget.isLoading ? null : _handleTap,
          child: _buildInner(AppColors.white),
        ),
      );
    } else if (widget.variant == AppButtonVariant.primaryViolet) {
      buttonContent = SizedBox(
        height: widget.height,
        width: widget.width,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricViolet,
            foregroundColor: AppColors.white,
          ),
          onPressed: widget.isLoading ? null : _handleTap,
          child: _buildInner(AppColors.white),
        ),
      );
    } else {
      // Default: Primary Gradient
      buttonContent = Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          gradient: widget.onPressed == null || widget.isLoading ? null : AppColors.heroGlowGradient,
          color: widget.onPressed == null || widget.isLoading ? AppColors.charcoalSurfaceVariant : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.onPressed == null || widget.isLoading
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x407C3AED),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : _handleTap,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: _buildInner(AppColors.white),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.translucent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: buttonContent,
      ),
    );
  }

  Widget _buildInner(Color color) {
    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
