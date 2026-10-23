import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/manit_badge.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/user_profile.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const ProfileScreen({super.key, this.onOpenSettings});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = false;
  bool _isSubmittingVerification = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.currentUser;
      if (user != null) {
        final res = await supabase.client!
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (res != null) {
          if (mounted) {
            setState(() {
              _profile = UserProfile.fromJson(res);
              _isLoading = false;
            });
          }
        } else {
          // Fallback from auth metadata
          final metadata = user.userMetadata ?? {};
          if (mounted) {
            setState(() {
              _profile = UserProfile(
                id: user.id,
                email: user.email ?? '',
                fullName: metadata['full_name'] as String? ?? 'MANIT Scholar',
                scholarNumber: metadata['scholar_number'] as String?,
                membershipStatus: MembershipStatus.manitStudent,
                verificationStatus: (metadata['is_manit_verified'] as bool? ?? false)
                    ? VerificationStatus.verified
                    : VerificationStatus.unverified,
              );
              _isLoading = false;
            });
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRequestVerification() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) return;

    setState(() => _isSubmittingVerification = true);

    try {
      final res = await supabase.client!.rpc('submit_for_verification', params: {
        'p_scholar_number': _profile?.scholarNumber,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] as String? ?? 'Verification request submitted for review.'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit verification request: $e'),
            backgroundColor: AppColors.coralAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingVerification = false);
      }
    }
  }

  Widget _buildMembershipBadge(UserProfile? profile) {
    if (profile == null || profile.membershipStatus == null) {
      return ManitBadge.notSpecified();
    }

    switch (profile.membershipStatus!) {
      case MembershipStatus.manitStudent:
        if (profile.verificationStatus == VerificationStatus.verified) {
          return ManitBadge.verified(label: 'MANIT Verified');
        } else if (profile.verificationStatus == VerificationStatus.pendingReview) {
          return const ManitBadge(
            label: 'MANIT Student — Review Pending',
            variant: ManitBadgeVariant.unverifiedStudent,
            icon: Icons.hourglass_top_rounded,
          );
        } else if (profile.verificationStatus == VerificationStatus.rejected) {
          return const ManitBadge(
            label: 'MANIT Student — Declined',
            variant: ManitBadgeVariant.unverifiedStudent,
            icon: Icons.cancel_outlined,
          );
        } else {
          return ManitBadge.unverified(label: 'MANIT Student — Unverified');
        }

      case MembershipStatus.otherCollege:
        final college = profile.collegeName.trim().isNotEmpty &&
                profile.collegeName.trim().toLowerCase() != 'manit bhopal'
            ? profile.collegeName.trim()
            : 'Student (Other College)';
        return ManitBadge.otherCollege(college);

      case MembershipStatus.nonStudent:
        return ManitBadge.nonStudent(label: 'Non-student');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.midnightNavy,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            CardSkeleton(height: 200),
            CardSkeleton(height: 140),
            CardSkeleton(height: 120),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.midnightNavy,
        body: ErrorStateView(
          message: _errorMessage!,
          onRetry: _loadProfile,
        ),
      );
    }

    final profile = _profile;

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 48),
        child: Column(
          children: [
            // Header Card
            StaggeredEntrance(
              index: 0,
              child: GradientCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.electricVioletSubtle,
                      child: Text(
                        profile?.fullName.isNotEmpty == true ? profile!.fullName[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.electricVioletGlow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile?.fullName ?? 'MANIT Scholar',
                      style: AppTypography.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.email ?? 'Institutional Scholar',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 12),

                    // Membership Status Badge Display
                    _buildMembershipBadge(profile),

                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Edit Profile & Skills',
                      variant: AppButtonVariant.secondaryOutline,
                      height: 40,
                      icon: Icons.edit_outlined,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                              initialProfile: profile,
                              onSaved: _loadProfile,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Verification Action Card (Only shown for unverified MANIT students)
            if (profile != null &&
                profile.membershipStatus == MembershipStatus.manitStudent &&
                profile.verificationStatus == VerificationStatus.unverified) ...[
              GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user_outlined, color: AppColors.electricVioletLight, size: 22),
                        SizedBox(width: 8),
                        Text('Get MANIT Verified Badge', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submit your institutional student ID to unlock the official MANIT Verified Scholar badge on your team pitches.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Submit for Institutional Review',
                      isLoading: _isSubmittingVerification,
                      onPressed: _handleRequestVerification,
                    ),
                  ],
                ),
              ),
            ],

            // Academic & Department Info
            GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Academic & Membership Details', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.badge_outlined,
                    'Membership Category',
                    profile?.membershipStatus?.displayName ?? 'Not specified',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.school_outlined,
                    'College / Institute',
                    profile?.collegeName ?? 'MANIT Bhopal',
                  ),
                  if (profile?.membershipStatus == MembershipStatus.manitStudent) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.verified_outlined,
                      'Verification Status',
                      profile?.verificationStatus.displayName ?? 'Unverified',
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.category_outlined,
                    'Department',
                    profile?.branch ?? 'Computer Science & Engineering',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    'Academic Year',
                    profile?.academicYear ?? '1st Year B.Tech',
                  ),
                ],
              ),
            ),

            // Technical Skills
            GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Technical Skills', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  if (profile?.skills.isNotEmpty == true)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile!.skills
                          .map((s) => Chip(label: Text(s)))
                          .toList(),
                    )
                  else
                    Text(
                      'No skills listed yet. Add skills to help teammates find you.',
                      style: AppTypography.bodySmall,
                    ),
                ],
              ),
            ),

            // Privacy & Sensitive Data Safeguard Notice
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Student IDs, private verification documents, and contact details are kept strictly private.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.cyanLight),
        const SizedBox(width: 10),
        Text('$label: ', style: AppTypography.bodySmall),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
