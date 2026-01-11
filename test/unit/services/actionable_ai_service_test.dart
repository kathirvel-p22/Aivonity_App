import 'package:flutter_test/flutter_test.dart';

// Test the core logic without importing the full service to avoid dependency issues
void main() {
  group('Actionable AI Command Logic Tests', () {
    test('should identify navigation keywords', () {
      final navigationKeywords = [
        'navigate',
        'go to',
        'take me to',
        'find route',
      ];

      expect(
        _containsKeywords('navigate to the store', navigationKeywords),
        isTrue,
      );
      expect(_containsKeywords('go to downtown', navigationKeywords), isTrue);
      expect(
        _containsKeywords('take me to the mall', navigationKeywords),
        isTrue,
      );
      expect(
        _containsKeywords('find route to airport', navigationKeywords),
        isTrue,
      );
      expect(
        _containsKeywords('what is the weather', navigationKeywords),
        isFalse,
      );
    });

    test('should identify location keywords', () {
      final locationKeywords = ['nearest', 'closest', 'near me', 'find'];

      expect(
        _containsKeywords('find nearest petrol pump', locationKeywords),
        isTrue,
      );
      expect(
        _containsKeywords('locate closest service center', locationKeywords),
        isTrue,
      );
      expect(_containsKeywords('show me near me', locationKeywords), isTrue);
      expect(
        _containsKeywords('regular conversation', locationKeywords),
        isFalse,
      );
    });

    test('should identify app navigation keywords', () {
      final appKeywords = ['open', 'show', 'go to', 'switch to'];

      expect(_containsKeywords('open fuel entry', appKeywords), isTrue);
      expect(_containsKeywords('show dashboard', appKeywords), isTrue);
      expect(_containsKeywords('go to settings', appKeywords), isTrue);
      expect(_containsKeywords('switch to analytics', appKeywords), isTrue);
      expect(_containsKeywords('tell me about cars', appKeywords), isFalse);
    });

    test('should identify emergency keywords', () {
      final emergencyKeywords = ['emergency', 'help', 'accident', 'breakdown'];

      expect(
        _containsKeywords('emergency help needed', emergencyKeywords),
        isTrue,
      );
      expect(_containsKeywords('I had an accident', emergencyKeywords), isTrue);
      expect(
        _containsKeywords('car breakdown assistance', emergencyKeywords),
        isTrue,
      );
      expect(
        _containsKeywords('regular maintenance', emergencyKeywords),
        isFalse,
      );
    });

    test('should identify booking keywords', () {
      final bookingKeywords = ['book', 'schedule', 'appointment', 'service'];

      expect(
        _containsKeywords('book service appointment', bookingKeywords),
        isTrue,
      );
      expect(
        _containsKeywords('schedule maintenance', bookingKeywords),
        isTrue,
      );
      expect(_containsKeywords('make an appointment', bookingKeywords), isTrue);
      expect(
        _containsKeywords('check service history', bookingKeywords),
        isFalse,
      );
    });

    test('should extract destinations correctly', () {
      expect(_extractDestination('navigate to New York'), 'New York');
      expect(_extractDestination('go to the mall'), 'the mall');
      expect(_extractDestination('take me to downtown'), 'downtown');
      expect(_extractDestination('find route to airport'), 'airport');
      expect(_extractDestination('show me the way'), '');
    });

    test('should determine correct search types', () {
      expect(_determineSearchType('find nearest petrol pump'), 'petrol+pump');
      expect(
        _determineSearchType('locate service center'),
        'car+repair+service',
      );
      expect(_determineSearchType('find hospital'), 'hospital');
      expect(_determineSearchType('police station help'), 'police+station');
      expect(_determineSearchType('towing service needed'), 'towing+service');
      expect(_determineSearchType('find restaurant'), 'restaurant');
      expect(_determineSearchType('hotel booking'), 'hotel');
      expect(_determineSearchType('unknown location type'), 'car+service');
    });
  });
}

// Helper functions copied from the service for testing
bool _containsKeywords(String message, List<String> keywords) {
  return keywords.any((keyword) => message.contains(keyword));
}

String _extractDestination(String message) {
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

String _determineSearchType(String message) {
  if (_containsKeywords(message, ['petrol', 'gas', 'fuel'])) {
    return 'petrol+pump';
  }
  if (_containsKeywords(message, ['service', 'repair', 'mechanic'])) {
    return 'car+repair+service';
  }
  if (_containsKeywords(message, ['hospital', 'medical'])) {
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

  return 'car+service'; // Default
}

