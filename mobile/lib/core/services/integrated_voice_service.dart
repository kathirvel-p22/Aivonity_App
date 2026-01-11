import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'google_speech_service.dart';
import 'enhanced_tts_service.dart';
import 'voice_command_service.dart';

/// Integrated Voice Service
/// Combines speech-to-text, text-to-speech, and voice command processing
/// for a complete voice interaction experience
class IntegratedVoiceService extends ChangeNotifier {
  static IntegratedVoiceService? _instance;
  static IntegratedVoiceService get instance =>
      _instance ??= IntegratedVoiceService._();

  IntegratedVoiceService._();

  final Logger _logger = Logger();

  // Service instances
  late final GoogleSpeechService _speechService;
  late final EnhancedTtsService _ttsService;
  late final VoiceCommandService _commandService;

  // State
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  String _currentLanguage = 'en-US';
  VoiceInteractionMode _mode = VoiceInteractionMode.conversational;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isProcessing => _isProcessing;
  String get currentLanguage => _currentLanguage;
  VoiceInteractionMode get mode => _mode;

  /// Initialize all voice services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('Initializing Integrated Voice Service...');

      // Initialize individual services
      _speechService = GoogleSpeechService.instance;
      _ttsService = EnhancedTtsService.instance;
      _commandService = VoiceCommandService.instance;

      await _speechService.initialize();
      await _ttsService.initialize();

      // Set up listeners
      _speechService.addListener(_onSpeechServiceUpdate);
      _ttsService.addListener(_onTtsServiceUpdate);

