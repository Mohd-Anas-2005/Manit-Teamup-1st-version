import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/manit_badge.dart';
import '../../../core/services/supabase_service.dart';
import '../../teams/presentation/create_team_screen.dart';
import '../../teams/services/team_repository.dart';
import '../domain/user_profile.dart';

/// Detailed student profile screen for discovered scholars.
///
/// Follows strict privacy constraints:
/// - Never renders student scholar numbers, private documents, or contact phone numbers.
/// - Presents collaborative details: skills, interests, portfolio, branch, and institutional verification.
class StudentDetailScreen extends StatelessWidget {
  final UserProfile student;

  const StudentDetailScreen({
    super.key,
    required this.student,
  });

  Widget _buildMembershipBadge() {
    if (student.membershipStatus == null) {
      return ManitBadge.notSpecified();
    }
    switch (student.membershipStatus!) {
      case MembershipStatus.manitStudent:
        if (student.verificationStatus == VerificationStatus.verified) {
          return ManitBadge.verified(label: 'MANIT Verified');
        } else if (student.verificationStatus == VerificationStatus.pendingReview) {
          return const ManitBadge(
            label: 'MANIT Student — Review Pending',
            variant: ManitBadgeVariant.unverifiedStudent,
            icon: Icons.hourglass_top_rounded,
          );
        } else if (student.verificationStatus == VerificationStatus.rejected) {
          return const ManitBadge(
            label: 'MANIT Student — Declined',
            variant: ManitBadgeVariant.unverifiedStudent,
            icon: Icons.cancel_outlined,
          );
        } else {
          return ManitBadge.unverified(label: 'MANIT Student — Unverified');
        }
      case MembershipStatus.otherCollege:
        return ManitBadge.otherCollege(
          student.collegeName.isNotEmpty ? student.collegeName : 'Other College',
        );
      case MembershipStatus.nonStudent:
        return ManitBadge.nonStudent(label: 'Non-student');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        title: const Text('Student Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header Card
            StaggeredEntrance(
              index: 0,
              child: GradientCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.electricVioletSubtle,
                      child: Text(
                        student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.electricVioletGlow,
                          fontSize: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      student.fullName,
                      style: AppTypography.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      student.collegeName,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    _buildMembershipBadge(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Academic Background Card
            StaggeredEntrance(
              index: 1,
              child: GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 20, color: AppColors.cyanLight),
                        const SizedBox(width: 8),
                        Text('Academic Background', style: AppTypography.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Branch / Dept', value: student.branch),
                    const Divider(color: AppColors.charcoalBorder, height: 16),
                    _DetailRow(label: 'Academic Year', value: student.academicYear),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bio Section
            if (student.bio.isNotEmpty) ...[
              GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notes_rounded, size: 20, color: AppColors.electricVioletLight),
                        const SizedBox(width: 8),
                        Text('About', style: AppTypography.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      student.bio,
                      style: AppTypography.bodyMedium.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Skills Card
            GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 20, color: AppColors.statusSuccess),
                      const SizedBox(width: 8),
                      Text('Technical Skills', style: AppTypography.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (student.skills.isEmpty)
                    Text(
                      'No skills listed yet.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: student.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.charcoalSurfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.charcoalBorder),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.cyanLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interests Card
            if (student.interests.isNotEmpty) ...[
              GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.interests_outlined, size: 20, color: AppColors.statusWarning),
                        const SizedBox(width: 8),
                        Text('Areas of Interest', style: AppTypography.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: student.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.charcoalSurfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.charcoalBorder),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.electricVioletGlow,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Portfolio & Social Links
            if (student.portfolioUrl != null && student.portfolioUrl!.isNotEmpty) ...[
              GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('Portfolio & Links', style: AppTypography.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      student.portfolioUrl!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.cyanLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            AppButton(
              label: 'Invite to Project / Team',
              icon: Icons.group_add_rounded,
              variant: AppButtonVariant.primaryGradient,
              onPressed: () => _handleInvite(context),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Return to Discovery',
              icon: Icons.arrow_back_rounded,
              variant: AppButtonVariant.secondaryOutline,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _handleInvite(BuildContext context) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || supabase.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to invite teammates.'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
      return;
    }

    if (supabase.currentUser!.id == student.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot invite yourself to a team.'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
      return;
    }

    final teamsRes = await TeamRepository.instance.fetchMyCreatedTeams();
    if (!context.mounted) return;

    final myTeams = teamsRes.data ?? [];
    if (myTeams.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.charcoalSurfaceElevated,
          title: const Text('No Active Teams Found'),
          content: const Text(
            'You have not launched any teams yet. Create a team first to recruit and invite scholars.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
                );
              },
              child: const Text('Create Team'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoalSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Select Team for Invitation', style: AppTypography.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Invite ${student.fullName} to join one of your active project squads:',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              ...myTeams.map((team) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.electricVioletSubtle,
                    child: Icon(Icons.groups_rounded, color: AppColors.electricVioletGlow, size: 20),
                  ),
                  title: Text(team.title, style: AppTypography.titleMedium),
                  subtitle: Text(team.eventName, style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();

                    try {
                      await supabase.client!.from('notifications').insert({
                        'recipient_id': student.id,
                        'type': 'teamAnnouncement',
                        'title': 'Team Invitation 🚀',
                        'body': 'You have been invited to join "${team.title}". Check out the roster!',
                        'related_team_id': team.id,
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Invitation sent to ${student.fullName} for "${team.title}"!')),
                              ],
                            ),
                            backgroundColor: AppColors.charcoalSurfaceElevated,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to send invitation: $e'),
                            backgroundColor: AppColors.statusError,
                          ),
                        );
                      }
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.titleMedium.copyWith(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
