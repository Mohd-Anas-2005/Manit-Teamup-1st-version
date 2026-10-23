import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/join_request.dart';

/// Result wrapper for JoinRequest repository operations.
class JoinRequestResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  const JoinRequestResult.success(this.data)
      : isSuccess = true,
        errorMessage = null;

  const JoinRequestResult.failure(this.errorMessage)
      : isSuccess = false,
        data = null;
}

/// Central repository managing team joining requests, submissions,
/// owner reviews (acceptance/rejection), requester withdrawals, and status checks.
class JoinRequestRepository {
  JoinRequestRepository._();
  static final JoinRequestRepository instance = JoinRequestRepository._();

  SupabaseClient? _clientForTesting;

  @visibleForTesting
  set clientForTesting(SupabaseClient? client) {
    _clientForTesting = client;
  }

  SupabaseClient? get _client => _clientForTesting ?? SupabaseService.instance.client;

  /// Submit a joining request to an open recruiting team with an optional pitch note.
  Future<JoinRequestResult<JoinRequest>> submitJoinRequest({
    required String teamId,
    String? message,
  }) async {
    final client = _client;
    if (client == null) {
      return const JoinRequestResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const JoinRequestResult.failure('Authentication required to submit a join request.');
    }

    try {
      final cleanMessage = (message ?? '').trim();

      // Attempt using the security-definer RPC
      try {
        final rpcResult = await client.rpc(
          'submit_join_request',
          params: {
            'p_team_id': teamId,
            'p_message': cleanMessage,
          },
        );

        if (rpcResult is Map<String, dynamic> && rpcResult['success'] == true) {
          final requestId = rpcResult['request_id'] as String? ?? '';
          return JoinRequestResult.success(
            JoinRequest(
              id: requestId,
              teamId: teamId,
              teamTitle: '',
              applicantId: user.id,
              applicantName: user.userMetadata?['display_name'] as String? ?? 'Me',
              applicantBranch: '',
              applicantYear: '',
              pitchNote: cleanMessage,
              status: RequestStatus.pending,
              createdAt: DateTime.now(),
            ),
          );
        }
      } catch (rpcError) {
        // If RPC throws an application exception (e.g. capacity reached, team closed, duplicate),
        // rethrow or propagate its message
        final errorStr = rpcError.toString();
        if (errorStr.contains('Team owner cannot submit') ||
            errorStr.contains('already an enrolled member') ||
            errorStr.contains('reached maximum capacity') ||
            errorStr.contains('not currently open for recruitment') ||
            errorStr.contains('duplicate key value') ||
            errorStr.contains('idx_unique_active_join_request')) {
          if (errorStr.contains('idx_unique_active_join_request') || errorStr.contains('duplicate')) {
            return const JoinRequestResult.failure('You already have an active pending request for this team.');
          }
          return JoinRequestResult.failure(_extractErrorMessage(errorStr));
        }

        // Direct table insert fallback governed by RLS
        final response = await client
            .from('join_requests')
            .insert({
              'team_id': teamId,
              'requester_id': user.id,
              'message': cleanMessage,
              'status': 'pending',
            })
            .select()
            .single();

        return JoinRequestResult.success(JoinRequest.fromJson(response));
      }

      return const JoinRequestResult.failure('Failed to submit join request.');
    } on PostgrestException catch (e) {
      debugPrint('JoinRequestRepository.submitJoinRequest PostgrestException: ${e.message}');
      if (e.message.contains('idx_unique_active_join_request') || e.code == '23505') {
        return const JoinRequestResult.failure('You already have an active pending request for this team.');
      }
      return JoinRequestResult.failure(e.message);
    } catch (e) {
      debugPrint('JoinRequestRepository.submitJoinRequest unexpected error: $e');
      return JoinRequestResult.failure(_extractErrorMessage(e.toString()));
    }
  }

  /// Fetch incoming join requests for all teams owned by the current authenticated user.
  Future<JoinRequestResult<List<JoinRequest>>> fetchIncomingRequests() async {
    final client = _client;
    if (client == null) {
      return const JoinRequestResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const JoinRequestResult.failure('Authentication required to view incoming requests.');
    }

    try {
      // First attempt using secure query RPC
      try {
        final rpcResult = await client.rpc('get_incoming_join_requests');
        if (rpcResult is List<dynamic>) {
          final requests = rpcResult
              .map((item) => JoinRequest.fromJson(item as Map<String, dynamic>))
              .toList();
          return JoinRequestResult.success(requests);
        }
      } catch (_) {
        // Fallback to table query with joins
      }

      final myTeams = await client
          .from('teams')
          .select('id, name')
          .eq('owner_id', user.id);

      final myTeamMap = {
        for (final t in (myTeams as List<dynamic>))
          (t['id'] as String): (t['name'] as String? ?? 'Team')
      };

      if (myTeamMap.isEmpty) {
        return const JoinRequestResult.success([]);
      }

      final teamIds = myTeamMap.keys.toList();
      final response = await client
          .from('join_requests')
          .select('*, profiles:requester_id(*)')
          .filter('team_id', 'in', teamIds)
          .order('created_at', ascending: false);

      final List<JoinRequest> list = [];
      for (final item in (response as List<dynamic>)) {
        final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
        final tId = map['team_id'] as String? ?? '';
        map['team_title'] = myTeamMap[tId] ?? '';
        list.add(JoinRequest.fromJson(map));
      }

      return JoinRequestResult.success(list);
    } on PostgrestException catch (e) {
      debugPrint('JoinRequestRepository.fetchIncomingRequests error: ${e.message}');
      return JoinRequestResult.failure(e.message);
    } catch (e) {
      debugPrint('JoinRequestRepository.fetchIncomingRequests unexpected: $e');
      return const JoinRequestResult.failure('Failed to load incoming requests.');
    }
  }

