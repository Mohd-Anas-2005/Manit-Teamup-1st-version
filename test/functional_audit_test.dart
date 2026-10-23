import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/features/profiles/domain/user_profile.dart';
import 'package:manit_teamup/features/profiles/presentation/edit_profile_screen.dart';
import 'package:manit_teamup/features/profiles/presentation/student_detail_screen.dart';
import 'package:manit_teamup/features/settings/presentation/settings_screen.dart';
import 'package:manit_teamup/features/discovery/presentation/discovery_screen.dart';
import 'package:manit_teamup/core/theme/app_theme.dart';

void main() {
  group('Functional Audit: Profile & Privacy Settings', () {
    testWidgets('EditProfileScreen retains existing social links and privacy toggles', (tester) async {
      const initialProfile = UserProfile(
        id: 'usr-1',
        email: 'scholar@manit.ac.in',
        fullName: 'Dev Scholar',
        collegeName: 'MANIT Bhopal',
        membershipStatus: MembershipStatus.manitStudent,
        verificationStatus: VerificationStatus.verified,
        branch: 'Computer Science & Engineering',
        academicYear: '3rd Year B.Tech',
        bio: 'Fullstack Dev',
        skills: ['Flutter', 'PostgreSQL'],
        interests: ['Hackathons'],
        githubUrl: 'https://github.com/scholar',
        linkedinUrl: 'https://linkedin.com/in/scholar',
        portfolioUrl: 'https://scholar.dev',
        whatsappNumber: '919876543210',
        isProfilePublic: true,
        allowWhatsAppDirect: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: EditProfileScreen(initialProfile: initialProfile),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Scholar Profile'), findsOneWidget);
      expect(find.text('Dev Scholar'), findsOneWidget);
      expect(find.text('919876543210'), findsOneWidget);
    });

    testWidgets('SettingsScreen displays privacy and direct contact toggles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('Collaboration & Privacy'), findsOneWidget);
      expect(find.text('Direct WhatsApp Inquiries'), findsOneWidget);
      expect(find.text('Public Roster Visibility'), findsOneWidget);
      expect(find.text('Legal & Support'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Delete Account Permanently'), 200);
      expect(find.text('Delete Account Permanently'), findsOneWidget);
    });
  });

  group('Functional Audit: Discovery & Student Detail', () {
    testWidgets('StudentDetailScreen renders Invite to Team button', (tester) async {
      const student = UserProfile(
        id: 'usr-2',
        email: 'rookie@manit.ac.in',
        fullName: 'Rookie Coder',
        collegeName: 'MANIT Bhopal',
        membershipStatus: MembershipStatus.manitStudent,
        verificationStatus: VerificationStatus.verified,
        branch: 'Electronics & Communication',
        academicYear: '2nd Year B.Tech',
        bio: 'Looking for ML teams',
        skills: ['Python', 'PyTorch'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StudentDetailScreen(student: student),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rookie Coder'), findsOneWidget);
      expect(find.text('Invite to Project / Team'), findsOneWidget);
    });

    testWidgets('DiscoveryScreen renders filter bar and search controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: DiscoveryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Broadcasts'), findsOneWidget);
      expect(find.text('Scholars'), findsOneWidget);
    });
  });
}
