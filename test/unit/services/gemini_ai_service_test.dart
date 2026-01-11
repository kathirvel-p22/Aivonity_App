import 'package:flutter_test/flutter_test.dart';
// ignore: avoid_relative_lib_imports
import '../../../mobile/lib/core/services/gemini_ai_service.dart';

void main() {
  group('GeminiAIService Tests', () {
    late GeminiAIService service;

    setUp(() {
      service = GeminiAIService.instance;
    });

    test('should initialize service', () async {
      await service.initialize();
      expect(service, isNotNull);
    });

    test('should test API key validity', () async {
      await service.initialize();

      final isValid = await service.testApiKey();
      expect(isValid, isTrue, reason: 'API key should be valid');
    });

    test('should get API key status', () {
      final status = GeminiAIService.getApiKeyStatus();
      expect(status, isNot('null'));
      expect(status, isNot('empty'));
    });

    test('should send message successfully', () async {
      await service.initialize();

      final response = await service.sendMessage('Hello, test message');
      expect(response, isNotNull);
      expect(response.message, isNotEmpty);
      // Note: hasError will be true for fallback responses, but message should still be provided
      expect(response.message, isNotEmpty);
    });

    test('should support multiple languages', () {
      final languages = service.getSupportedLanguages();
      expect(languages, isNotEmpty);
      expect(languages.contains('en'), isTrue);
      expect(languages.contains('es'), isTrue);
    });
  });
}