  /// Fetch requests submitted by the current authenticated user.
  Future<JoinRequestResult<List<JoinRequest>>> fetchSentRequests() async {
    final client = _client;
    if (client == null) {
      return const JoinRequestResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const JoinRequestResult.failure('Authentication required to view sent requests.');
    }

    try {
      // First attempt using secure query RPC
      try {
        final rpcResult = await client.rpc('get_sent_join_requests');
        if (rpcResult is List<dynamic>) {
          final requests = rpcResult
              .map((item) => JoinRequest.fromJson(item as Map<String, dynamic>))
              .toList();
          return JoinRequestResult.success(requests);
        }
      } catch (_) {
        // Fallback to table query with joins
      }

      final response = await client
          .from('join_requests')
          .select('*, teams(id, name), profiles:requester_id(*)')
          .eq('requester_id', user.id)
          .order('created_at', ascending: false);

      final List<JoinRequest> list = (response as List<dynamic>)
          .map((item) => JoinRequest.fromJson(item as Map<String, dynamic>))
          .toList();

      return JoinRequestResult.success(list);
    } on PostgrestException catch (e) {
      debugPrint('JoinRequestRepository.fetchSentRequests error: ${e.message}');
      return JoinRequestResult.failure(e.message);
    } catch (e) {
      debugPrint('JoinRequestRepository.fetchSentRequests unexpected: $e');
      return const JoinRequestResult.failure('Failed to load your sent applications.');
    }
  }

  /// Fetch the active or most recent join request for a specific team by the current user.
  Future<JoinRequestResult<JoinRequest?>> fetchUserRequestForTeam(String teamId) async {
    final client = _client;
    if (client == null) {
      return const JoinRequestResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const JoinRequestResult.success(null);
    }

    try {
      final response = await client
          .from('join_requests')
          .select()
          .eq('team_id', teamId)
          .eq('requester_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);

      final list = response as List<dynamic>;
      if (list.isEmpty) {
        return const JoinRequestResult.success(null);
      }

      return JoinRequestResult.success(JoinRequest.fromJson(list.first as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      debugPrint('JoinRequestRepository.fetchUserRequestForTeam error: ${e.message}');
      return JoinRequestResult.failure(e.message);
    } catch (e) {
      debugPrint('JoinRequestRepository.fetchUserRequestForTeam unexpected: $e');
      return const JoinRequestResult.failure('Failed to check application status.');
    }
  }

  /// Concurrency-safe acceptance of a pending join request by the team owner.
  Future<JoinRequestResult<Map<String, dynamic>>> acceptJoinRequest(String requestId) async {
    final client = _client;
    if (client == null) {
      return const JoinRequestResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const JoinRequestResult.failure('Authentication required to accept requests.');
    }

    try {
      final response = await client.rpc(
        'accept_join_request',
        params: {'p_request_id': requestId},
      );

      final map = (response is Map<String, dynamic>)
          ? response
          : <String, dynamic>{'success': true};

      return JoinRequestResult.success(map);
    } on PostgrestException catch (e) {
      debugPrint('JoinRequestRepository.acceptJoinRequest error: ${e.message}');
      return JoinRequestResult.failure(e.message);
    } catch (e) {
      debugPrint('JoinRequestRepository.acceptJoinRequest unexpected: $e');
      return JoinRequestResult.failure(_extractErrorMessage(e.toString()));
    }
  }

  /// Authorized rejection of a pending join request by the team owner.
  Future<JoinRequestResult<Map<String, dynamic>>> rejectJoinRequest(String requestId) async {
    final client = _client;
    if (client == null) {
      return const JoinRequestResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const JoinRequestResult.failure('Authentication required to decline requests.');
    }

    try {
      final response = await client.rpc(
        'reject_join_request',
        params: {'p_request_id': requestId},
      );

      final map = (response is Map<String, dynamic>)
          ? response
          : <String, dynamic>{'success': true, 'status': 'rejected'};

      return JoinRequestResult.success(map);
    } on PostgrestException catch (e) {
      debugPrint('JoinRequestRepository.rejectJoinRequest error: ${e.message}');
      return JoinRequestResult.failure(e.message);
    } catch (e) {
      debugPrint('JoinRequestRepository.rejectJoinRequest unexpected: $e');
      return JoinRequestResult.failure(_extractErrorMessage(e.toString()));
    }
  }

  /// Authorized withdrawal of a pending join request by the requester.
  Future<JoinRequestResult<Map<String, dynamic>>> withdrawJoinRequest(String requestId) async {
    final client = _client;
    if (client == null) {
      return const JoinRequestResult.failure('Backend connection is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const JoinRequestResult.failure('Authentication required to withdraw requests.');
    }

    try {
      final response = await client.rpc(
        'withdraw_join_request',
        params: {'p_request_id': requestId},
      );

      final map = (response is Map<String, dynamic>)
          ? response
          : <String, dynamic>{'success': true, 'status': 'withdrawn'};

      return JoinRequestResult.success(map);
    } on PostgrestException catch (e) {
      debugPrint('JoinRequestRepository.withdrawJoinRequest error: ${e.message}');
      return JoinRequestResult.failure(e.message);
    } catch (e) {
      debugPrint('JoinRequestRepository.withdrawJoinRequest unexpected: $e');
      return JoinRequestResult.failure(_extractErrorMessage(e.toString()));
    }
  }

  String _extractErrorMessage(String error) {
    if (error.contains('Exception: ')) {
      return error.split('Exception: ').last.split('\n').first;
    }
    return error;
  }
}
