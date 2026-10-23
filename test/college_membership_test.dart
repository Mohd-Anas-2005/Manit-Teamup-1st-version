import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/core/theme/app_theme.dart';
import 'package:manit_teamup/features/discovery/domain/discovery_filter.dart';
import 'package:manit_teamup/features/profiles/domain/user_profile.dart';
import 'package:manit_teamup/features/profiles/presentation/edit_profile_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: child,
  );
}

void main() {
  group('College Membership Domain Model & Display Label Tests', () {
    test('Shows MANIT Verified Scholar only for verified MANIT students', () {
      const verifiedStudent = UserProfile(
        id: 'u-1',
        email: 'scholar@stu.manit.ac.in',
        fullName: 'Aman Sharma',
        membershipStatus: MembershipStatus.manitStudent,
        verificationStatus: VerificationStatus.verified,
      );

      expect(verifiedStudent.isManitVerified, isTrue);
      expect(verifiedStudent.membershipDisplayLabel, 'MANIT Verified Scholar');
    });

    test('Shows MANIT Student — Unverified for self-declared unverified MANIT students', () {
      const unverifiedStudent = UserProfile(
        id: 'u-2',
        email: 'newbie@stu.manit.ac.in',
        fullName: 'Rohit Kumar',
        membershipStatus: MembershipStatus.manitStudent,
        verificationStatus: VerificationStatus.unverified,
      );

      expect(unverifiedStudent.isManitVerified, isFalse);
      expect(unverifiedStudent.membershipDisplayLabel, 'MANIT Student — Unverified');
    });

    test('Shows MANIT Student — Verification Pending when under review', () {
      const pendingStudent = UserProfile(
        id: 'u-3',
        email: 'pending@stu.manit.ac.in',
        fullName: 'Pooja Singh',
        membershipStatus: MembershipStatus.manitStudent,
        verificationStatus: VerificationStatus.pendingReview,
      );

      expect(pendingStudent.isManitVerified, isFalse);
      expect(pendingStudent.isVerificationPending, isTrue);
      expect(pendingStudent.membershipDisplayLabel, 'MANIT Student — Verification Pending');
    });

    test('Shows the other college name for students elsewhere', () {
      const iitStudent = UserProfile(
        id: 'u-4',
        email: 'student@iitb.ac.in',
        fullName: 'Ananya Roy',
        collegeName: 'IIT Bombay',
        membershipStatus: MembershipStatus.otherCollege,
        verificationStatus: VerificationStatus.unverified,
      );

      expect(iitStudent.isManitVerified, isFalse);
      expect(iitStudent.membershipDisplayLabel, 'IIT Bombay');

      const nitStudent = UserProfile(
        id: 'u-5',
        email: 'student@nitt.edu',
        fullName: 'Vikram Iyer',
        collegeName: 'NIT Trichy',
        membershipStatus: MembershipStatus.otherCollege,
      );
      expect(nitStudent.membershipDisplayLabel, 'NIT Trichy');
    });

    test('Shows Non-student where applicable', () {
      const visitor = UserProfile(
        id: 'u-6',
        email: 'dev@startup.com',
        fullName: 'Kunal Shah',
        collegeName: 'Not a student',
        membershipStatus: MembershipStatus.nonStudent,
      );

      expect(visitor.isManitVerified, isFalse);
      expect(visitor.membershipDisplayLabel, 'Non-student');
    });

    test('Shows Not specified if no selection has been made', () {
      const unselected = UserProfile(
        id: 'u-7',
        email: 'user@example.com',
        fullName: 'New User',
        membershipStatus: null,
      );

      expect(unselected.isManitVerified, isFalse);
      expect(unselected.membershipDisplayLabel, 'Not specified');
    });
  });

  group('Ordinary Profile Update Security & Invariants', () {
    test('toUpdateJson() strictly omits verification status so users cannot self-verify', () {
      const user = UserProfile(
        id: 'user-attack',
        email: 'attacker@stu.manit.ac.in',
        fullName: 'Attacker Attempting Verification',
        membershipStatus: MembershipStatus.manitStudent,
        verificationStatus: VerificationStatus.verified, // even if local state has verified
        scholarNumber: '211112099',
      );

      final updatePayload = user.toUpdateJson();

      // Ensure forbidden fields are not sent to Supabase in profile edits
      expect(updatePayload.containsKey('membership_verification_status'), isFalse,
          reason: 'Ordinary profile updates must NEVER contain membership_verification_status');
      expect(updatePayload.containsKey('is_manit_verified'), isFalse,
          reason: 'Ordinary profile updates must NEVER contain is_manit_verified');

      expect(updatePayload['id'], 'user-attack');
      expect(updatePayload['display_name'], 'Attacker Attempting Verification');
      expect(updatePayload['membership_status'], 'manitStudent');
    });
  });

  group('DiscoveryFilter Criteria Tests', () {
    const manitVerified = UserProfile(
      id: '1',
      email: 'verified@stu.manit.ac.in',
      fullName: 'Aarav Patel',
      collegeName: 'MANIT Bhopal',
      membershipStatus: MembershipStatus.manitStudent,
      verificationStatus: VerificationStatus.verified,
      branch: 'Computer Science & Engineering',
      academicYear: '3rd Year B.Tech',
      skills: ['Flutter', 'Dart', 'Firebase'],
    );

    const manitUnverified = UserProfile(
      id: '2',
      email: 'unverified@stu.manit.ac.in',
      fullName: 'Bhavna Joshi',
      collegeName: 'MANIT Bhopal',
      membershipStatus: MembershipStatus.manitStudent,
      verificationStatus: VerificationStatus.unverified,
      branch: 'Electrical Engineering',
      academicYear: '2nd Year B.Tech',
      skills: ['Python', 'IoT', 'C++'],
    );

    const otherCollege = UserProfile(
      id: '3',
      email: 'iitd@iitd.ac.in',
      fullName: 'Chetan Bhagat',
      collegeName: 'IIT Delhi',
      membershipStatus: MembershipStatus.otherCollege,
      verificationStatus: VerificationStatus.unverified,
      branch: 'Mechanical Engineering',
      academicYear: '4th Year B.Tech',
      skills: ['Robotics', 'CAD', 'Python'],
    );

    test('Filter by MANIT students', () {
      const filter = DiscoveryFilter(onlyManitStudents: true);
      expect(filter.matchesProfile(manitVerified), isTrue);
      expect(filter.matchesProfile(manitUnverified), isTrue);
      expect(filter.matchesProfile(otherCollege), isFalse);
    });

    test('Filter by Verified MANIT students only', () {
      const filter = DiscoveryFilter(onlyVerifiedManit: true);
      expect(filter.matchesProfile(manitVerified), isTrue);
      expect(filter.matchesProfile(manitUnverified), isFalse);
      expect(filter.matchesProfile(otherCollege), isFalse);
    });

    test('Filter by students from other colleges', () {
      const filter = DiscoveryFilter(onlyOtherCollegeStudents: true);
      expect(filter.matchesProfile(manitVerified), isFalse);
      expect(filter.matchesProfile(manitUnverified), isFalse);
      expect(filter.matchesProfile(otherCollege), isTrue);
    });

    test('Filter by branch', () {
      const filter = DiscoveryFilter(branch: 'Computer Science');
      expect(filter.matchesProfile(manitVerified), isTrue);
      expect(filter.matchesProfile(manitUnverified), isFalse);
      expect(filter.matchesProfile(otherCollege), isFalse);
    });

    test('Filter by academic year', () {
      const filter = DiscoveryFilter(academicYear: '2nd Year');
      expect(filter.matchesProfile(manitVerified), isFalse);
      expect(filter.matchesProfile(manitUnverified), isTrue);
      expect(filter.matchesProfile(otherCollege), isFalse);
    });

    test('Filter by skills', () {
      const filterFlutter = DiscoveryFilter(skill: 'Flutter');
      expect(filterFlutter.matchesProfile(manitVerified), isTrue);
      expect(filterFlutter.matchesProfile(manitUnverified), isFalse);

      const filterPython = DiscoveryFilter(skill: 'Python');
      expect(filterPython.matchesProfile(manitVerified), isFalse);
      expect(filterPython.matchesProfile(manitUnverified), isTrue);
      expect(filterPython.matchesProfile(otherCollege), isTrue);
    });
  });

  group('EditProfileScreen Membership Form Tests', () {
    testWidgets('Shows college name field when "Student from another college" selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const EditProfileScreen()));
      await tester.pump();

      // Default is MANIT Student -> College Name field should not be visible
      expect(find.text('College / Institute Name'), findsNothing);

      // Open Dropdown
      await tester.tap(find.text('MANIT Student'));
      await tester.pumpAndSettle();

      // Select "Student from another college"
      await tester.tap(find.text('Student from another college').last);
      await tester.pumpAndSettle();

      // Now college name field must be displayed
      expect(find.text('College / Institute Name'), findsOneWidget);
    });
  });
}
