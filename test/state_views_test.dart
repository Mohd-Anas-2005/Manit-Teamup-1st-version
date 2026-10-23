import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/core/widgets/state_views.dart';

void main() {
  group('State Components Verification', () {
    testWidgets('LoadingStateView displays indicator and optional message',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateView(message: 'Scanning for team broadcasts...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Scanning for team broadcasts...'), findsOneWidget);
    });

    testWidgets('ErrorStateView displays message and triggers retry callback',
        (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateView(
              title: 'Connection Interrupted',
              message: 'Failed to synchronize with MANIT server',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Connection Interrupted'), findsOneWidget);
      expect(find.text('Failed to synchronize with MANIT server'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      expect(retryPressed, isTrue);
    });

    testWidgets('EmptyStateView displays empty illustration, title, and action',
        (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              title: 'No Active Requests',
              message: 'You have not sent or received joining requests yet.',
              actionLabel: 'Discover Teams',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('No Active Requests'), findsOneWidget);
      expect(find.text('You have not sent or received joining requests yet.'), findsOneWidget);
      expect(find.text('Discover Teams'), findsOneWidget);

      await tester.tap(find.text('Discover Teams'));
      expect(actionPressed, isTrue);
    });

    testWidgets('SuccessStateView displays success badge, title, and description',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessStateView(
              title: 'Scholar Verified',
              message: 'Institutional MANIT credentials verified successfully.',
            ),
          ),
        ),
      );

      expect(find.text('Scholar Verified'), findsOneWidget);
      expect(find.text('Institutional MANIT credentials verified successfully.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
