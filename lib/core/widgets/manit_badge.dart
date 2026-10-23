import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ManitBadgeVariant {
  verifiedScholar,
  unverifiedStudent,
  otherCollege,
  nonStudent,
  notSpecified,
  scholarNumber,
  openVacancies,
  hackathon,
}

class ManitBadge extends StatelessWidget {
  final String label;
  final ManitBadgeVariant variant;
  final IconData? icon;

  const ManitBadge({
    super.key,
    required this.label,
    this.variant = ManitBadgeVariant.verifiedScholar,
    this.icon,
  });

  /// Clearly visible MANIT Verified badge only for verified MANIT students
  factory ManitBadge.verified({String label = 'MANIT Scholar'}) {
    return ManitBadge(
      label: label,
      variant: ManitBadgeVariant.verifiedScholar,
      icon: Icons.verified_rounded,
    );
  }

  /// Self-declared unverified MANIT student badge
  factory ManitBadge.unverified({String label = 'MANIT Student — Unverified'}) {
    return ManitBadge(
      label: label,
      variant: ManitBadgeVariant.unverifiedStudent,
      icon: Icons.pending_outlined,
    );
  }

  /// Other college badge
  factory ManitBadge.otherCollege(String collegeName) {
    return ManitBadge(
      label: collegeName,
      variant: ManitBadgeVariant.otherCollege,
      icon: Icons.school_outlined,
    );
  }

  /// Non-student badge
  factory ManitBadge.nonStudent({String label = 'Non-student'}) {
    return ManitBadge(
      label: label,
      variant: ManitBadgeVariant.nonStudent,
      icon: Icons.person_outline,
    );
  }

  /// Not specified badge
  factory ManitBadge.notSpecified({String label = 'Not specified'}) {
    return ManitBadge(
      label: label,
      variant: ManitBadgeVariant.notSpecified,
      icon: Icons.help_outline_rounded,
    );
  }

  factory ManitBadge.scholarId(String scholarNumber) {
    return ManitBadge(
      label: scholarNumber,
      variant: ManitBadgeVariant.scholarNumber,
      icon: Icons.badge_outlined,
    );
  }

  factory ManitBadge.vacancies(int count) {
    return ManitBadge(
      label: '$count open spot${count == 1 ? '' : 's'}',
      variant: ManitBadgeVariant.openVacancies,
      icon: Icons.person_add_alt_1_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case ManitBadgeVariant.verifiedScholar:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: AppColors.verifiedManitGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x337C3AED),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.verified_rounded, size: 14, color: AppColors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );

      case ManitBadgeVariant.unverifiedStudent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.statusWarning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.statusWarning.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.pending_outlined, size: 13, color: AppColors.statusWarning),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusWarning,
                ),
              ),
            ],
          ),
        );

      case ManitBadgeVariant.otherCollege:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cyanSubtle,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyanLight.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.school_outlined, size: 13, color: AppColors.cyanLight),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyanLight,
                ),
              ),
            ],
          ),
        );

      case ManitBadgeVariant.nonStudent:
      case ManitBadgeVariant.notSpecified:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.charcoalSurfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.charcoalBorder, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.person_outline, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );

      case ManitBadgeVariant.openVacancies:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.coralSubtle,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.coralLight.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.person_add_alt_1_rounded, size: 13, color: AppColors.coralLight),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coralLight,
                ),
              ),
            ],
          ),
        );

      case ManitBadgeVariant.scholarNumber:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.charcoalSurfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.charcoalBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: AppColors.textLavender),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLavender,
                ),
              ),
            ],
          ),
        );

      case ManitBadgeVariant.hackathon:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cyanSubtle,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyanLight.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.code_rounded, size: 13, color: AppColors.cyanLight),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyanLight,
                ),
              ),
            ],
          ),
        );
    }
  }
}
