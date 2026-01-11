import 'package:flutter/material.dart';

/// Actionable AI Service for parsing commands and taking actions within the app
class ActionableAIService {
  static ActionableAIService? _instance;
  static ActionableAIService get instance =>
      _instance ??= ActionableAIService._();

  ActionableAIService._();

  /// Parse user message and identify actionable commands
  Future<AIActionResult> parseAndExecuteAction(
    String message,
    BuildContext context,
  ) async {
    // Note: Navigation is handled by the calling screen, not here
    // This method only identifies actions and returns results
    final lowerMessage = message.toLowerCase();

    // Navigation commands
    if (_containsKeywords(lowerMessage, [
      'navigate',
      'go to',
      'take me to',
      'find route',
      'directions',
      'route to',
    ])) {
      return _handleNavigationCommand(message);
    }

    // Location-based commands
    if (_containsKeywords(
      lowerMessage,
      ['nearest', 'closest', 'near me', 'find', 'locate', 'search for'],
    )) {
      return _handleLocationCommand(message);
    }

    // Traffic and route information - HIGH PRIORITY
    if (_containsKeywords(lowerMessage, [
      'traffic',
      'traffic update',
      'road conditions',
      'congestion',
      'delay',
      'accidents',
      'road closures',
      'construction',
      'incident',
    ])) {
      return _handleTrafficCommand(message);
    }

    // Emergency navigation - HIGH PRIORITY
    if (_containsKeywords(lowerMessage, [
      'emergency',
      'help',
      'accident',
      'breakdown',
      'towing',
      'police',
      'hospital',
    ])) {
      return _handleEmergencyCommand();
    }

    // App section navigation - disabled for mobile app
    // if (_containsKeywords(
    //     lowerMessage, ['open', 'show', 'go to', 'switch to'])) {
    //   return _handleAppNavigationCommand(message);
    // }

    // Fuel/Service booking - disabled for mobile app
    // if (_containsKeywords(
    //     lowerMessage, ['book', 'schedule', 'appointment', 'service'])) {
    //   return _handleBookingCommand(message);
    // }

    // No actionable command found
    return const AIActionResult(
      action: AIAction.none,
      message: null,
      executed: false,
    );
  }

  /// Handle navigation commands
  AIActionResult _handleNavigationCommand(String message) {
    final lowerMessage = message.toLowerCase();

    // Extract destination from message
    final String destination = _extractDestination(message);

    if (destination.isNotEmpty) {
      // Convert navigation commands to location searches that open Google Maps
      return AIActionResult(
        action: AIAction.location,
        message:
            'Opening Google Maps with directions to $destination. Getting real-time route with traffic information.',
        executed: true,
        parameters: {
          'searchType': '${destination.replaceAll(' ', '+')}+directions',
          'traffic': true,
        },
      );
    }

    return const AIActionResult(
      action: AIAction.location,
      message:
          'Opening Google Maps for navigation. Please specify your destination.',
      executed: true,
      parameters: {'searchType': 'navigation', 'traffic': false},
    );
  }

  /// Handle location-based commands (find nearest places)
  AIActionResult _handleLocationCommand(String message) {
    final lowerMessage = message.toLowerCase();

    // Determine what to search for
    final String searchType = _determineSearchType(lowerMessage);

    if (searchType.isNotEmpty) {
      return AIActionResult(
        action: AIAction.location,
        message:
            'Finding nearest $searchType near your current location. Opening Google Maps with real-time results.',
        executed: true,
        parameters: {'searchType': searchType},
      );
    }

    return const AIActionResult(
      action: AIAction.location,
      message:
          'Opening Google Maps to show nearby services with live traffic information.',
      executed: true,
    );
  }

  /// Handle traffic and route information commands
  AIActionResult _handleTrafficCommand(String message) {
    final lowerMessage = message.toLowerCase();

    // Check if user wants traffic updates for a specific route
    if (_containsKeywords(lowerMessage, ['route', 'to', 'from'])) {
      final String destination = _extractDestination(message);
      if (destination.isNotEmpty) {
        return AIActionResult(
          action: AIAction.location,
          message:
              'Getting real-time traffic updates and route information to $destination. Opening Google Maps with live traffic data.',
          executed: true,
          parameters: {
            'searchType': 'traffic+to+$destination',
            'traffic': true,
          },
        );
      }
    }

    // General traffic information
    return const AIActionResult(
      action: AIAction.location,
      message:
          'Opening Google Maps with real-time traffic information for your area. You can see live traffic conditions, accidents, and road closures.',
      executed: true,
      parameters: {'searchType': 'traffic', 'traffic': true},
    );
  }

