import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/features/joining_requests/domain/join_request.dart';
import 'package:manit_teamup/features/joining_requests/presentation/joining_requests_screen.dart';
import 'package:manit_teamup/features/joining_requests/services/join_request_repository.dart';
import 'package:manit_teamup/features/teams/domain/team.dart';
import 'package:manit_teamup/features/teams/presentation/team_detail_screen.dart';

void main() {
  group('JoinRequest Domain Model & Parsing Tests', () {
    test('Correctly parses flat JSON from Supabase RPC', () {
      final json = {
        'id': 'req-uuid-1',
        'team_id': 'team-uuid-1',
        'team_title': 'SIH AI Health Navigator',
        'applicant_id': 'user-uuid-1',
        'applicant_name': 'Rohan Verma',
        'applicant_branch': 'Computer Science & Engineering',
        'applicant_year': '3rd Year B.Tech',
        'applicant_college': 'MANIT Bhopal',
        'applicant_is_manit_verified': true,
        'applicant_skills': ['Flutter', 'Python', 'FastAPI'],
        'pitch_note': 'I have built 2 hackathon projects in Flutter & FastAPI.',
        'status': 'pending',
        'created_at': '2026-10-21T10:00:00Z',
      };

      final req = JoinRequest.fromJson(json);

      expect(req.id, 'req-uuid-1');
      expect(req.teamId, 'team-uuid-1');
      expect(req.teamTitle, 'SIH AI Health Navigator');
      expect(req.applicantId, 'user-uuid-1');
      expect(req.applicantName, 'Rohan Verma');
      expect(req.applicantIsManitVerified, isTrue);
      expect(req.pitchNote, 'I have built 2 hackathon projects in Flutter & FastAPI.');
      expect(req.status, RequestStatus.pending);
      expect(req.applicantSkills, contains('Flutter'));
    });

    test('Correctly parses nested PostgreSQL relations (teams & profiles)', () {
      final dbRow = {
        'id': 'req-uuid-2',
        'team_id': 'team-uuid-2',
        'requester_id': 'user-uuid-2',
        'message': 'Optional pitch message from student',
        'status': 'accepted',
        'created_at': '2026-10-21T11:00:00Z',
        'teams': {
          'name': 'Robotics Autonomous Roster',
        },
        'profiles': {
          'display_name': 'Pooja Sharma',
          'branch': 'Electrical Engineering',
          'academic_year': '2nd Year B.Tech',
          'college_name': 'MANIT Bhopal',
          'membership_verification_status': 'verified',
          'skills': ['ROS', 'C++'],
        },
      };

      final req = JoinRequest.fromJson(dbRow);

      expect(req.id, 'req-uuid-2');
      expect(req.teamId, 'team-uuid-2');
      expect(req.teamTitle, 'Robotics Autonomous Roster');
      expect(req.applicantId, 'user-uuid-2');
      expect(req.applicantName, 'Pooja Sharma');
      expect(req.applicantBranch, 'Electrical Engineering');
      expect(req.applicantIsManitVerified, isTrue);
      expect(req.pitchNote, 'Optional pitch message from student');
      expect(req.status, RequestStatus.accepted);
    });

    test('Handles optional empty or null pitch message safely', () {
      final json = {
        'id': 'req-uuid-3',
        'team_id': 'team-uuid-3',
        'applicant_id': 'user-uuid-3',
        'pitch_note': null,
        'message': null,
        'status': 'pending',
      };

      final req = JoinRequest.fromJson(json);

      expect(req.pitchNote, '');
      expect(req.status, RequestStatus.pending);
    });

    test('copyWith creates new instance with updated status and preserves other fields', () {
      final original = JoinRequest(
        id: 'req-uuid-4',
        teamId: 'team-uuid-4',
        teamTitle: 'AI Drone Crew',
        applicantId: 'applicant-1',
        applicantName: 'Vikram Singh',
        applicantBranch: 'Mechanical Engineering',
        applicantYear: '4th Year B.Tech',
        applicantIsManitVerified: true,
        pitchNote: 'Specialist in 3D CAD and autonomous flight control.',
        status: RequestStatus.pending,
        createdAt: DateTime.parse('2026-10-21T09:00:00Z'),
      );

      final accepted = original.copyWith(status: RequestStatus.accepted);
      expect(accepted.status, RequestStatus.accepted);
      expect(accepted.id, original.id);
      expect(accepted.applicantName, original.applicantName);

      final withdrawn = original.copyWith(status: RequestStatus.withdrawn);
      expect(withdrawn.status, RequestStatus.withdrawn);

      final rejected = original.copyWith(status: RequestStatus.rejected);
      expect(rejected.status, RequestStatus.rejected);
    });
  });

  group('JoinRequestRepository Authentication Invariant Tests', () {
    test('submitJoinRequest fails safely when unauthenticated', () async {
      final res = await JoinRequestRepository.instance.submitJoinRequest(
        teamId: 'team-uuid-1',
        message: 'Hello team',
      );

      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, isNotNull);
    });

    test('fetchIncomingRequests fails safely when unauthenticated', () async {
      final res = await JoinRequestRepository.instance.fetchIncomingRequests();

      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, isNotNull);
    });

    test('fetchSentRequests fails safely when unauthenticated', () async {
      final res = await JoinRequestRepository.instance.fetchSentRequests();

      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, isNotNull);
    });

    test('acceptJoinRequest enforces authentication', () async {
      final res = await JoinRequestRepository.instance.acceptJoinRequest('req-uuid-1');

      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, isNotNull);
    });

    test('withdrawJoinRequest enforces authentication', () async {
      final res = await JoinRequestRepository.instance.withdrawJoinRequest('req-uuid-1');

      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, isNotNull);
    });
  });

  group('JoiningRequestsScreen Widget & Interaction Tests', () {
    testWidgets('Renders empty state when no incoming or sent requests', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JoiningRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Incoming ('), findsOneWidget);
      expect(find.textContaining('Sent ('), findsOneWidget);
      expect(find.text('No Incoming Requests'), findsOneWidget);
    });

    testWidgets('Switches to Sent Applications tab and renders empty view', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JoiningRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Sent tab
      await tester.tap(find.textContaining('Sent'));
      await tester.pumpAndSettle();

      expect(find.text('No Applications Sent'), findsOneWidget);
    });
  });

  group('TeamDetailScreen Joining Workflow Widget Tests', () {
    final sampleRecruitingTeam = Team(
      id: 'team-recruiting-1',
      ownerId: 'owner-other-user',
      ownerName: 'Ananya Roy',
      ownerIsManitVerified: true,
      title: 'Smart Energy Optimizer',
      description: 'IoT and ML for power grid optimization at SIH 2026.',
      projectCategory: ProjectCategory.hackathon,
      eventName: 'Smart India Hackathon',
      requiredSkills: const ['Flutter', 'Python', 'IoT'],
      maxTeamSize: 4,
      isRecruiting: true,
      members: const [
        TeamMember(
          userId: 'owner-other-user',
          fullName: 'Ananya Roy',
          role: TeamRole.owner,
          branch: 'Electrical Engineering',
          academicYear: '3rd Year B.Tech',
          isManitVerified: true,
        ),
      ],
      createdAt: DateTime.parse('2026-10-21T00:00:00Z'),
    );

    testWidgets('Shows "Pitch & Request to Join" button when team is recruiting and user is not member', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TeamDetailScreen(team: sampleRecruitingTeam),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pitch & Request to Join'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsWidgets);
    });

    testWidgets('Tapping "Pitch & Request to Join" opens bottom pitch sheet with optional note input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TeamDetailScreen(team: sampleRecruitingTeam),
        ),
      );

      await tester.pumpAndSettle();

      final buttonFinder = find.text('Pitch & Request to Join');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Submit Joining Pitch'), findsOneWidget);
      expect(find.textContaining('Pitch your skills to Ananya Roy'), findsOneWidget);
      expect(find.text('Send Join Request'), findsOneWidget);
    });

    testWidgets('Shows recruitment closed card when team is not recruiting', (tester) async {
      final closedTeam = sampleRecruitingTeam.copyWith(isRecruiting: false);

      await tester.pumpWidget(
        MaterialApp(
          home: TeamDetailScreen(team: closedTeam),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recruitment for this team roster is currently closed.'), findsOneWidget);
      expect(find.text('Pitch & Request to Join'), findsNothing);
    });

    testWidgets('Shows recruitment closed card when team is at full capacity', (tester) async {
      final fullTeam = sampleRecruitingTeam.copyWith(
        maxTeamSize: 2,
        members: [
          ...sampleRecruitingTeam.members,
          const TeamMember(
            userId: 'member-2',
            fullName: 'Teammate Two',
            role: TeamRole.member,
            branch: 'Computer Science',
            academicYear: '2nd Year B.Tech',
          ),
        ],
      );

      expect(fullTeam.isFull, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: TeamDetailScreen(team: fullTeam),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recruitment for this team roster is currently closed.'), findsOneWidget);
      expect(find.text('Pitch & Request to Join'), findsNothing);
    });
  });
}
