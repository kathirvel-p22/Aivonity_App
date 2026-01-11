import 'package:flutter/material.dart';

/// Application Configuration
/// Contains API keys and configuration settings for AIVONITY app
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // App Information
  static const String appName = 'AIVONITY';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Intelligent Vehicle Assistant Ecosystem';

  // Supported Locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('es', 'ES'), // Spanish
    Locale('fr', 'FR'), // French
    Locale('de', 'DE'), // German
    Locale('zh', 'CN'), // Chinese
  ];

  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isDebugMode => !isProduction;

  // API Keys (In production, these should be loaded from secure storage or environment variables)
  static const String openAIApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: 'your-openai-api-key-here', // Replace with actual key
  );

  static const String googleCloudApiKey = String.fromEnvironment(
    'GOOGLE_CLOUD_API_KEY',
    defaultValue: 'your-google-cloud-api-key-here', // Replace with actual key
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'your-google-maps-api-key-here', // Replace with actual key
  );

  // API Endpoints
  static const String baseApiUrl = String.fromEnvironment(
    'BASE_API_URL',
    defaultValue: 'https://api.aivonity.com/v1',
  );

  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'wss://ws.aivonity.com',
  );

  // Voice Service Configuration
  static const Duration voiceTimeoutDuration = Duration(seconds: 30);
  static const Duration voicePauseDuration = Duration(seconds: 3);
  static const double voiceConfidenceThreshold = 0.6;

  // TTS Configuration
  static const double defaultSpeechRate = 1.0;
  static const double defaultPitch = 0.0;
  static const double defaultVolumeGainDb = 0.0;

  // Chat Configuration
  static const int maxChatHistoryLength = 50;
  static const Duration chatTypingDelay = Duration(milliseconds: 1500);

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Feature Flags
  static const bool enableVoiceInteraction = bool.fromEnvironment(
    'ENABLE_VOICE',
    defaultValue: true,
  );
  static const bool enableAIChat = bool.fromEnvironment(
    'ENABLE_AI_CHAT',
    defaultValue: true,
  );
  static const bool enableRealTimeData = bool.fromEnvironment(
    'ENABLE_REALTIME',
    defaultValue: true,
  );
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  // Validation
  static bool get hasValidOpenAIKey =>
      openAIApiKey.isNotEmpty && openAIApiKey != 'your-openai-api-key-here';
  static bool get hasValidGoogleCloudKey =>
      googleCloudApiKey.isNotEmpty &&
      googleCloudApiKey != 'your-google-cloud-api-key-here';
  static bool get hasValidGoogleMapsKey =>
      googleMapsApiKey.isNotEmpty &&
      googleMapsApiKey != 'your-google-maps-api-key-here';

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': environment,
      'hasOpenAIKey': hasValidOpenAIKey,
      'hasGoogleCloudKey': hasValidGoogleCloudKey,
      'hasGoogleMapsKey': hasValidGoogleMapsKey,
      'enableVoiceInteraction': enableVoiceInteraction,
      'enableAIChat': enableAIChat,
      'enableRealTimeData': enableRealTimeData,
      'enableAnalytics': enableAnalytics,
    };
  }
}
