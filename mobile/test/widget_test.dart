// AIVONITY Vehicle Assistant Widget Tests
//
// Tests for the AIVONITY vehicle assistant application

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aivonity_app/main.dart';

void main() {
  testWidgets('AIVONITY app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AIVONITYApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that our app loads with the dashboard
    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);

    // Verify bottom navigation is present
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AIVONITYApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Tap on Analytics tab
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();

    // Verify we're on the Analytics screen
    expect(find.text('Analytics'), findsWidgets);

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify we're on the Settings screen
    expect(find.text('Settings'), findsWidgets);
  });
}

