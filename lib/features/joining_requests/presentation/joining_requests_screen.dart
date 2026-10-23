import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/manit_badge.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/join_request.dart';
import '../services/join_request_repository.dart';

class JoiningRequestsScreen extends StatefulWidget {
  const JoiningRequestsScreen({super.key});

  @override
  State<JoiningRequestsScreen> createState() => _JoiningRequestsScreenState();
}

class _JoiningRequestsScreenState extends State<JoiningRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<JoinRequest> _incomingRequests = [];
  final List<JoinRequest> _sentRequests = [];
  final Set<String> _processingActionIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      }
    });
    _loadAllRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRequests() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || supabase.client == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final incomingRes = await JoinRequestRepository.instance.fetchIncomingRequests();
    final sentRes = await JoinRequestRepository.instance.fetchSentRequests();

    if (!mounted) return;

    if (!incomingRes.isSuccess && !sentRes.isSuccess) {
      setState(() {
        _isLoading = false;
        _errorMessage = incomingRes.errorMessage ?? sentRes.errorMessage ?? 'Failed to load requests.';
      });
      return;
    }

    setState(() {
      if (incomingRes.isSuccess && incomingRes.data != null) {
        _incomingRequests
          ..clear()
          ..addAll(incomingRes.data!);
      }
      if (sentRes.isSuccess && sentRes.data != null) {
        _sentRequests
          ..clear()
          ..addAll(sentRes.data!);
      }
      _isLoading = false;
    });
  }

  Future<void> _handleAccept(JoinRequest request) async {
    setState(() => _processingActionIds.add(request.id));

    final res = await JoinRequestRepository.instance.acceptJoinRequest(request.id);
    if (!mounted) return;

    setState(() => _processingActionIds.remove(request.id));

    if (res.isSuccess) {
      // Immediate UI update after confirmed backend success
      setState(() {
        final index = _incomingRequests.indexWhere((r) => r.id == request.id);
        if (index != -1) {
          _incomingRequests[index] = request.copyWith(status: RequestStatus.accepted);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Accepted ${request.applicantName}! Member added to team roster.'),
              ),
            ],
          ),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Failed to accept request.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _handleReject(JoinRequest request) async {
    setState(() => _processingActionIds.add(request.id));

    final res = await JoinRequestRepository.instance.rejectJoinRequest(request.id);
    if (!mounted) return;

    setState(() => _processingActionIds.remove(request.id));

    if (res.isSuccess) {
      // Immediate UI update after confirmed backend success
      setState(() {
        final index = _incomingRequests.indexWhere((r) => r.id == request.id);
        if (index != -1) {
          _incomingRequests[index] = request.copyWith(status: RequestStatus.rejected);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join request declined.'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Failed to decline request.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _handleWithdraw(JoinRequest request) async {
    setState(() => _processingActionIds.add(request.id));

    final res = await JoinRequestRepository.instance.withdrawJoinRequest(request.id);
    if (!mounted) return;

    setState(() => _processingActionIds.remove(request.id));

    if (res.isSuccess) {
      // Immediate UI update after confirmed backend success
      setState(() {
        final index = _sentRequests.indexWhere((r) => r.id == request.id);
        if (index != -1) {
          _sentRequests[index] = request.copyWith(status: RequestStatus.withdrawn);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application withdrawn successfully.'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Failed to withdraw application.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.midnightNavyDeep,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.electricVioletLight,
            indicatorWeight: 3,
            labelColor: AppColors.electricVioletGlow,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Incoming (${_incomingRequests.where((r) => r.status == RequestStatus.pending).length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.outbox_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Sent (${_sentRequests.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList(_incomingRequests, isIncoming: true),
          _buildRequestList(_sentRequests, isIncoming: false),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<JoinRequest> requests, {required bool isIncoming}) {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          CardSkeleton(height: 180),
          CardSkeleton(height: 180),
          CardSkeleton(height: 180),
        ],
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _loadAllRequests,
      );
    }

    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAllRequests,
        color: AppColors.electricVioletLight,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyStateView(
              icon: isIncoming ? Icons.mark_email_read_outlined : Icons.swap_horiz_rounded,
              title: isIncoming ? 'No Incoming Requests' : 'No Applications Sent',
              message: isIncoming
                  ? 'When peers apply to join your teams, their profiles, skill tags, and pitches will appear here.'
                  : 'You haven’t submitted joining requests yet. Find open hackathons on Discovery to apply.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllRequests,
      color: AppColors.electricVioletLight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final req = requests[index];
          final isProcessing = _processingActionIds.contains(req.id);

          return StaggeredEntrance(
            index: index,
            child: GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Team Title & Status Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        req.teamTitle.isNotEmpty ? req.teamTitle : 'Team Roster',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(req.status),
                  ],
                ),
                const SizedBox(height: 10),

                // Applicant / Team Info Tile
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.midnightNavyDeep.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.charcoalBorder.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.electricVioletSubtle,
                        child: Text(
                          (isIncoming ? req.applicantName : req.teamTitle).isNotEmpty
                              ? (isIncoming ? req.applicantName : req.teamTitle)[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.electricVioletGlow,
                          ),
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
                                    isIncoming ? req.applicantName : 'Applicant: You',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (req.applicantIsManitVerified) ...[
                                  const SizedBox(width: 6),
                                  ManitBadge.verified(),
                                ],
                              ],
                            ),
                            if (isIncoming && (req.applicantBranch.isNotEmpty || req.applicantYear.isNotEmpty)) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${req.applicantBranch} • ${req.applicantYear}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Pitch Message / Introduction
                if (req.pitchNote.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.charcoalSurfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pitch: "${req.pitchNote}"',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                // Skills tags if available
                if (req.applicantSkills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: req.applicantSkills.take(4).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyanSubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(color: AppColors.cyanLight, fontSize: 10),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Action Buttons for Incoming Pending Requests (Owner Acceptance/Rejection)
                if (isIncoming && req.status == RequestStatus.pending) ...[
                  const SizedBox(height: 14),
                  if (isProcessing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.electricVioletLight,
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.coralLight,
                            side: const BorderSide(color: AppColors.coralAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () => _handleReject(req),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusSuccess,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Accept Teammate'),
                          onPressed: () => _handleAccept(req),
                        ),
                      ],
                    ),
                ],

                // Action Buttons for Sent Pending Requests (Requester Withdrawal)
                if (!isIncoming && req.status == RequestStatus.pending) ...[
                  const SizedBox(height: 14),
                  if (isProcessing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.coralAccent,
                          ),
                        ),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coralLight,
                          side: BorderSide(color: AppColors.coralAccent.withValues(alpha: 0.6)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.undo_rounded, size: 15),
                        label: const Text('Withdraw Application'),
                        onPressed: () => _handleWithdraw(req),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildStatusChip(RequestStatus status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case RequestStatus.pending:
        bg = AppColors.statusWarningSubtle;
        fg = AppColors.statusWarning;
        icon = Icons.access_time_rounded;
        break;
      case RequestStatus.accepted:
        bg = AppColors.statusSuccessSubtle;
        fg = AppColors.statusSuccess;
        icon = Icons.check_circle_outline_rounded;
        break;
      case RequestStatus.rejected:
        bg = AppColors.coralSubtle;
        fg = AppColors.coralLight;
        icon = Icons.cancel_outlined;
        break;
      case RequestStatus.withdrawn:
        bg = AppColors.charcoalSurfaceVariant;
        fg = AppColors.textSecondary;
        icon = Icons.undo_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}
