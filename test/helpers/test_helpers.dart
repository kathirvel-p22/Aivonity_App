// Test helpers and utilities for AIVONITY testing suite

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aivonity_app/main.dart';

/// Test helper utilities for AIVONITY testing
class TestHelpers {
  /// Create a test app with providers
  static Widget createTestApp({Widget? home}) {
    return ProviderScope(
      overrides: [],
      child: MaterialApp(
        home: home ?? const MainDashboard(),
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      ),
    );
  }

  /// Setup test environment with mock shared preferences
  static Future<void> setupTestEnvironment() async {
    SharedPreferences.setMockInitialValues({});
  }

  /// Pump and settle with timeout
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Find widget by key with timeout
  static Future<Finder> findByKeyWithTimeout(
    WidgetTester tester,
    Key key, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
      final finder = find.byKey(key);
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
    }

    throw Exception('Widget with key $key not found within timeout');
  }

  /// Tap and wait for animation
  static Future<void> tapAndWait(
    WidgetTester tester,
    Finder finder, {
    Duration wait = const Duration(milliseconds: 300),
  }) async {
    await tester.tap(finder);
    await tester.pump(wait);
  }

  /// Enter text and wait
  static Future<void> enterTextAndWait(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration wait = const Duration(milliseconds: 300),
  }) async {
    await tester.enterText(finder, text);
    await tester.pump(wait);
  }

  /// Scroll until visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder,
    Finder scrollable, {
    double delta = 100.0,
    int maxScrolls = 50,
  }) async {
    int scrollCount = 0;

    while (scrollCount < maxScrolls) {
      if (finder.evaluate().isNotEmpty) {
        break;
      }

      await tester.drag(scrollable, Offset(0, -delta));
      await tester.pump();
      scrollCount++;
    }
  }

  /// Wait for condition
  static Future<void> waitForCondition(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (condition()) {
        return;
      }
      await tester.pump(interval);
    }

    throw Exception('Condition not met within timeout');
  }

  /// Generate test user data
  static Map<String, dynamic> generateTestUser({String? suffix}) {
    final id = suffix ?? DateTime.now().millisecondsSinceEpoch.toString();
    return {
      'email': 'test_user_$id@aivonity.com',
      'password': 'TestPassword123!',
      'name': 'Test User $id',
      'phone': '+1234567890',
    };
  }

  /// Generate test vehicle data
  static Map<String, dynamic> generateTestVehicle({String? suffix}) {
    final id = suffix ?? DateTime.now().millisecondsSinceEpoch.toString();
    return {
      'make': 'Tesla',
      'model': 'Model 3',
      'year': 2023,
      'vin': 'TEST${id.substring(0, 8).toUpperCase()}',
      'mileage': 15000,
    };
  }

  /// Generate test telemetry data
  static Map<String, dynamic> generateTestTelemetry({
    bool isAnomalous = false,
  }) {
    if (isAnomalous) {
      return {
        'engine_temp': 125.0, // Critical
        'oil_pressure': 15.0, // Low
        'battery_voltage': 10.5, // Low
        'rpm': 5500, // High
        'speed': 65.0,
        'fuel_level': 10.0, // Low
      };
    }

    return {
      'engine_temp': 85.5,
      'oil_pressure': 45.2,
      'battery_voltage': 12.6,
      'rpm': 2500,
      'speed': 65.0,
      'fuel_level': 75.0,
    };
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matcher for checking if a widget is visible
  static Matcher isVisible() {
    return _IsVisibleMatcher();
  }

  /// Matcher for checking if text contains substring
  static Matcher containsText(String substring) {
    return _ContainsTextMatcher(substring);
  }
}

class _IsVisibleMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Finder) {
      return item.evaluate().isNotEmpty;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is visible');
  }
}

class _ContainsTextMatcher extends Matcher {
  final String substring;

  _ContainsTextMatcher(this.substring);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is String) {
      return item.contains(substring);
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('contains text "$substring"');
  }
}

