enum ProjectCategory {
  hackathon('Hackathon'),
  academicProject('College Project'),
  startup('Startup Venture'),
  aiMl('AI / ML Research'),
  openSource('Open Source'),
  competitiveProgramming('Coding Contest');

  final String displayName;
  const ProjectCategory(this.displayName);
}

enum TeamRole {
  owner('Lead / Owner'),
  lead('Co-Lead'),
  member('Teammate');

  final String label;
  const TeamRole(this.label);
}

class TeamMember {
  final String userId;
  final String fullName;
  final TeamRole role;
  final String branch;
  final String academicYear;
  final bool isManitVerified;
  final String? avatarUrl;
  final List<String> skills;
  final String? whatsappNumber;

  const TeamMember({
    required this.userId,
    required this.fullName,
    this.role = TeamRole.member,
    required this.branch,
    required this.academicYear,
    this.isManitVerified = false,
    this.avatarUrl,
    this.skills = const [],
    this.whatsappNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'role': role.name,
      'branch': branch,
      'academic_year': academicYear,
      'is_manit_verified': isManitVerified,
      'avatar_url': avatarUrl,
      'skills': skills,
      'whatsapp_number': whatsappNumber,
    };
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TeamMember(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      fullName: profile?['display_name'] as String? ??
          json['full_name'] as String? ??
          'Teammate',
      role: TeamRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => TeamRole.member,
      ),
      branch: profile?['branch'] as String? ?? json['branch'] as String? ?? '',
      academicYear: profile?['academic_year'] as String? ??
          json['academic_year'] as String? ??
          '',
      isManitVerified: profile?['membership_verification_status'] == 'verified' ||
          (profile?['is_manit_verified'] as bool? ?? false) ||
          (json['is_manit_verified'] as bool? ?? false),
      avatarUrl: profile?['avatar_url'] as String? ?? json['avatar_url'] as String?,
      skills: (profile?['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      whatsappNumber: json['whatsapp_number'] as String?,
    );
  }
}

class Team {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerScholar;
  final bool ownerIsManitVerified;
  final String title;
  final String description;
  final ProjectCategory projectCategory;
  final String eventName;
  final List<String> requiredSkills;
  final int maxTeamSize;
  final bool isRecruiting;
  final List<TeamMember> members;
  final String? whatsappGroupLink;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Team({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerScholar,
    this.ownerIsManitVerified = true,
    required this.title,
    required this.description,
    required this.projectCategory,
    required this.eventName,
    required this.requiredSkills,
    required this.maxTeamSize,
    this.isRecruiting = true,
    this.members = const [],
    this.whatsappGroupLink,
    required this.createdAt,
    this.updatedAt,
  });

  int get vacanciesLeft => (maxTeamSize - members.length).clamp(0, maxTeamSize);
  bool get isFull => vacanciesLeft == 0;
  int get memberCount => members.length;

  Team copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerScholar,
    bool? ownerIsManitVerified,
    String? title,
    String? description,
    ProjectCategory? projectCategory,
    String? eventName,
    List<String>? requiredSkills,
    int? maxTeamSize,
    bool? isRecruiting,
    List<TeamMember>? members,
    String? whatsappGroupLink,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerScholar: ownerScholar ?? this.ownerScholar,
      ownerIsManitVerified: ownerIsManitVerified ?? this.ownerIsManitVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      projectCategory: projectCategory ?? this.projectCategory,
      eventName: eventName ?? this.eventName,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      maxTeamSize: maxTeamSize ?? this.maxTeamSize,
      isRecruiting: isRecruiting ?? this.isRecruiting,
      members: members ?? this.members,
      whatsappGroupLink: whatsappGroupLink ?? this.whatsappGroupLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Format for database INSERT statement on public.teams
  Map<String, dynamic> toDatabaseInsertJson() {
    return {
      'name': title,
      'description': description,
      'category': projectCategory.name,
      'event_name': eventName,
      'required_skills': requiredSkills,
      'max_members': maxTeamSize,
      'recruitment_status': isRecruiting ? 'open' : 'closed',
      'whatsapp_group_link': whatsappGroupLink,
      'owner_id': ownerId,
    };
  }

  /// Format for database UPDATE statement on public.teams
  /// Omits id, owner_id, and created_at to preserve immutable triggers
  Map<String, dynamic> toDatabaseUpdateJson() {
    return {
      'name': title,
      'description': description,
      'category': projectCategory.name,
      'event_name': eventName,
      'required_skills': requiredSkills,
      'max_members': maxTeamSize,
      'recruitment_status': isRecruiting ? 'open' : 'closed',
      'whatsapp_group_link': whatsappGroupLink,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_scholar': ownerScholar,
      'owner_is_manit_verified': ownerIsManitVerified,
      'title': title,
      'description': description,
      'project_category': projectCategory.name,
      'event_name': eventName,
      'required_skills': requiredSkills,
      'max_team_size': maxTeamSize,
      'is_recruiting': isRecruiting,
      'members': members.map((m) => m.toJson()).toList(),
      'whatsapp_group_link': whatsappGroupLink,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    // Resolve owner information if profile is joined
    final ownerProfile = json['profiles'] as Map<String, dynamic>?;
    final String resolvedOwnerName = ownerProfile?['display_name'] as String? ??
        json['owner_name'] as String? ??
        'Team Lead';
    final bool resolvedOwnerVerified = ownerProfile?['membership_verification_status'] == 'verified' ||
        (ownerProfile?['is_manit_verified'] as bool? ?? false) ||
        (json['owner_is_manit_verified'] as bool? ?? false);

    // Resolve category from 'category' (DB column) or 'project_category'
    final rawCategory = json['category'] ?? json['project_category'];
    final ProjectCategory category = ProjectCategory.values.firstWhere(
      (c) => c.name == rawCategory,
      orElse: () => ProjectCategory.hackathon,
    );

    // Resolve recruitment status from 'recruitment_status' (DB column) or 'is_recruiting'
    final bool recruiting = json['recruitment_status'] != null
        ? json['recruitment_status'] == 'open'
        : (json['is_recruiting'] as bool? ?? true);

    // Resolve members if team_members joined
    List<TeamMember> parsedMembers = [];
    if (json['team_members'] is List) {
      parsedMembers = (json['team_members'] as List<dynamic>)
          .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
          .toList();
    } else if (json['members'] is List) {
      parsedMembers = (json['members'] as List<dynamic>)
          .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return Team(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      ownerName: resolvedOwnerName,
      ownerScholar: json['owner_scholar'] as String?,
      ownerIsManitVerified: resolvedOwnerVerified,
      title: json['name'] as String? ?? json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      projectCategory: category,
      eventName: json['event_name'] as String? ?? '',
      requiredSkills: (json['required_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      maxTeamSize: json['max_members'] as int? ?? json['max_team_size'] as int? ?? 4,
      isRecruiting: recruiting,
      members: parsedMembers,
      whatsappGroupLink: json['whatsapp_group_link'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
