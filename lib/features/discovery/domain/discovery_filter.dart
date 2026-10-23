import '../../profiles/domain/user_profile.dart';
import '../../teams/domain/team.dart';

/// Available sorting modes for scholar discovery.
enum ScholarSortBy {
  newest,
  verifiedFirst,
  nameAsc,
}

extension ScholarSortByX on ScholarSortBy {
  String get label {
    switch (this) {
      case ScholarSortBy.newest:
        return 'Recently Joined';
      case ScholarSortBy.verifiedFirst:
        return 'Verified Scholars First';
      case ScholarSortBy.nameAsc:
        return 'Name (A to Z)';
    }
  }
}

/// Comprehensive filter model supporting team broadcasts and scholar discovery.
class DiscoveryFilter {
  final String query;
  final ProjectCategory? category;
  final MembershipStatus? membershipCategory;
  final bool onlyManitStudents;
  final bool onlyVerifiedManit;
  final bool onlyOtherCollegeStudents;
  final String? branch;
  final String? academicYear;
  final String? skill;
  final String? interest;
  final String? eventName;
  final ScholarSortBy sortBy;
  final bool onlyRecruiting;

  const DiscoveryFilter({
    this.query = '',
    this.category,
    this.membershipCategory,
    this.onlyManitStudents = false,
    this.onlyVerifiedManit = false,
    this.onlyOtherCollegeStudents = false,
    this.branch,
    this.academicYear,
    this.skill,
    this.interest,
    this.eventName,
    this.sortBy = ScholarSortBy.newest,
    this.onlyRecruiting = true,
  });

  DiscoveryFilter copyWith({
    String? query,
    ProjectCategory? category,
    MembershipStatus? membershipCategory,
    bool? onlyManitStudents,
    bool? onlyVerifiedManit,
    bool? onlyOtherCollegeStudents,
    String? branch,
    String? academicYear,
    String? skill,
    String? interest,
    String? eventName,
    ScholarSortBy? sortBy,
    bool? onlyRecruiting,
  }) {
    return DiscoveryFilter(
      query: query ?? this.query,
      category: category ?? this.category,
      membershipCategory: membershipCategory ?? this.membershipCategory,
      onlyManitStudents: onlyManitStudents ?? this.onlyManitStudents,
      onlyVerifiedManit: onlyVerifiedManit ?? this.onlyVerifiedManit,
      onlyOtherCollegeStudents: onlyOtherCollegeStudents ?? this.onlyOtherCollegeStudents,
      branch: branch ?? this.branch,
      academicYear: academicYear ?? this.academicYear,
      skill: skill ?? this.skill,
      interest: interest ?? this.interest,
      eventName: eventName ?? this.eventName,
      sortBy: sortBy ?? this.sortBy,
      onlyRecruiting: onlyRecruiting ?? this.onlyRecruiting,
    );
  }

  bool get hasActiveFilters =>
      category != null ||
      membershipCategory != null ||
      onlyManitStudents ||
      onlyVerifiedManit ||
      onlyOtherCollegeStudents ||
      (branch != null && branch!.isNotEmpty) ||
      (academicYear != null && academicYear!.isNotEmpty) ||
      (skill != null && skill!.isNotEmpty) ||
      (interest != null && interest!.isNotEmpty) ||
      (eventName != null && eventName!.isNotEmpty) ||
      sortBy != ScholarSortBy.newest ||
      !onlyRecruiting ||
      query.isNotEmpty;

  /// Check whether a UserProfile matches the active filter criteria.
  /// Enforces privacy: never relies on or inspects student IDs or personal contacts.
  bool matchesProfile(UserProfile profile) {
    if (onlyVerifiedManit && !profile.isManitVerified) {
      return false;
    }

    if (onlyManitStudents && profile.membershipStatus != MembershipStatus.manitStudent) {
      return false;
    }

    if (onlyOtherCollegeStudents && profile.membershipStatus != MembershipStatus.otherCollege) {
      return false;
    }

    if (membershipCategory != null && profile.membershipStatus != membershipCategory) {
      return false;
    }

    if (branch != null && branch!.isNotEmpty &&
        !profile.branch.toLowerCase().contains(branch!.toLowerCase())) {
      return false;
    }

    if (academicYear != null && academicYear!.isNotEmpty &&
        !profile.academicYear.toLowerCase().contains(academicYear!.toLowerCase())) {
      return false;
    }

    if (skill != null && skill!.isNotEmpty) {
      final targetSkill = skill!.toLowerCase();
      final hasSkill = profile.skills.any((s) => s.toLowerCase().contains(targetSkill));
      if (!hasSkill) return false;
    }

    if (interest != null && interest!.isNotEmpty) {
      final targetInterest = interest!.toLowerCase();
      final hasInterest = profile.interests.any((i) => i.toLowerCase().contains(targetInterest));
      if (!hasInterest) return false;
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      final matchName = profile.fullName.toLowerCase().contains(q);
      final matchCollege = profile.collegeName.toLowerCase().contains(q);
      final matchBranch = profile.branch.toLowerCase().contains(q);
      final matchBio = profile.bio.toLowerCase().contains(q);
      final matchSkill = profile.skills.any((s) => s.toLowerCase().contains(q));
      final matchInterest = profile.interests.any((i) => i.toLowerCase().contains(q));

      if (!matchName && !matchCollege && !matchBranch && !matchBio && !matchSkill && !matchInterest) {
        return false;
      }
    }

    return true;
  }
}
