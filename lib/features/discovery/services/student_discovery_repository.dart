import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../profiles/domain/user_profile.dart';
import '../domain/discovery_filter.dart';

/// Result wrapper for paginated student discovery queries.
class StudentDiscoveryResult {
  final List<UserProfile> students;
  final bool hasMore;
  final int offset;
  final String? errorMessage;

  const StudentDiscoveryResult({
    required this.students,
    required this.hasMore,
    required this.offset,
    this.errorMessage,
  });

  const StudentDiscoveryResult.failure(String message, {this.offset = 0})
      : students = const [],
        hasMore = false,
        errorMessage = message;
}

/// Production repository for real student discovery powered by Supabase.
///
/// Features & Guarantees:
/// - Server-side filtering: name search, skills, interests, college category, verified status, branch, and academic year.
/// - Privacy: Queries public `discoverable_profiles` view with security_invoker = true, strictly omitting scholar_number and whatsapp_number.
/// - Scalable pagination: Incremental loading with `.range(offset, offset + limit - 1)`.
/// - Sort modes: Recently joined, Verified scholars first, Name (A to Z).
class StudentDiscoveryRepository {
  StudentDiscoveryRepository._();
  static final StudentDiscoveryRepository instance = StudentDiscoveryRepository._();

  SupabaseClient? _clientForTesting;

  @visibleForTesting
  set clientForTesting(SupabaseClient? client) {
    _clientForTesting = client;
  }

  SupabaseClient? get _client => _clientForTesting ?? SupabaseService.instance.client;

  /// Fetch a page of discoverable students with server-side filters and sorting.
  Future<StudentDiscoveryResult> fetchStudents({
    required DiscoveryFilter filter,
    int offset = 0,
    int limit = 12,
  }) async {
    final client = _client;
    if (client == null) {
      return const StudentDiscoveryResult.failure(
        'Supabase backend connection is not configured.',
      );
    }

    try {
      // 1. Build initial filter query on privacy-hardened discoverable_profiles view
      PostgrestFilterBuilder<List<Map<String, dynamic>>> filterBuilder = client
          .from('discoverable_profiles')
          .select(
            'id, display_name, avatar_url, college_name, membership_status, '
            'membership_verification_status, is_manit_verified, branch, academic_year, '
            'bio, skills, interests, portfolio_url, github_url, linkedin_url, created_at',
          );

      // 2. Search by display name
      if (filter.query.trim().isNotEmpty) {
        filterBuilder = filterBuilder.ilike('display_name', '%${filter.query.trim()}%');
      }

      // 3. Filter by college membership category
      if (filter.membershipCategory != null) {
        filterBuilder = filterBuilder.eq('membership_status', filter.membershipCategory!.name);
      } else if (filter.onlyManitStudents) {
        filterBuilder = filterBuilder.eq('membership_status', 'manitStudent');
      } else if (filter.onlyOtherCollegeStudents) {
        filterBuilder = filterBuilder.eq('membership_status', 'otherCollege');
      }

      // 4. Filter by verified MANIT status
      if (filter.onlyVerifiedManit) {
        filterBuilder = filterBuilder.eq('is_manit_verified', true);
      }

      // 5. Filter by branch / department
      if (filter.branch != null && filter.branch!.trim().isNotEmpty) {
        filterBuilder = filterBuilder.ilike('branch', '%${filter.branch!.trim()}%');
      }

      // 6. Filter by academic year
      if (filter.academicYear != null && filter.academicYear!.trim().isNotEmpty) {
        filterBuilder = filterBuilder.ilike('academic_year', '%${filter.academicYear!.trim()}%');
      }

      // 7. Filter by technical skills (PostgREST array contains)
      if (filter.skill != null && filter.skill!.trim().isNotEmpty) {
        filterBuilder = filterBuilder.contains('skills', [filter.skill!.trim()]);
      }

      // 8. Filter by interests (PostgREST array contains)
      if (filter.interest != null && filter.interest!.trim().isNotEmpty) {
        filterBuilder = filterBuilder.contains('interests', [filter.interest!.trim()]);
      }

      // 9. Sorting
      PostgrestTransformBuilder<List<Map<String, dynamic>>> transformBuilder;
      switch (filter.sortBy) {
        case ScholarSortBy.verifiedFirst:
          transformBuilder = filterBuilder
              .order('is_manit_verified', ascending: false)
              .order('created_at', ascending: false);
          break;
        case ScholarSortBy.nameAsc:
          transformBuilder = filterBuilder.order('display_name', ascending: true);
          break;
        case ScholarSortBy.newest:
          transformBuilder = filterBuilder.order('created_at', ascending: false);
          break;
      }

      // 10. Pagination via range
      final response = await transformBuilder.range(offset, offset + limit - 1);
      final List<dynamic> data = response as List<dynamic>;

      final students = data
          .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
          .toList();

      final hasMore = students.length >= limit;

      return StudentDiscoveryResult(
        students: students,
        hasMore: hasMore,
        offset: offset + students.length,
      );
    } on PostgrestException catch (e) {
      debugPrint('StudentDiscoveryRepository error: ${e.message}');
      return StudentDiscoveryResult.failure(
        'Failed to discover students: ${e.message}',
        offset: offset,
      );
    } catch (e) {
      debugPrint('StudentDiscoveryRepository unexpected error: $e');
      return StudentDiscoveryResult.failure(
        'An unexpected error occurred while loading students.',
        offset: offset,
      );
    }
  }
}
