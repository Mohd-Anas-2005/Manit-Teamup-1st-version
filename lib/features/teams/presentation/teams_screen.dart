import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/manit_badge.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/team.dart';
import '../services/team_repository.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';

class TeamsScreen extends StatefulWidget {
  final VoidCallback? onOpenCreateTeam;

  const TeamsScreen({super.key, this.onOpenCreateTeam});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Team> _myCreatedTeams = [];
  List<Team> _myJoinedTeams = [];
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
    _loadTeams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) {
      setState(() {
        _myCreatedTeams = [];
        _myJoinedTeams = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final createdRes = await TeamRepository.instance.fetchMyCreatedTeams();
    final joinedRes = await TeamRepository.instance.fetchMyJoinedTeams();

    if (!mounted) return;

    if (createdRes.errorMessage != null && joinedRes.errorMessage != null) {
      setState(() {
        _errorMessage = createdRes.errorMessage;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _myCreatedTeams = createdRes.data ?? [];
      _myJoinedTeams = joinedRes.data ?? [];
      _isLoading = false;
    });
  }

  void _navigateToCreateTeam() {
    if (widget.onOpenCreateTeam != null) {
      widget.onOpenCreateTeam!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateTeamScreen(onCreated: _loadTeams),
        ),
      );
    }
  }

  void _openTeamDetails(Team team) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamDetailScreen(
          team: team,
          onTeamModified: _loadTeams,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          color: AppColors.midnightNavyDeep,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.electricVioletLight,
            indicatorWeight: 3,
            labelColor: AppColors.electricVioletGlow,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'My Created Teams'),
              Tab(text: 'Joined Rosters'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                CardSkeleton(height: 150),
                CardSkeleton(height: 150),
                CardSkeleton(height: 150),
              ],
            )
          : _errorMessage != null
              ? ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _loadTeams,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTeamList(_myCreatedTeams, isOwnerTab: true),
                    _buildTeamList(_myJoinedTeams, isOwnerTab: false),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.electricViolet,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('New Team'),
        onPressed: _navigateToCreateTeam,
      ),
    );
  }

  Widget _buildTeamList(List<Team> teams, {required bool isOwnerTab}) {
    if (teams.isEmpty) {
      return EmptyStateView(
        icon: isOwnerTab ? Icons.groups_outlined : Icons.handshake_outlined,
        title: isOwnerTab ? 'No Teams Launched Yet' : 'No Joined Teams Yet',
        message: isOwnerTab
            ? 'Broadcast a team roster to discover top campus teammates.'
            : 'Explore open broadcasts in the Discovery tab and pitch your skills to team leads!',
        actionLabel: isOwnerTab ? 'Launch a Team' : null,
        onAction: isOwnerTab ? _navigateToCreateTeam : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeams,
      color: AppColors.electricVioletLight,
      backgroundColor: AppColors.charcoalSurfaceElevated,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return StaggeredEntrance(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _openTeamDetails(team),
                borderRadius: BorderRadius.circular(16),
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
                              Text(team.title, style: AppTypography.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                team.eventName,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.cyanLight),
                              ),
                            ],
                          ),
                        ),
                        if (team.isRecruiting && team.vacanciesLeft > 0)
                          ManitBadge.vacancies(team.vacanciesLeft)
                        else
                          const ManitBadge(
                            label: 'Roster Full',
                            variant: ManitBadgeVariant.openVacancies,
                            icon: Icons.lock_outline_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      team.description,
                      style: AppTypography.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.charcoalSurfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            team.projectCategory.displayName,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isOwnerTab ? 'Manage Roster' : 'View Details',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.electricVioletLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.electricVioletLight),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }
}
