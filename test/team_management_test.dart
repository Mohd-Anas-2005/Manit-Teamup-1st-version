import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/features/teams/domain/team.dart';
import 'package:manit_teamup/features/teams/presentation/create_team_screen.dart';
import 'package:manit_teamup/features/teams/presentation/edit_team_screen.dart';
import 'package:manit_teamup/features/teams/presentation/team_detail_screen.dart';
import 'package:manit_teamup/features/teams/services/team_repository.dart';

void main() {
  group('Team Domain & Capacity Invariant Tests', () {
    final sampleTeam = Team(
      id: 'team-uuid-1',
      ownerId: 'owner-uuid-1',
      ownerName: 'Aryan Sharma',
      ownerIsManitVerified: true,
      title: 'Autonomous Drone Roster',
      description: 'Developing autonomous indoor navigation for search & rescue.',
      projectCategory: ProjectCategory.hackathon,
      eventName: 'Smart India Hackathon 2026',
      requiredSkills: const ['Flutter', 'Python', 'ROS', 'OpenCV'],
      maxTeamSize: 4,
      isRecruiting: true,
      members: const [
        TeamMember(
          userId: 'owner-uuid-1',
          fullName: 'Aryan Sharma',
          role: TeamRole.owner,
          branch: 'Computer Science & Engineering',
          academicYear: '3rd Year B.Tech',
          isManitVerified: true,
          skills: ['Flutter', 'Dart'],
        ),
        TeamMember(
          userId: 'member-uuid-2',
          fullName: 'Divya Patel',
          role: TeamRole.lead,
          branch: 'Electronics & Communication',
          academicYear: '3rd Year B.Tech',
          isManitVerified: true,
          skills: ['ROS', 'Python'],
        ),
      ],
      createdAt: DateTime.parse('2026-10-21T00:00:00Z'),
    );

    test('Computes vacancies and capacity status correctly', () {
      expect(sampleTeam.memberCount, 2);
      expect(sampleTeam.vacanciesLeft, 2);
      expect(sampleTeam.isFull, isFalse);

      final fullTeam = sampleTeam.copyWith(
        members: [
          ...sampleTeam.members,
          const TeamMember(
            userId: 'member-uuid-3',
            fullName: 'Kabir Khan',
            branch: 'Electrical Engineering',
            academicYear: '2nd Year B.Tech',
          ),
          const TeamMember(
            userId: 'member-uuid-4',
            fullName: 'Neha Joshi',
            branch: 'Mechanical Engineering',
            academicYear: '3rd Year B.Tech',
          ),
        ],
      );

      expect(fullTeam.memberCount, 4);
      expect(fullTeam.vacanciesLeft, 0);
      expect(fullTeam.isFull, isTrue);
    });

    test('toDatabaseInsertJson produces valid Supabase schema payload', () {
      final insertJson = sampleTeam.toDatabaseInsertJson();

      expect(insertJson['name'], 'Autonomous Drone Roster');
      expect(insertJson['category'], 'hackathon');
      expect(insertJson['event_name'], 'Smart India Hackathon 2026');
      expect(insertJson['max_members'], 4);
      expect(insertJson['recruitment_status'], 'open');
      expect(insertJson['owner_id'], 'owner-uuid-1');
      expect(insertJson['required_skills'], ['Flutter', 'Python', 'ROS', 'OpenCV']);
    });

    test('toDatabaseUpdateJson omits immutable columns (id, owner_id, created_at)', () {
      final updateJson = sampleTeam.toDatabaseUpdateJson();

      expect(updateJson.containsKey('id'), isFalse, reason: 'Team ID is immutable in database trigger');
      expect(updateJson.containsKey('owner_id'), isFalse, reason: 'Owner ID is immutable in database trigger');
      expect(updateJson.containsKey('created_at'), isFalse, reason: 'Created at timestamp is immutable');
      expect(updateJson['name'], 'Autonomous Drone Roster');
      expect(updateJson['category'], 'hackathon');
      expect(updateJson['recruitment_status'], 'open');
    });

    test('fromJson decodes Supabase PostgreSQL columns seamlessly', () {
      final dbRow = {
        'id': 'db-team-101',
        'owner_id': 'user-lead-99',
        'name': 'SIH AI Health Navigator',
        'description': 'AI diagnostics for rural health centers.',
        'category': 'aiMl',
        'event_name': 'Smart India Hackathon',
        'required_skills': ['FastAPI', 'PyTorch', 'Flutter'],
        'max_members': 5,
        'recruitment_status': 'closed',
        'created_at': '2026-10-21T08:00:00Z',
        'profiles': {
          'display_name': 'Meera Nambiar',
          'membership_verification_status': 'verified',
        },
      };

      final parsed = Team.fromJson(dbRow);

      expect(parsed.id, 'db-team-101');
      expect(parsed.ownerId, 'user-lead-99');
      expect(parsed.title, 'SIH AI Health Navigator');
      expect(parsed.projectCategory, ProjectCategory.aiMl);
      expect(parsed.maxTeamSize, 5);
      expect(parsed.isRecruiting, isFalse);
      expect(parsed.ownerName, 'Meera Nambiar');
      expect(parsed.ownerIsManitVerified, isTrue);
    });
  });

  group('TeamRepository Authorization & Failure Safety Tests', () {
    test('createTeam fails safely when unauthenticated', () async {
      final result = await TeamRepository.instance.createTeam(
        title: 'Cybersecurity Testing Roster',
        description: 'Vulnerability assessment toolkit for campus systems.',
        category: ProjectCategory.openSource,
        eventName: 'DefCon Campus',
        requiredSkills: ['Linux', 'Go'],
        maxTeamSize: 3,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('updateTeam enforces authentication', () async {
      final result = await TeamRepository.instance.updateTeam(
        teamId: 'team-test-1',
        title: 'Updated Title',
        description: 'Updated Description',
        category: ProjectCategory.startup,
        eventName: 'E-Summit',
        requiredSkills: ['Next.js'],
        maxTeamSize: 4,
        isRecruiting: false,
      );

      expect(result.isSuccess, isFalse);
    });

    test('deleteTeam enforces authentication', () async {
      final result = await TeamRepository.instance.deleteTeam('team-test-1');
      expect(result.isSuccess, isFalse);
    });
  });

  group('CreateTeamScreen Form & Live Preview Widget Tests', () {
    testWidgets('Renders all fields and validates required inputs on empty submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateTeamScreen(),
        ),
      );

      expect(find.text('Launch New Team'), findsOneWidget);
      expect(find.text('Discovery Card Live Preview'), findsOneWidget);

      // Tap publish button without filling fields
      final submitBtn = find.text('Publish Team Broadcast');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Enter team title'), findsOneWidget);
      expect(find.text('Enter event name'), findsOneWidget);
      expect(find.text('Specify required skills'), findsOneWidget);
      expect(find.text('Enter description'), findsOneWidget);
    });

    testWidgets('Live preview updates title in real time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateTeamScreen(),
        ),
      );

      // Enter title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Team / Project Title'),
        'AI Autonomous Delivery Drone',
      );
      await tester.pump();

      // Verify the preview reflects the entered title
      expect(find.text('AI Autonomous Delivery Drone'), findsWidgets);
    });
  });

  group('TeamDetailScreen Roster Display Widget Tests', () {
    final testTeam = Team(
      id: 'test-team-id',
      ownerId: 'owner-id-xyz',
      ownerName: 'Gaurav Sen',
      ownerIsManitVerified: true,
      title: 'RoboCup Autonomous Rover',
      description: 'Building competitive rover with autonomous waypoint navigation.',
      projectCategory: ProjectCategory.hackathon,
      eventName: 'MANIT TechFest Robocon',
      requiredSkills: const ['C++', 'ROS2', 'SLAM', 'Python'],
      maxTeamSize: 4,
      isRecruiting: true,
      members: const [
        TeamMember(
          userId: 'owner-id-xyz',
          fullName: 'Gaurav Sen',
          role: TeamRole.owner,
          branch: 'Computer Science & Engineering',
          academicYear: '4th Year B.Tech',
          isManitVerified: true,
        ),
        TeamMember(
          userId: 'member-2',
          fullName: 'Ananya Roy',
          role: TeamRole.member,
          branch: 'Electronics & Communication',
          academicYear: '3rd Year B.Tech',
          isManitVerified: true,
        ),
      ],
      createdAt: DateTime.now(),
    );

    testWidgets('Renders complete team broadcast details and roster members', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TeamDetailScreen(team: testTeam),
        ),
      );
      await tester.pump();

      // Header and Event
      expect(find.text('RoboCup Autonomous Rover'), findsOneWidget);
      expect(find.text('MANIT TechFest Robocon'), findsOneWidget);
      expect(find.text('Hackathon'), findsOneWidget);

      // Capacity
      expect(find.text('2 of 4 spots filled'), findsOneWidget);

      // Required Skills chips
      expect(find.text('C++'), findsOneWidget);
      expect(find.text('ROS2'), findsOneWidget);
      expect(find.text('SLAM'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);

      // Accepted Members Roster
      expect(find.text('Gaurav Sen'), findsOneWidget);
      expect(find.text('Lead / Owner'), findsOneWidget);
      expect(find.text('Ananya Roy'), findsOneWidget);
      expect(find.text('Teammate'), findsOneWidget);
    });
  });

  group('EditTeamScreen Details & Recruitment Toggle Widget Tests', () {
    final editableTeam = Team(
      id: 'edit-team-id',
      ownerId: 'owner-1',
      ownerName: 'Gaurav Sen',
      title: 'Smart Campus AI',
      description: 'Automated attendance and occupancy tracking.',
      projectCategory: ProjectCategory.academicProject,
      eventName: 'Final Year Capstone',
      requiredSkills: const ['Flutter', 'Python'],
      maxTeamSize: 3,
      isRecruiting: true,
      createdAt: DateTime.now(),
    );

    testWidgets('Populates initial values and allows recruitment status toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EditTeamScreen(team: editableTeam),
        ),
      );

      expect(find.text('Edit Team Broadcast'), findsOneWidget);
      expect(find.text('Smart Campus AI'), findsOneWidget);
      expect(find.text('Final Year Capstone'), findsOneWidget);
      expect(find.text('Open for Recruitment'), findsOneWidget);

      // Toggle recruitment switch
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(find.text('Recruitment is paused or closed.'), findsOneWidget);
    });
  });
}
