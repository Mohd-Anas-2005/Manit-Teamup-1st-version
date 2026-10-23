enum RequestStatus {
  pending('Pending Review'),
  accepted('Accepted'),
  rejected('Declined'),
  withdrawn('Withdrawn');

  final String label;
  const RequestStatus(this.label);
}

class JoinRequest {
  final String id;
  final String teamId;
  final String teamTitle;
  final String applicantId;
  final String applicantName;
  final String applicantBranch;
  final String applicantYear;
  final String applicantCollege;
  final bool applicantIsManitVerified;
  final List<String> applicantSkills;
  final String pitchNote;
  final RequestStatus status;
  final DateTime createdAt;

  const JoinRequest({
    required this.id,
    required this.teamId,
    required this.teamTitle,
    required this.applicantId,
    required this.applicantName,
    required this.applicantBranch,
    required this.applicantYear,
    this.applicantCollege = 'MANIT Bhopal',
    this.applicantIsManitVerified = false,
    this.applicantSkills = const [],
    required this.pitchNote,
    this.status = RequestStatus.pending,
    required this.createdAt,
  });

  JoinRequest copyWith({
    String? id,
    String? teamId,
    String? teamTitle,
    String? applicantId,
    String? applicantName,
    String? applicantBranch,
    String? applicantYear,
    String? applicantCollege,
    bool? applicantIsManitVerified,
    List<String>? applicantSkills,
    String? pitchNote,
    RequestStatus? status,
    DateTime? createdAt,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamTitle: teamTitle ?? this.teamTitle,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      applicantBranch: applicantBranch ?? this.applicantBranch,
      applicantYear: applicantYear ?? this.applicantYear,
      applicantCollege: applicantCollege ?? this.applicantCollege,
      applicantIsManitVerified: applicantIsManitVerified ?? this.applicantIsManitVerified,
      applicantSkills: applicantSkills ?? this.applicantSkills,
      pitchNote: pitchNote ?? this.pitchNote,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'team_title': teamTitle,
      'applicant_id': applicantId,
      'applicant_name': applicantName,
      'applicant_branch': applicantBranch,
      'applicant_year': applicantYear,
      'applicant_college': applicantCollege,
      'applicant_is_manit_verified': applicantIsManitVerified,
      'applicant_skills': applicantSkills,
      'pitch_note': pitchNote,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    // Extract nested profiles object if present (e.g. from table joins)
    final profile = json['profiles'] as Map<String, dynamic>?;
    // Extract nested teams object if present
    final team = json['teams'] as Map<String, dynamic>?;

    final parsedTeamTitle = json['team_title'] as String? ??
        team?['name'] as String? ??
        '';

    final parsedApplicantId = json['applicant_id'] as String? ??
        json['requester_id'] as String? ??
        '';

    final parsedApplicantName = json['applicant_name'] as String? ??
        profile?['display_name'] as String? ??
        '';

    final parsedApplicantBranch = json['applicant_branch'] as String? ??
        profile?['branch'] as String? ??
        '';

    final parsedApplicantYear = json['applicant_year'] as String? ??
        profile?['academic_year'] as String? ??
        '';

    final parsedApplicantCollege = json['applicant_college'] as String? ??
        profile?['college_name'] as String? ??
        'MANIT Bhopal';

    final parsedIsManitVerified = json['applicant_is_manit_verified'] as bool? ??
        (profile?['membership_verification_status'] == 'verified');

    final parsedSkills = (json['applicant_skills'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (profile?['skills'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final parsedPitchNote = json['pitch_note'] as String? ??
        json['message'] as String? ??
        '';

    return JoinRequest(
      id: json['id'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      teamTitle: parsedTeamTitle,
      applicantId: parsedApplicantId,
      applicantName: parsedApplicantName,
      applicantBranch: parsedApplicantBranch,
      applicantYear: parsedApplicantYear,
      applicantCollege: parsedApplicantCollege,
      applicantIsManitVerified: parsedIsManitVerified,
      applicantSkills: parsedSkills,
      pitchNote: parsedPitchNote,
      status: RequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
