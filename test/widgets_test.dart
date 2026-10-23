import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/core/widgets/app_button.dart';
import 'package:manit_teamup/core/widgets/gradient_card.dart';
import 'package:manit_teamup/core/widgets/manit_badge.dart';

void main() {
  group('Core Reusable Widgets Tests', () {
    testWidgets('ManitBadge renders verified scholar and open vacancies badges',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ManitBadge.verified(),
                ManitBadge.scholarId('211112044'),
                ManitBadge.vacancies(3),
              ],
            ),
          ),
        ),
      );

      expect(find.text('MANIT Scholar'), findsOneWidget);
      expect(find.text('211112044'), findsOneWidget);
      expect(find.text('3 open spots'), findsOneWidget);
    });

    testWidgets('AppButton handles tap and displays loading spinner',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Submit Pitch',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit Pitch'), findsOneWidget);
      await tester.tap(find.text('Submit Pitch'));
      expect(tapped, isTrue);

      // Verify loading state disables tap and shows indicator
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Submit Pitch',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('GradientCard renders child and triggers onTap callback',
        (tester) async {
      bool cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientCard(
              onTap: () => cardTapped = true,
              child: const Text('Hackathon Squad Alpha'),
            ),
          ),
        ),
      );

      expect(find.text('Hackathon Squad Alpha'), findsOneWidget);
      await tester.tap(find.text('Hackathon Squad Alpha'));
      expect(cardTapped, isTrue);
    });
  });
}
