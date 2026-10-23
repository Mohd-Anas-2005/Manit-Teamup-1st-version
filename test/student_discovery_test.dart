import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/features/discovery/domain/discovery_filter.dart';
import 'package:manit_teamup/features/discovery/presentation/discovery_screen.dart';
import 'package:manit_teamup/features/discovery/services/student_discovery_repository.dart';
import 'package:manit_teamup/features/profiles/domain/user_profile.dart';
import 'package:manit_teamup/features/profiles/presentation/student_detail_screen.dart';

void main() {
  group('Student Discovery Filtering & Search Criteria Tests', () {
    const student1 = UserProfile(
      id: 'student-1',
      email: 'aarav@stu.manit.ac.in',
      fullName: 'Aarav Sharma',
      collegeName: 'MANIT Bhopal',
      membershipStatus: MembershipStatus.manitStudent,
      verificationStatus: VerificationStatus.verified,
      branch: 'Computer Science & Engineering',
      academicYear: '3rd Year B.Tech',
      bio: 'Building AI/ML and mobile apps for campus innovation.',
      skills: ['Flutter', 'Python', 'PyTorch'],
      interests: ['AI/ML', 'Hackathons', 'Open Source'],
      scholarNumber: '211112001',
    );

    const student2 = UserProfile(
      id: 'student-2',
      email: 'priya@stu.manit.ac.in',
      fullName: 'Priya Verma',
      collegeName: 'MANIT Bhopal',
      membershipStatus: MembershipStatus.manitStudent,
      verificationStatus: VerificationStatus.unverified,
      branch: 'Electrical Engineering',
      academicYear: '2nd Year B.Tech',
      bio: 'Passionate about robotics, embedded systems and IoT.',
      skills: ['C++', 'IoT', 'Arduino'],
      interests: ['Robotics', 'Hardware'],
      scholarNumber: '221112045',
    );

    const student3 = UserProfile(
      id: 'student-3',
      email: 'rohan@iitb.ac.in',
      fullName: 'Rohan Mehta',
      collegeName: 'IIT Bombay',
      membershipStatus: MembershipStatus.otherCollege,
      verificationStatus: VerificationStatus.unverified,
      branch: 'Mechanical Engineering',
      academicYear: '4th Year B.Tech',
      bio: 'CAD design, 3D printing and competitive robotics.',
      skills: ['SolidWorks', 'Python', 'ROS'],
      interests: ['Robotics', 'Startups'],
    );

    const student4 = UserProfile(
      id: 'student-4',
      email: 'mentor@industry.com',
      fullName: 'Vikram Aditya',
      collegeName: 'Industry Mentor',
      membershipStatus: MembershipStatus.nonStudent,
      verificationStatus: VerificationStatus.unverified,
      branch: 'Software Architecture',
      academicYear: 'Alumnus',
      bio: 'Cloud infra engineer and open-source enthusiast.',
      skills: ['Go', 'Kubernetes', 'Cloud'],
      interests: ['Open Source', 'System Design'],
    );

    test('Searches students by display name', () {
      const filterAarav = DiscoveryFilter(query: 'Aarav');
      expect(filterAarav.matchesProfile(student1), isTrue);
      expect(filterAarav.matchesProfile(student2), isFalse);

      const filterPriya = DiscoveryFilter(query: 'priya');
      expect(filterPriya.matchesProfile(student2), isTrue);
      expect(filterPriya.matchesProfile(student1), isFalse);
    });

    test('Filters students by technical skills', () {
      const flutterFilter = DiscoveryFilter(skill: 'Flutter');
      expect(flutterFilter.matchesProfile(student1), isTrue);
      expect(flutterFilter.matchesProfile(student2), isFalse);

      const pythonFilter = DiscoveryFilter(skill: 'Python');
      expect(pythonFilter.matchesProfile(student1), isTrue);
      expect(pythonFilter.matchesProfile(student3), isTrue);
      expect(pythonFilter.matchesProfile(student2), isFalse);
    });

    test('Filters students by areas of interest', () {
      const aiFilter = DiscoveryFilter(interest: 'AI/ML');
      expect(aiFilter.matchesProfile(student1), isTrue);
      expect(aiFilter.matchesProfile(student2), isFalse);

      const roboticsFilter = DiscoveryFilter(interest: 'Robotics');
      expect(roboticsFilter.matchesProfile(student2), isTrue);
      expect(roboticsFilter.matchesProfile(student3), isTrue);
      expect(roboticsFilter.matchesProfile(student1), isFalse);
    });

    test('Filters students by college membership category', () {
      const manitCategory = DiscoveryFilter(membershipCategory: MembershipStatus.manitStudent);
      expect(manitCategory.matchesProfile(student1), isTrue);
      expect(manitCategory.matchesProfile(student2), isTrue);
      expect(manitCategory.matchesProfile(student3), isFalse);

      const otherCollegeCategory = DiscoveryFilter(membershipCategory: MembershipStatus.otherCollege);
      expect(otherCollegeCategory.matchesProfile(student3), isTrue);
      expect(otherCollegeCategory.matchesProfile(student1), isFalse);

      const nonStudentCategory = DiscoveryFilter(membershipCategory: MembershipStatus.nonStudent);
      expect(nonStudentCategory.matchesProfile(student4), isTrue);
      expect(nonStudentCategory.matchesProfile(student1), isFalse);
    });

    test('Filters students by verified MANIT status', () {
      const verifiedOnly = DiscoveryFilter(onlyVerifiedManit: true);
      expect(verifiedOnly.matchesProfile(student1), isTrue);
      expect(verifiedOnly.matchesProfile(student2), isFalse); // unverified MANIT student
      expect(verifiedOnly.matchesProfile(student3), isFalse); // other college
    });

    test('Filters students by branch and academic year', () {
      const csFilter = DiscoveryFilter(branch: 'Computer Science');
      expect(csFilter.matchesProfile(student1), isTrue);
      expect(csFilter.matchesProfile(student2), isFalse);

      const year2Filter = DiscoveryFilter(academicYear: '2nd Year');
      expect(year2Filter.matchesProfile(student2), isTrue);
      expect(year2Filter.matchesProfile(student1), isFalse);
    });

    test('Combines multiple filters into strict matching criteria', () {
      const compositeFilter = DiscoveryFilter(
        onlyVerifiedManit: true,
        branch: 'Computer Science',
        skill: 'Flutter',
        interest: 'AI/ML',
      );
      expect(compositeFilter.matchesProfile(student1), isTrue);
      expect(compositeFilter.matchesProfile(student2), isFalse);
      expect(compositeFilter.matchesProfile(student3), isFalse);
    });
  });

  group('StudentDiscoveryRepository Pagination & Security Invariants', () {
    test('StudentDiscoveryRepository handles unconfigured backend without leaking credentials', () async {
      // With default uninitialized SupabaseService client (null in test mode)
      final result = await StudentDiscoveryRepository.instance.fetchStudents(
        filter: const DiscoveryFilter(),
        offset: 0,
        limit: 10,
      );

      expect(result.students, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.errorMessage, contains('not configured'));
    });

    test('ScholarSortBy enum provides user-friendly labels', () {
      expect(ScholarSortBy.newest.label, 'Recently Joined');
      expect(ScholarSortBy.verifiedFirst.label, 'Verified Scholars First');
      expect(ScholarSortBy.nameAsc.label, 'Name (A to Z)');
    });
  });

  group('StudentDetailScreen Privacy & Content Widget Tests', () {
    const publicScholar = UserProfile(
      id: 'scholar-123',
      email: 'scholar@stu.manit.ac.in',
      fullName: 'Devansh Kulkarni',
      collegeName: 'MANIT Bhopal',
      membershipStatus: MembershipStatus.manitStudent,
      verificationStatus: VerificationStatus.verified,
      branch: 'Electronics & Communication',
      academicYear: '3rd Year B.Tech',
      bio: 'Developing edge IoT devices and autonomous rover firmware.',
      skills: ['Embedded C', 'Rust', 'PCB Design'],
      interests: ['Robotics', 'Hardware', 'Hackathons'],
      portfolioUrl: 'https://devansh.portfolio.dev',
      scholarNumber: '211119999', // Sensitive PII
      whatsappNumber: '+919876543210', // Sensitive PII
    );

    testWidgets('Renders complete student details with MANIT Verified badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentDetailScreen(student: publicScholar),
        ),
      );

      // Verify name, college, and branch
      expect(find.text('Devansh Kulkarni'), findsOneWidget);
      expect(find.text('MANIT Bhopal'), findsOneWidget);
      expect(find.text('Electronics & Communication'), findsOneWidget);
      expect(find.text('3rd Year B.Tech'), findsOneWidget);

      // Verify badge
      expect(find.text('MANIT Verified'), findsOneWidget);

      // Verify skills chips
      expect(find.text('Embedded C'), findsOneWidget);
      expect(find.text('Rust'), findsOneWidget);
      expect(find.text('PCB Design'), findsOneWidget);

      // Verify interests chips
      expect(find.text('Robotics'), findsOneWidget);
      expect(find.text('Hardware'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Invite to Project / Team'), findsOneWidget);
      expect(find.text('Return to Discovery'), findsOneWidget);

      // CRITICAL PRIVACY GUARANTEE: Never expose scholar number or phone number publicly
      expect(find.text('211119999'), findsNothing,
          reason: 'Scholar number must NEVER be rendered in public student detail screens');
      expect(find.text('+919876543210'), findsNothing,
          reason: 'Private phone number must NEVER be rendered in public student detail screens');
    });

    testWidgets('Renders other college student profile correctly', (tester) async {
      const otherStudent = UserProfile(
        id: 'scholar-other',
        email: 'priyanka@bits.ac.in',
        fullName: 'Priyanka Sen',
        collegeName: 'BITS Pilani',
        membershipStatus: MembershipStatus.otherCollege,
        verificationStatus: VerificationStatus.unverified,
        branch: 'Computer Science',
        academicYear: '4th Year B.Tech',
        skills: ['React', 'Next.js'],
        interests: ['Web3'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: StudentDetailScreen(student: otherStudent),
        ),
      );

      expect(find.text('Priyanka Sen'), findsOneWidget);
      expect(find.text('BITS Pilani'), findsNWidgets(2)); // in header & in badge
      expect(find.text('React'), findsOneWidget);
      expect(find.text('Web3'), findsOneWidget);
    });
  });

  group('DiscoveryScreen Scholars Tab & Empty State Widget Tests', () {
    testWidgets('Renders discovery screen with Broadcasts and Scholars segments', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiscoveryScreen(),
        ),
      );
      await tester.pump();

      // Check segments
      expect(find.text('Broadcasts'), findsOneWidget);
      expect(find.text('Scholars'), findsOneWidget);

      // Switch to Scholars tab
      await tester.tap(find.text('Scholars'));
      await tester.pumpAndSettle();

      // In unconfigured test mode, empty state should be rendered cleanly
      expect(find.byIcon(Icons.person_search_outlined), findsOneWidget);
      expect(find.text('No Scholars Found'), findsOneWidget);
    });
  });
}