      _isInitialized = true;
      _logger.i('Integrated Voice Service initialized successfully');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to initialize Integrated Voice Service: $e');
      throw VoiceServiceException('Initialization failed: $e');
    }
  }

  /// Start voice interaction session
  Future<VoiceInteractionResult> startVoiceInteraction({
    VoiceInteractionMode? mode,
    String? languageCode,
    Duration? timeout,
  }) async {
    if (!_isInitialized) {
      throw const VoiceServiceException('Service not initialized');
    }

    if (_isListening || _isSpeaking) {
      throw const VoiceServiceException(
        'Voice interaction already in progress',
      );
    }

    try {
      _logger.i('Starting voice interaction...');

      // Set mode and language
      if (mode != null) _mode = mode;
      if (languageCode != null) {
        await setLanguage(languageCode);
      }

      // Start listening
      final success = await _speechService.startRecording();
      if (!success) {
        throw const VoiceServiceException('Failed to start voice recording');
      }

      _isListening = true;
      notifyListeners();

      // Wait for speech recognition to complete or timeout
      final speechResult = await _speechService.stopRecordingAndProcess();

      _isListening = false;
      _isProcessing = true;
      notifyListeners();

      if (!speechResult.success) {
        _isProcessing = false;
        notifyListeners();
        return VoiceInteractionResult(
          success: false,
          error: speechResult.error ?? 'Speech recognition failed',
        );
      }

      // Process the recognized speech
      final result = await _processRecognizedSpeech(speechResult);

      _isProcessing = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isListening = false;
      _isProcessing = false;
      notifyListeners();

      _logger.e('Voice interaction failed: $e');
      return VoiceInteractionResult(
        success: false,
        error: 'Voice interaction failed: $e',
      );
    }
  }

  /// Process recognized speech based on current mode
  Future<VoiceInteractionResult> _processRecognizedSpeech(
    GoogleSpeechResult speechResult,
  ) async {
    try {
      final transcript = speechResult.transcript.trim();
      if (transcript.isEmpty) {
        return const VoiceInteractionResult(
          success: false,
          error: 'No speech detected',
        );
      }

      _logger.i('Processing recognized speech: $transcript');

      switch (_mode) {
        case VoiceInteractionMode.command:
          return await _processVoiceCommand(transcript);

        case VoiceInteractionMode.conversational:
          return await _processConversationalInput(transcript);

        case VoiceInteractionMode.dictation:
          return VoiceInteractionResult(
            success: true,
            transcript: transcript,
            confidence: speechResult.confidence,
          );
      }
    } catch (e) {
      _logger.e('Failed to process recognized speech: $e');
      return VoiceInteractionResult(
        success: false,
        error: 'Failed to process speech: $e',
      );
    }
  }

  /// Process voice command
  Future<VoiceInteractionResult> _processVoiceCommand(String transcript) async {
    try {
      final commandResult = await _commandService.processVoiceInput(transcript);

      if (!commandResult.isSuccess) {
        // Fallback to conversational mode
        return await _processConversationalInput(transcript);
      }

      // Execute the command
      final response = await _executeVoiceCommand(commandResult);

      // Speak the response
      if (response.isNotEmpty) {
        await _ttsService.speak(response);
      }

      return VoiceInteractionResult(
        success: true,
        transcript: transcript,
        confidence: commandResult.confidence,
        command: commandResult.command,
        response: response,
        parameters: commandResult.parameters,
      );
    } catch (e) {
      _logger.e('Failed to process voice command: $e');
      return VoiceInteractionResult(
        success: false,
        error: 'Command processing failed: $e',
      );
    }
  }

  /// Process conversational input (AI chat)
  Future<VoiceInteractionResult> _processConversationalInput(
    String transcript,
  ) async {
    try {
      // This would integrate with your AI chat service
      // For now, we'll create a simple response
      final response = await _generateAIResponse(transcript);

      // Speak the AI response
      if (response.isNotEmpty) {
        await _ttsService.speak(response);
      }

      return VoiceInteractionResult(
        success: true,
        transcript: transcript,
        confidence: 0.9, // Default confidence for AI responses
        response: response,
        isAIResponse: true,
      );
    } catch (e) {
      _logger.e('Failed to process conversational input: $e');
      return VoiceInteractionResult(
        success: false,
        error: 'AI processing failed: $e',
      );
    }
  }

  /// Execute voice command and return response
  Future<String> _executeVoiceCommand(VoiceCommandResult commandResult) async {
    switch (commandResult.command) {
      case VoiceCommandType.checkHealth:
        return "I'll check your vehicle's health status. Your vehicle is currently showing a health score of 85%. All major systems are functioning normally.";

      case VoiceCommandType.scheduleMaintenance:
        final serviceType = commandResult.parameters['serviceType'] as String?;
        final timing = commandResult.parameters['timing'] as String?;

        String response = "I'll help you schedule maintenance";
        if (serviceType != null) {
          response += ' for $serviceType';
        }
        if (timing != null) {
          response += ' $timing';
        }
        response += '. Let me find available appointments for you.';
        return response;

      case VoiceCommandType.checkFuelEfficiency:
        return "Your current fuel efficiency is 28.5 MPG, which is 3% better than last month. You're doing great with eco-friendly driving!";

      case VoiceCommandType.findServiceCenter:
        final location = commandResult.parameters['location'] as String?;
        String response = 'I found 5 service centers nearby';
        if (location != null) {
          response += ' in $location';
        }
        response +=
            '. The closest one is AutoCare Plus, 2.3 miles away with a 4.8-star rating.';
        return response;

      case VoiceCommandType.navigate:
        final destination = commandResult.parameters['destination'] as String?;
        if (destination != null) {
          return 'Starting navigation to $destination. The estimated travel time is 15 minutes.';
        }
        return 'Where would you like me to navigate to?';

      case VoiceCommandType.checkAlerts:
        return 'You have 2 active alerts: Low tire pressure in the front right tire, and your next oil change is due in 500 miles.';

      case VoiceCommandType.help:
        return 'I can help you with vehicle health checks, scheduling maintenance, finding service centers, checking fuel efficiency, navigation, vehicle control commands like locking doors and starting engine, climate control, and emergency assistance. What would you like to do?';

      case VoiceCommandType.lockDoors:
        return 'Locking all vehicle doors. Your vehicle is now secured.';

      case VoiceCommandType.unlockDoors:
        return 'Unlocking all vehicle doors. Welcome back!';

      case VoiceCommandType.startEngine:
        return 'Starting the vehicle engine. Please ensure you are in a safe location and have your keys nearby.';

      case VoiceCommandType.stopEngine:
        return 'Stopping the vehicle engine. Please apply the parking brake.';

      case VoiceCommandType.climateControl:
        final action = commandResult.parameters['action'] as String?;
        final temperature = commandResult.parameters['temperature'] as int?;

        String response = 'Climate control ';
        if (action == 'on') {
          response += 'turned on';
        } else if (action == 'off') {
          response += 'turned off';
        } else if (temperature != null) {
          response += 'set to $temperature degrees';
        } else {
          response += 'adjusted';
        }
        response += '. Comfort settings updated.';
        return response;

      case VoiceCommandType.lightsControl:
        final lightType = commandResult.parameters['lightType'] as String?;
        final action = commandResult.parameters['action'] as String?;

        String response = '';
        if (lightType != null && lightType != 'all') {
          response += '$lightType ';
        }
        response += 'lights ';
        response += action == 'on' ? 'turned on' : 'turned off';
        response += '.';
        return response;

      case VoiceCommandType.emergencyCall:
        final emergencyType =
            commandResult.parameters['emergencyType'] as String?;
        String response = 'Emergency call initiated';
        if (emergencyType != null && emergencyType != 'general') {
          response += ' for $emergencyType';
        }
        response +=
            '. Help is on the way. Stay calm and follow safety procedures.';
        return response;

      case VoiceCommandType.hazardLights:
        return 'Hazard warning lights activated. Please pull over to a safe location if needed.';

      default:
        return "I understand you want to ${commandResult.command.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').toLowerCase()}. Let me help you with that.";
    }
  }

  /// Generate AI response with enhanced vehicle context
  Future<String> _generateAIResponse(String input) async {
    try {
      // In a real implementation, integrate with actual AI service
      // For now, provide enhanced mock responses with vehicle context

      final lowerInput = input.toLowerCase();

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (lowerInput.contains('hello') || lowerInput.contains('hi')) {
        return "Hello! I'm your AI vehicle assistant. I can help you with vehicle health, maintenance, troubleshooting, and more. What would you like to know?";
      }

      if (lowerInput.contains('health') || lowerInput.contains('status')) {
        return 'Your vehicle health is looking good! Engine: 95%, Battery: 87%, Brakes: 94%. Next maintenance due in 2,500 miles. Would you like more details?';
      }

      if (lowerInput.contains('maintenance') ||
          lowerInput.contains('service')) {
        return "Based on your vehicle's mileage, you're due for an oil change in 2,500 miles and tire rotation in 1,200 miles. I can help you schedule an appointment at a nearby service center.";
      }

      if (lowerInput.contains('fuel') || lowerInput.contains('efficiency')) {
        return 'Your current fuel efficiency is 32.5 MPG, which is above average! Here are some tips to improve it further: maintain steady speeds, keep tires properly inflated, and remove excess weight.';
      }

      if (lowerInput.contains('problem') ||
          lowerInput.contains('issue') ||
          lowerInput.contains('trouble')) {
        return "I'm here to help troubleshoot any vehicle issues. Can you describe what's happening? For example: unusual sounds, warning lights, performance problems, or electrical issues?";
      }

      if (lowerInput.contains('find') ||
          lowerInput.contains('locate') ||
          lowerInput.contains('service center')) {
        return 'I found 5 service centers near you. The closest is AutoCare Plus, 2.3 miles away with a 4.8-star rating. Would you like directions or want to book an appointment?';
      }

      if (lowerInput.contains('thank')) {
        return "You're welcome! I'm always here to help with your vehicle needs. Is there anything else you'd like to know about your car?";
      }

      // Default response with suggestions
      return "I understand you're asking about '${input.length > 30 ? "${input.substring(0, 30)}..." : input}'. I can help with vehicle health checks, maintenance scheduling, troubleshooting, finding service centers, and fuel efficiency tips. What specific information would you like?";
    } catch (e) {
      _logger.e('Error generating AI response: $e');
      return "I apologize, but I'm having trouble processing your request right now. Please try again in a moment.";
    }
  }

  /// Stop current voice interaction
  Future<void> stopVoiceInteraction() async {
    try {
      if (_isListening) {
        await _speechService.cancelRecording();
        _isListening = false;
      }

      if (_isSpeaking) {
        await _ttsService.stop();
        _isSpeaking = false;
      }

      _isProcessing = false;
      notifyListeners();

      _logger.i('Voice interaction stopped');
    } catch (e) {
      _logger.e('Failed to stop voice interaction: $e');
    }
  }

  /// Speak text using TTS
  Future<bool> speak(
    String text, {
    String? languageCode,
    double? speechRate,
    double? pitch,
  }) async {
    if (!_isInitialized) return false;

    try {
      return await _ttsService.speak(
        text,
        languageCode: languageCode ?? _currentLanguage,
        speechRate: speechRate,
        pitch: pitch,
      );
    } catch (e) {
      _logger.e('Failed to speak text: $e');
      return false;
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _ttsService.stop();
    }
  }

  /// Set language for voice interactions
  Future<void> setLanguage(String languageCode) async {
    try {
      _currentLanguage = languageCode;
      _speechService.setLanguage(languageCode);

      // Set TTS voice for the language
      final voices = await _ttsService.getAvailableVoices(languageCode);
      if (voices.isNotEmpty) {
        await _ttsService.setVoice(
          languageCode: languageCode,
          voiceName: voices.first.name,
        );
      }

      _logger.i('Language set to: $languageCode');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to set language: $e');
    }
  }

  /// Set voice interaction mode
  void setMode(VoiceInteractionMode mode) {
    _mode = mode;
    _logger.i('Voice interaction mode set to: ${mode.name}');
    notifyListeners();
  }

  /// Get available languages
  List<VoiceLanguage> getAvailableLanguages() {
    return [
      const VoiceLanguage(code: 'en-US', name: 'English (US)'),
      const VoiceLanguage(code: 'en-GB', name: 'English (UK)'),
      const VoiceLanguage(code: 'es-ES', name: 'Spanish (Spain)'),
      const VoiceLanguage(code: 'es-US', name: 'Spanish (US)'),
      const VoiceLanguage(code: 'fr-FR', name: 'French (France)'),
      const VoiceLanguage(code: 'de-DE', name: 'German (Germany)'),
      const VoiceLanguage(code: 'it-IT', name: 'Italian (Italy)'),
      const VoiceLanguage(code: 'pt-BR', name: 'Portuguese (Brazil)'),
      const VoiceLanguage(code: 'zh-CN', name: 'Chinese (Simplified)'),
      const VoiceLanguage(code: 'ja-JP', name: 'Japanese'),
      const VoiceLanguage(code: 'ko-KR', name: 'Korean'),
    ];
  }

  /// Get available voice commands
  List<VoiceCommandInfo> getAvailableCommands() {
    return _commandService.getAvailableCommands();
  }

  /// Check if service is available
  Future<bool> isAvailable() async {
    try {
      final speechAvailable = await _speechService.isAvailable();
      final ttsAvailable = await _ttsService.isAvailable();
      return speechAvailable && ttsAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Service update listeners
  void _onSpeechServiceUpdate() {
    final wasListening = _isListening;
    _isListening = _speechService.isRecording;

    if (wasListening != _isListening) {
      notifyListeners();
    }
  }

  void _onTtsServiceUpdate() {
    final wasSpeaking = _isSpeaking;
    _isSpeaking = _ttsService.isSpeaking;

    if (wasSpeaking != _isSpeaking) {
      notifyListeners();
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _speechService.removeListener(_onSpeechServiceUpdate);
    _ttsService.removeListener(_onTtsServiceUpdate);
    super.dispose();
  }
}

/// Voice Interaction Modes
enum VoiceInteractionMode {
  command, // Process as voice commands
  conversational, // Process as AI chat
  dictation, // Simple speech-to-text
}

/// Voice Interaction Result
class VoiceInteractionResult {
  final bool success;
  final String? transcript;
  final double confidence;
  final VoiceCommandType? command;
  final String? response;
  final Map<String, dynamic>? parameters;
  final bool isAIResponse;
  final String? error;

  const VoiceInteractionResult({
    required this.success,
    this.transcript,
    this.confidence = 0.0,
    this.command,
    this.response,
    this.parameters,
    this.isAIResponse = false,
    this.error,
  });

  @override
  String toString() {
    return 'VoiceInteractionResult(success: $success, transcript: "$transcript", command: $command)';
  }
}

/// Voice Service Exception
class VoiceServiceException implements Exception {
  final String message;

  const VoiceServiceException(this.message);

  @override
  String toString() => 'VoiceServiceException: $message';
}

/// Voice Language (reused from other services)
class VoiceLanguage {
  final String code;
  final String name;

  const VoiceLanguage({required this.code, required this.name});

  @override
  String toString() => '$name ($code)';
}