  /// Handle app navigation commands
  AIActionResult _handleAppNavigationCommand(String message) {
    final lowerMessage = message.toLowerCase();

    // Dashboard
    if (_containsKeywords(lowerMessage, ['dashboard', 'home', 'main'])) {
      return const AIActionResult(
        action: AIAction.appNavigation,
        message: 'Opening dashboard.',
        executed: true,
        route: '/dashboard',
      );
    }

    // Analytics
    if (_containsKeywords(
      lowerMessage,
      ['analytics', 'charts', 'graphs', 'data'],
    )) {
      return const AIActionResult(
        action: AIAction.appNavigation,
        message: 'Switching to analytics view.',
        executed: true,
        route: '/analytics',
      );
    }

    // Fuel section
    if (_containsKeywords(
      lowerMessage,
      ['fuel', 'gas', 'petrol', 'log fuel'],
    )) {
      return const AIActionResult(
        action: AIAction.appNavigation,
        message: 'Opening fuel entry screen.',
        executed: true,
        route: '/fuel-entry',
      );
    }

    // Service scheduling
    if (_containsKeywords(lowerMessage, ['service', 'maintenance', 'repair'])) {
      return const AIActionResult(
        action: AIAction.appNavigation,
        message: 'Opening service scheduler.',
        executed: true,
        route: '/service-scheduler',
      );
    }

    return const AIActionResult(
      action: AIAction.appNavigation,
      message: 'Opening requested section.',
      executed: true,
    );
  }

  /// Handle emergency commands
  AIActionResult _handleEmergencyCommand() {
    return const AIActionResult(
      action: AIAction.location,
      message:
          'Opening Google Maps to locate nearest emergency services including hospitals, police stations, and towing services. Please stay safe!',
      executed: true,
      parameters: {'searchType': 'emergency+services', 'emergency': true},
    );
  }

  /// Handle booking/appointment commands
  AIActionResult _handleBookingCommand(String message) {
    final lowerMessage = message.toLowerCase();

    if (_containsKeywords(lowerMessage, ['service', 'maintenance', 'repair'])) {
      String serviceType = 'General Inspection';
      if (_containsKeywords(lowerMessage, ['oil', 'change'])) {
        serviceType = 'Oil Change';
      } else if (_containsKeywords(lowerMessage, ['tire', 'tyre'])) {
        serviceType = 'Tire Rotation';
      } else if (_containsKeywords(lowerMessage, ['brake'])) {
        serviceType = 'Brake Service';
      }

      return AIActionResult(
        action: AIAction.booking,
        message: 'Opening service scheduler. Service type: $serviceType.',
        executed: true,
        route: '/service-scheduler',
        parameters: {'serviceType': serviceType},
      );
    }

    return const AIActionResult(
      action: AIAction.booking,
      message: 'Opening booking system.',
      executed: true,
      route: '/service-scheduler',
    );
  }

  /// Extract destination from navigation command
  String _extractDestination(String message) {
    // Simple extraction - look for common patterns
    final patterns = [
      RegExp(r'navigate to (.+)'),
      RegExp(r'go to (.+)'),
      RegExp(r'take me to (.+)'),
      RegExp(r'find route to (.+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(message.toLowerCase());
      if (match != null && match.groupCount >= 1) {
        return match.group(1)!.trim();
      }
    }

    return '';
  }

  /// Determine search type from location command
  String _determineSearchType(String message) {
    if (_containsKeywords(message, ['petrol', 'gas', 'fuel'])) {
      return 'petrol+pump';
    }
    if (_containsKeywords(message, ['service', 'repair', 'mechanic'])) {
      return 'car+repair+service';
    }
    if (_containsKeywords(message, ['hospital', 'medical', 'emergency'])) {
      return 'hospital';
    }
    if (_containsKeywords(message, ['police', 'station'])) {
      return 'police+station';
    }
    if (_containsKeywords(message, ['tow', 'towing'])) {
      return 'towing+service';
    }
    if (_containsKeywords(message, ['restaurant', 'food'])) {
      return 'restaurant';
    }
    if (_containsKeywords(message, ['hotel', 'lodging'])) {
      return 'hotel';
    }
    if (_containsKeywords(message, ['traffic', 'accident', 'incident'])) {
      return 'traffic+incident';
    }

    return 'car+service'; // Default
  }

  /// Check if message contains any of the keywords
  bool _containsKeywords(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
}

/// Result of an AI action
class AIActionResult {
  final AIAction action;
  final String? message;
  final bool executed;
  final String? route;
  final Map<String, dynamic>? parameters;

  const AIActionResult({
    required this.action,
    this.message,
    required this.executed,
    this.route,
    this.parameters,
  });
}

/// Types of AI actions
enum AIAction {
  none,
  navigate,
  location,
  appNavigation,
  emergency,
  booking,
}

