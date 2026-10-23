import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/team.dart';

/// Result wrapper for Team repository operations.
class TeamResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  const TeamResult.success(this.data)
      : isSuccess = true,
        errorMessage = null;

  const TeamResult.failure(this.errorMessage)
      : isSuccess = false,
        data = null;
}

/// Central repository managing team lifecycles, searches, recruitment, and membership.
///
/// Features & Invariants:
/// - Only authenticated users can create teams; owner_id is derived from auth.uid().
/// - Automatic owner enrollment into team_members via database trigger.
/// - Only the team owner can edit, delete, or change recruitment status.
/// - Database-enforced capacity limits preventing concurrent over-enrollment.
class TeamRepository {
  TeamRepository._();
  static final TeamRepository instance = TeamRepository._();

  SupabaseClient? _clientForTesting;

  @visibleForTesting
  set clientForTesting(SupabaseClient? client) {
    _clientForTesting = client;
  }

  SupabaseClient? get _client => _clientForTesting ?? SupabaseService.instance.client;

  /// Create a new team with database-level ownership and auto-enrollment.
  Future<TeamResult<Team>> createTeam({
    required String title,
    required String description,
    required ProjectCategory category,
    required String eventName,
    required List<String> requiredSkills,
    required int maxTeamSize,
    String? whatsappGroupLink,
  }) async {
    final client = _client;
    if (client == null) {
      return const TeamResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const TeamResult.failure('Authentication required to create a team.');
    }

    try {
      final insertPayload = {
        'owner_id': user.id,
        'name': title.trim(),
        'description': description.trim(),
        'category': category.name,
        'event_name': eventName.trim(),
        'required_skills': requiredSkills.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'max_members': maxTeamSize.clamp(2, 30),
        'recruitment_status': 'open',
        'whatsapp_group_link': whatsappGroupLink?.trim().isEmpty ?? true ? null : whatsappGroupLink!.trim(),
      };

      final response = await client
          .from('teams')
          .insert(insertPayload)
          .select()
          .single();

      final createdTeam = Team.fromJson(response);
      return TeamResult.success(createdTeam);
    } on PostgrestException catch (e) {
      debugPrint('TeamRepository.createTeam error: ${e.message}');
      return TeamResult.failure(e.message);
    } catch (e) {
      debugPrint('TeamRepository.createTeam unexpected error: $e');
      return const TeamResult.failure('Failed to create team. Please try again.');
    }
  }

  /// Edit team details. Only permitted for the team owner.
  Future<TeamResult<Team>> updateTeam({
    required String teamId,
    required String title,
    required String description,
    required ProjectCategory category,
    required String eventName,
    required List<String> requiredSkills,
    required int maxTeamSize,
    required bool isRecruiting,
    String? whatsappGroupLink,
  }) async {
    final client = _client;
    if (client == null) {
      return const TeamResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const TeamResult.failure('Authentication required.');
    }

    try {
      final updatePayload = {
        'name': title.trim(),
        'description': description.trim(),
        'category': category.name,
        'event_name': eventName.trim(),
        'required_skills': requiredSkills.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'max_members': maxTeamSize.clamp(2, 30),
        'recruitment_status': isRecruiting ? 'open' : 'closed',
        'whatsapp_group_link': whatsappGroupLink?.trim().isEmpty ?? true ? null : whatsappGroupLink!.trim(),
      };

      final response = await client
          .from('teams')
          .update(updatePayload)
          .eq('id', teamId)
          .eq('owner_id', user.id) // Authorization: caller must be owner
          .select()
          .single();

      final updatedTeam = Team.fromJson(response);
      return TeamResult.success(updatedTeam);
    } on PostgrestException catch (e) {
      debugPrint('TeamRepository.updateTeam error: ${e.message}');
      return TeamResult.failure(e.message);
    } catch (e) {
      return const TeamResult.failure('Failed to update team details.');
    }
  }

  /// Delete a team. Restricted to authorized team owner.
  Future<TeamResult<void>> deleteTeam(String teamId) async {
    final client = _client;
    if (client == null) {
      return const TeamResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const TeamResult.failure('Authentication required.');
    }

    try {
      await client
          .from('teams')
          .delete()
          .eq('id', teamId)
          .eq('owner_id', user.id); // Authorization constraint

      return const TeamResult.success(null);
    } on PostgrestException catch (e) {
      return TeamResult.failure(e.message);
    } catch (e) {
      return const TeamResult.failure('Failed to delete team.');
    }
  }

