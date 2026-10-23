import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/app/app.dart';
import 'package:manit_teamup/core/navigation/app_scaffold.dart';

void main() {
  testWidgets('ManitTeamUpApp smoke test and navigation verification',
      (WidgetTester tester) async {
    // Build our app with AppScaffold to verify destination navigation.
    await tester.pumpWidget(const ManitTeamUpApp(home: AppScaffold()));
    await tester.pump();

    // Verify initial header is displayed
    expect(find.text('Teammate & Hackathons'), findsOneWidget);

    // Verify all 5 navigation destinations exist
    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('Teams'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify floating action button to launch team exists on Discovery tab
    expect(find.text('Launch Team'), findsOneWidget);

    // Tap on Teams tab
    await tester.tap(find.text('Teams'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify top bar updates to Team Workspaces
    expect(find.text('Team Workspaces'), findsOneWidget);

    // Tap on Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify top bar updates to Scholar Profile
    expect(find.text('Scholar Profile'), findsOneWidget);
    expect(find.text('Edit Profile & Skills'), findsOneWidget);

    // Verify Android predictive back / PopScope behavior:
    // Back navigation on Profile tab should return to Discovery tab
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Teammate & Hackathons'), findsOneWidget);
  });
}
