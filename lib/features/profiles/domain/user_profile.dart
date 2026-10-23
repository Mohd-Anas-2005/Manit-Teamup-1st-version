/// College membership categories required by MANIT TeamUp.
enum MembershipStatus {
  manitStudent('MANIT Student'),
  otherCollege('Student (Other College)'),
  nonStudent('Not a Student');

  final String displayName;
  const MembershipStatus(this.displayName);

  static MembershipStatus? fromString(String? val) {
    if (val == null || val.isEmpty) return null;
    return MembershipStatus.values.firstWhere(
      (m) => m.name == val,
      orElse: () => MembershipStatus.manitStudent,
    );
  }
}

/// Verification status for MANIT students.
enum VerificationStatus {
  unverified('Unverified'),
  pendingReview('Pending Review'),
  verified('Verified'),
  rejected('Rejected');

  final String displayName;
  const VerificationStatus(this.displayName);

  static VerificationStatus fromString(String? val) {
    switch (val) {
      case 'verified':
        return VerificationStatus.verified;
      case 'pending':
      case 'pending_review':
        return VerificationStatus.pendingReview;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'unverified':
      default:
        return VerificationStatus.unverified;
    }
  }

  String toDbValue() {
    switch (this) {
      case VerificationStatus.verified:
        return 'verified';
      case VerificationStatus.pendingReview:
        return 'pending_review';
      case VerificationStatus.rejected:
        return 'rejected';
      case VerificationStatus.unverified:
        return 'unverified';
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String collegeName;
  final MembershipStatus? membershipStatus;
  final VerificationStatus verificationStatus;
  final String? scholarNumber;
  final String branch;
  final String academicYear;
  final String bio;
  final List<String> skills;
  final List<String> interests;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? portfolioUrl;
  final String? whatsappNumber;
  final bool isProfilePublic;
  final bool allowWhatsAppDirect;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.collegeName = 'MANIT Bhopal',
    this.membershipStatus = MembershipStatus.manitStudent,
    this.verificationStatus = VerificationStatus.unverified,
    this.scholarNumber,
    this.branch = 'Computer Science & Engineering',
    this.academicYear = '1st Year B.Tech',
    this.bio = '',
    this.skills = const [],
    this.interests = const [],
    this.githubUrl,
    this.linkedinUrl,
    this.portfolioUrl,
    this.whatsappNumber,
    this.isProfilePublic = true,
    this.allowWhatsAppDirect = true,
  });

  /// Computed: True ONLY if user is a MANIT student AND has verified verification status.
  bool get isManitVerified =>
      membershipStatus == MembershipStatus.manitStudent &&
      verificationStatus == VerificationStatus.verified;

  /// Computed: Verification is currently under review by authorities.
  bool get isVerificationPending =>
      membershipStatus == MembershipStatus.manitStudent &&
      verificationStatus == VerificationStatus.pendingReview;

  /// Formatted profile display badge/label according to specifications:
  /// - MANIT Verified badge only for verified MANIT students.
  /// - "MANIT Student — Unverified" for self-declared unverified MANIT students.
  /// - Other college name for students elsewhere.
  /// - "Non-student" where applicable.
  /// - "Not specified" if no selection has been made.
  String get membershipDisplayLabel {
    if (membershipStatus == null) {
      return 'Not specified';
    }
    switch (membershipStatus!) {
      case MembershipStatus.manitStudent:
        if (verificationStatus == VerificationStatus.verified) {
          return 'MANIT Verified Scholar';
        } else if (verificationStatus == VerificationStatus.pendingReview) {
          return 'MANIT Student — Verification Pending';
        } else if (verificationStatus == VerificationStatus.rejected) {
          return 'MANIT Student — Verification Declined';
        } else {
          return 'MANIT Student — Unverified';
        }
      case MembershipStatus.otherCollege:
        if (collegeName.trim().isNotEmpty &&
            collegeName.trim().toLowerCase() != 'manit bhopal') {
          return collegeName.trim();
        }
        return 'Student (Other College)';
      case MembershipStatus.nonStudent:
        return 'Non-student';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': fullName,
      'avatar_url': avatarUrl,
      'college_name': collegeName,
      'membership_status': membershipStatus?.name,
      'membership_verification_status': verificationStatus.toDbValue(),
      'scholar_number': scholarNumber,
      'branch': branch,
      'academic_year': academicYear,
      'bio': bio,
      'skills': skills,
      'interests': interests,
      'github_url': githubUrl,
      'linkedin_url': linkedinUrl,
      'portfolio_url': portfolioUrl,
      'whatsapp_number': whatsappNumber,
      'is_profile_public': isProfilePublic,
      'allow_whatsapp_direct': allowWhatsAppDirect,
    };
  }

  /// Safe payload for ordinary profile updates by clients.
  /// Omits membership_verification_status to prevent client tampering.
  Map<String, dynamic> toUpdateJson() {
    return {
      'id': id,
      'display_name': fullName,
      'avatar_url': avatarUrl,
      'college_name': collegeName,
      'membership_status': membershipStatus?.name,
      'branch': branch,
      'academic_year': academicYear,
      'bio': bio,
      'skills': skills,
      'interests': interests,
      'github_url': githubUrl,
      'linkedin_url': linkedinUrl,
      'portfolio_url': portfolioUrl,
      'whatsapp_number': whatsappNumber,
      'is_profile_public': isProfilePublic,
      'allow_whatsapp_direct': allowWhatsAppDirect,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawVerification = json['membership_verification_status'] as String?;
    final isExplicitVerified = json['is_manit_verified'] as bool? ?? false;

    VerificationStatus vStatus;
    if (rawVerification != null) {
      vStatus = VerificationStatus.fromString(rawVerification);
    } else if (isExplicitVerified) {
      vStatus = VerificationStatus.verified;
    } else {
      vStatus = VerificationStatus.unverified;
    }

    final rawName = json['display_name'] as String? ?? json['full_name'] as String? ?? '';

    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: rawName,
      avatarUrl: json['avatar_url'] as String?,
      collegeName: json['college_name'] as String? ?? 'MANIT Bhopal',
      membershipStatus: MembershipStatus.fromString(json['membership_status'] as String?),
      verificationStatus: vStatus,
      scholarNumber: json['scholar_number'] as String?,
      branch: json['branch'] as String? ?? 'Computer Science & Engineering',
      academicYear: json['academic_year'] as String? ?? '1st Year B.Tech',
      bio: json['bio'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      githubUrl: json['github_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      portfolioUrl: json['portfolio_url'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      isProfilePublic: json['is_profile_public'] as bool? ?? true,
      allowWhatsAppDirect: json['allow_whatsapp_direct'] as bool? ?? true,
    );
  }
}