  /// Toggle or update recruitment status for a team.
  Future<TeamResult<void>> setRecruitmentStatus({
    required String teamId,
    required bool isOpen,
  }) async {
    final client = _client;
    if (client == null) {
      return const TeamResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const TeamResult.failure('Authentication required.');
    }

    try {
      await client
          .from('teams')
          .update({'recruitment_status': isOpen ? 'open' : 'closed'})
          .eq('id', teamId)
          .eq('owner_id', user.id);

      return const TeamResult.success(null);
    } on PostgrestException catch (e) {
      return TeamResult.failure(e.message);
    } catch (e) {
      return const TeamResult.failure('Failed to update recruitment status.');
    }
  }

  /// Fetch a single team with its accepted members and owner details.
  Future<TeamResult<Team>> fetchTeamDetails(String teamId) async {
    final client = _client;
    if (client == null) {
      return const TeamResult.failure('Backend connection is not configured.');
    }

    try {
      // 1. Fetch team record
      final teamRes = await client
          .from('teams')
          .select()
          .eq('id', teamId)
          .maybeSingle();

      if (teamRes == null) {
        return const TeamResult.failure('Team not found or removed.');
      }

      // 2. Fetch accepted members for this team with profile attributes
      final membersRes = await client
          .from('team_members')
          .select('id, user_id, role, joined_at, profiles(id, display_name, avatar_url, branch, academic_year, membership_status, membership_verification_status)')
          .eq('team_id', teamId);

      final List<TeamMember> members = (membersRes as List<dynamic>)
          .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
          .toList();

      final baseTeam = Team.fromJson(teamRes);
      final fullTeam = baseTeam.copyWith(members: members);

      return TeamResult.success(fullTeam);
    } on PostgrestException catch (e) {
      return TeamResult.failure(e.message);
    } catch (e) {
      return const TeamResult.failure('An unexpected error occurred while fetching team.');
    }
  }

  /// Browse and filter teams with server-side query filters.
  Future<TeamResult<List<Team>>> fetchTeams({
    String? query,
    ProjectCategory? category,
    String? skill,
    String? eventName,
    bool? onlyOpen,
    int limit = 20,
    int offset = 0,
  }) async {
    final client = _client;
    if (client == null) {
      return const TeamResult.failure('Backend connection is not configured.');
    }

    try {
      var filterBuilder = client.from('teams').select();

      if (onlyOpen == true) {
        filterBuilder = filterBuilder.eq('recruitment_status', 'open');
      }

      if (category != null) {
        filterBuilder = filterBuilder.eq('category', category.name);
      }

      if (eventName != null && eventName.trim().isNotEmpty) {
        filterBuilder = filterBuilder.ilike('event_name', '%${eventName.trim()}%');
      }

      if (skill != null && skill.trim().isNotEmpty) {
        filterBuilder = filterBuilder.contains('required_skills', [skill.trim()]);
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim();
        filterBuilder = filterBuilder.or('name.ilike.%$q%,description.ilike.%$q%,event_name.ilike.%$q%');
      }

      final transformBuilder = filterBuilder.order('created_at', ascending: false);
      final response = await transformBuilder.range(offset, offset + limit - 1);

      final List<Team> teams = (response as List<dynamic>)
          .map((item) => Team.fromJson(item as Map<String, dynamic>))
          .toList();

      return TeamResult.success(teams);
    } on PostgrestException catch (e) {
      debugPrint('TeamRepository.fetchTeams error: ${e.message}');
      return TeamResult.failure(e.message);
    } catch (e) {
      return const TeamResult.failure('An error occurred while discovering teams.');
    }
  }

  /// Fetch teams created by the current authenticated user.
  Future<TeamResult<List<Team>>> fetchMyCreatedTeams() async {
    final client = _client;
    if (client == null) {
      return const TeamResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const TeamResult.failure('Authentication required.');
    }

    try {
      final response = await client
          .from('teams')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      final List<Team> teams = (response as List<dynamic>)
          .map((item) => Team.fromJson(item as Map<String, dynamic>))
          .toList();

      return TeamResult.success(teams);
    } on PostgrestException catch (e) {
      return TeamResult.failure(e.message);
    } catch (e) {
      return const TeamResult.failure('Failed to load your created teams.');
    }
  }

  /// Fetch teams where current user is an accepted member (non-owner).
  Future<TeamResult<List<Team>>> fetchMyJoinedTeams() async {
    final client = _client;
    if (client == null) {
      return const TeamResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const TeamResult.failure('Authentication required.');
    }

    try {
      final memberRows = await client
          .from('team_members')
          .select('team_id, role, teams(*)')
          .eq('user_id', user.id)
          .neq('role', 'owner');

      final List<Team> teams = [];
      for (final row in (memberRows as List<dynamic>)) {
        final teamData = row['teams'] as Map<String, dynamic>?;
        if (teamData != null) {
          teams.add(Team.fromJson(teamData));
        }
      }

      return TeamResult.success(teams);
    } on PostgrestException catch (e) {
      return TeamResult.failure(e.message);
    } catch (e) {
      return const TeamResult.failure('Failed to load joined rosters.');
    }
  }
}
