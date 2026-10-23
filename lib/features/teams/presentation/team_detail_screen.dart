import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/manit_badge.dart';
import '../../../core/widgets/state_views.dart';
import '../../joining_requests/domain/join_request.dart';
import '../../joining_requests/services/join_request_repository.dart';
import '../domain/team.dart';
import '../services/team_repository.dart';
import 'edit_team_screen.dart';

/// Detailed view of a team broadcast with roster members and management controls.
class TeamDetailScreen extends StatefulWidget {
  final Team team;
  final VoidCallback? onTeamModified;

  const TeamDetailScreen({
    super.key,
    required this.team,
    this.onTeamModified,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late Team _team;
  bool _isLoading = false;
  bool _isProcessingAction = false;
  JoinRequest? _userJoinRequest;
  bool _isWithdrawingJoin = false;

  @override
  void initState() {
    super.initState();
    _team = widget.team;
    _refreshTeamDetails();
  }

  bool get _isOwner {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    return currentUserId != null && currentUserId == _team.ownerId;
  }

  bool get _isMember {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    if (currentUserId == null) return false;
    return _team.members.any((m) => m.userId == currentUserId);
  }

  Future<void> _refreshTeamDetails() async {
    if (_team.id.isEmpty) return;
    setState(() => _isLoading = true);

    final res = await TeamRepository.instance.fetchTeamDetails(_team.id);
    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      setState(() {
        _team = res.data!;
      });
    }

    // Fetch user's join request for this team if not owner and not member
    if (!_isOwner && !_isMember) {
      final reqRes = await JoinRequestRepository.instance.fetchUserRequestForTeam(_team.id);
      if (mounted && reqRes.isSuccess) {
        setState(() {
          _userJoinRequest = reqRes.data;
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRecruitment() async {
    setState(() => _isProcessingAction = true);
    final nextStatus = !_team.isRecruiting;

    final res = await TeamRepository.instance.setRecruitmentStatus(
      teamId: _team.id,
      isOpen: nextStatus,
    );

    if (!mounted) return;
    setState(() => _isProcessingAction = false);

    if (res.isSuccess) {
      setState(() {
        _team = _team.copyWith(isRecruiting: nextStatus);
      });
      widget.onTeamModified?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nextStatus ? 'Recruitment reopened!' : 'Recruitment closed.'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Failed to update recruitment.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoalSurfaceElevated,
        title: const Text('Delete Team Broadcast?'),
        content: const Text(
          'Are you sure you want to permanently delete this team? All pending requests will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Team'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessingAction = true);
    final res = await TeamRepository.instance.deleteTeam(_team.id);

    if (!mounted) return;
    setState(() => _isProcessingAction = false);

    if (res.isSuccess) {
      widget.onTeamModified?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team successfully deleted.'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Failed to delete team.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  void _openEditScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditTeamScreen(
          team: _team,
          onUpdated: (updatedTeam) {
            setState(() => _team = updatedTeam);
            widget.onTeamModified?.call();
          },
        ),
      ),
    );
  }

  void _showJoinRequestSheet() {
    final noteController = TextEditingController();
    bool isSheetSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.charcoalSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.send_rounded, color: AppColors.electricVioletLight, size: 22),
                      const SizedBox(width: 8),
                      Text('Submit Joining Pitch', style: AppTypography.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pitch your skills to ${_team.ownerName} for "${_team.title}"',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Share your background, portfolio/GitHub, and what role you wish to fill... (Optional)',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Send Join Request',
                    icon: Icons.send_rounded,
                    variant: AppButtonVariant.primaryGradient,
                    isLoading: isSheetSubmitting,
                    onPressed: () async {
                      setSheetState(() => isSheetSubmitting = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final text = noteController.text.trim();
                      final res = await JoinRequestRepository.instance.submitJoinRequest(
                        teamId: _team.id,
                        message: text,
                      );

                      if (ctx.mounted) {
                        setSheetState(() => isSheetSubmitting = false);
                        Navigator.of(ctx).pop();
                      }

                      if (!mounted) return;

                      if (res.isSuccess) {
                        // Immediate UI update after confirmed backend success
                        setState(() {
                          _userJoinRequest = res.data ??
                              JoinRequest(
                                id: '',
                                teamId: _team.id,
                                teamTitle: _team.title,
                                applicantId: SupabaseService.instance.currentUser?.id ?? '',
                                applicantName: 'Me',
                                applicantBranch: '',
                                applicantYear: '',
                                pitchNote: text,
                                status: RequestStatus.pending,
                                createdAt: DateTime.now(),
                              );
                        });
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text('Join request submitted successfully!')),
                              ],
                            ),
                            backgroundColor: AppColors.charcoalSurfaceElevated,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(res.errorMessage ?? 'Failed to submit join request.'),
                            backgroundColor: AppColors.statusError,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _withdrawJoinRequest() async {
    final req = _userJoinRequest;
    if (req == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoalSurfaceElevated,
        title: const Text('Withdraw Application?'),
        content: const Text(
          'Are you sure you want to withdraw your pending request to join this team?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isWithdrawingJoin = true);
    final res = await JoinRequestRepository.instance.withdrawJoinRequest(req.id);
    if (!mounted) return;
    setState(() => _isWithdrawingJoin = false);

    if (res.isSuccess) {
      // Immediate UI update after confirmed backend success
      setState(() {
        _userJoinRequest = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join request withdrawn successfully.'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Failed to withdraw join request.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressFraction = (_team.memberCount / _team.maxTeamSize).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        title: const Text('Team Details'),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Team',
              onPressed: _openEditScreen,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingStateView(message: 'Loading team details & roster...')
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  StaggeredEntrance(
                    index: 0,
                    child: GradientCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_team.title, style: AppTypography.headlineMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      _team.eventName,
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.cyanLight),
                                    ),
                                  ],
                                ),
                              ),
                              if (_team.isRecruiting && _team.vacanciesLeft > 0)
                                ManitBadge.vacancies(_team.vacanciesLeft)
                              else
                                const ManitBadge(
                                  label: 'Roster Closed',
                                  variant: ManitBadgeVariant.openVacancies,
                                  icon: Icons.lock_outline_rounded,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.charcoalSurfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _team.projectCategory.displayName,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Capacity & Roster Progress Card
                  StaggeredEntrance(
                    index: 1,
                    child: GradientCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Roster Capacity', style: AppTypography.titleMedium),
                              Text(
                                '${_team.memberCount} of ${_team.maxTeamSize} spots filled',
                                style: AppTypography.bodySmall.copyWith(
                                  color: _team.isFull ? AppColors.statusWarning : AppColors.statusSuccess,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressFraction,
                              minHeight: 8,
                              backgroundColor: AppColors.charcoalSurfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _team.isFull ? AppColors.statusWarning : AppColors.electricVioletLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description & Vision
                  StaggeredEntrance(
                    index: 2,
                    child: GradientCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, size: 20, color: AppColors.statusWarning),
                              const SizedBox(width: 8),
                              Text('Project Vision & Scope', style: AppTypography.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _team.description,
                            style: AppTypography.bodyMedium.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Required Skills
                  StaggeredEntrance(
                    index: 3,
                    child: GradientCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt_rounded, size: 20, color: AppColors.statusSuccess),
                              const SizedBox(width: 8),
                              Text('Required Technical Skills', style: AppTypography.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _team.requiredSkills.map((skill) {
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
                  ),
                  const SizedBox(height: 16),

                  // Team Members Roster
                  StaggeredEntrance(
                    index: 4,
                    child: GradientCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.groups_rounded, size: 20, color: AppColors.electricVioletLight),
                              const SizedBox(width: 8),
                              Text('Accepted Team Members', style: AppTypography.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_team.members.isEmpty) ...[
                            // At minimum, show the owner if members list isn't populated yet
                            _MemberTile(
                              name: _team.ownerName,
                              role: 'Owner / Lead',
                              isVerified: _team.ownerIsManitVerified,
                              branch: 'Team Creator',
                            ),
                          ] else
                            ..._team.members.map((member) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _MemberTile(
                                  name: member.fullName,
                                  role: member.role.label,
                                  isVerified: member.isManitVerified,
                                  branch: member.branch.isNotEmpty ? member.branch : 'MANIT Scholar',
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Management / Action Buttons
                  if (_isOwner) ...[
                    AppButton(
                      label: _team.isRecruiting ? 'Close Team Recruitment' : 'Reopen Team Recruitment',
                      icon: _team.isRecruiting ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                      variant: AppButtonVariant.primaryViolet,
                      isLoading: _isProcessingAction,
                      onPressed: _toggleRecruitment,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Delete Team Broadcast',
                      icon: Icons.delete_outline_rounded,
                      variant: AppButtonVariant.coralAction,
                      isLoading: _isProcessingAction,
                      onPressed: _confirmDelete,
                    ),
                  ] else if (_isMember) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccessSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You are an accepted member of this team roster.',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_userJoinRequest?.status == RequestStatus.pending) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.statusWarningSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.statusWarning.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pending_actions_rounded, color: AppColors.statusWarning, size: 22),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Application Pending Review',
                                  style: TextStyle(
                                    color: AppColors.statusWarning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.statusWarning.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                    color: AppColors.statusWarning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your pitch was submitted to ${_team.ownerName}. You will receive a campus notification once a decision is made.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          if (_userJoinRequest!.pitchNote.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.charcoalSurfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '"${_userJoinRequest!.pitchNote}"',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'Withdraw Application',
                            icon: Icons.undo_rounded,
                            variant: AppButtonVariant.secondaryOutline,
                            isLoading: _isWithdrawingJoin,
                            onPressed: _withdrawJoinRequest,
                          ),
                        ],
                      ),
                    ),
                  ] else if (_team.isRecruiting && !_team.isFull) ...[
                    AppButton(
                      label: 'Pitch & Request to Join',
                      icon: Icons.send_rounded,
                      variant: AppButtonVariant.primaryGradient,
                      onPressed: _showJoinRequestSheet,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.charcoalSurfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.charcoalBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'Recruitment for this team roster is currently closed.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String name;
  final String role;
  final bool isVerified;
  final String branch;

  const _MemberTile({
    required this.name,
    required this.role,
    required this.isVerified,
    required this.branch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.charcoalSurfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.charcoalBorder, width: 0.7),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.electricVioletSubtle,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'M',
              style: const TextStyle(color: AppColors.electricVioletGlow, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTypography.titleMedium.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 14, color: AppColors.statusSuccess),
                    ],
                  ],
                ),
                Text(
                  branch,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.charcoalSurfaceElevated,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              role,
              style: const TextStyle(fontSize: 11, color: AppColors.textLavender, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
