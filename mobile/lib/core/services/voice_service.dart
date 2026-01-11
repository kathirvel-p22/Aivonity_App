import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

/// AIVONITY Voice Service
/// Real voice service with speech-to-text and text-to-speech capabilities
class VoiceService extends ChangeNotifier {
  static VoiceService? _instance;
  static VoiceService get instance => _instance ??= VoiceService._();

  VoiceService._();

  // Speech-to-Text instance
  final SpeechToText _speechToText = SpeechToText();

  // Text-to-Speech instance
  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isAvailable = false;
  String? _lastRecognizedText;
  double _confidence = 0.0;
  List<LocaleName> _availableLocales = [];
  String _currentLocale = 'en-US';

  /// Initialize voice service
  static Future<void> initialize() async {
    try {
      await instance._initializeService();
      instance._isInitialized = true;
      debugPrint('Voice service initialized');
    } catch (e) {
      debugPrint('Failed to initialize voice service: $e');
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isAvailable;
  String? get lastRecognizedText => _lastRecognizedText;
  double get confidence => _confidence;

  Future<void> _initializeService() async {
    try {
      // Request microphone permission
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return;
      }

      // Initialize Speech-to-Text
      final sttAvailable = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'listening') {
            _isListening = true;
          } else if (status == 'notListening') {
            _isListening = false;
          }
          notifyListeners();
        },
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          _isListening = false;
          notifyListeners();
        },
      );

      if (sttAvailable) {
        _availableLocales = await _speechToText.locales();
        debugPrint('Available locales: ${_availableLocales.length}');
      }

      // Initialize Text-to-Speech
      await _flutterTts.setLanguage(_currentLocale);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set TTS callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
        notifyListeners();
      });

      _isAvailable = sttAvailable;
      debugPrint('Voice service initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize voice service: $e');
      _isAvailable = false;
      notifyListeners();
    }
  }

  /// Start listening for speech
  Future<bool> startListening({String? localeId, Duration? timeout}) async {
    if (!_isAvailable || _isListening) {
      return false;
    }

    try {
      // Clear previous results
      _lastRecognizedText = null;
      _confidence = 0.0;

      // Start listening with the specified locale or default
      final locale = localeId ?? _currentLocale;
      await _speechToText.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords;
          _confidence = result.confidence;
          debugPrint(
            'Recognized: ${result.recognizedWords} (${result.confidence})',
          );
          notifyListeners();
        },
        listenFor: timeout ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: locale,
        onSoundLevelChange: (level) {
          // Handle sound level changes for visual feedback
        },
      );

      _isListening = true;
      notifyListeners();

      return true;
    } catch (e) {
      _isListening = false;
      notifyListeners();
      debugPrint('Failed to start listening: $e');
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to stop listening: $e');
    }
  }

  /// Speak text
  Future<bool> speak(
    String text, {
    double? rate,
    double? pitch,
    double? volume,
    String? language,
  }) async {
    if (!_isAvailable || text.isEmpty) {
      return false;
    }

    try {
      // Set TTS parameters if provided
      if (language != null) {
        await _flutterTts.setLanguage(language);
      }
      if (rate != null) {
        await _flutterTts.setSpeechRate(rate);
      }
      if (pitch != null) {
        await _flutterTts.setPitch(pitch);
      }
      if (volume != null) {
        await _flutterTts.setVolume(volume);
      }

      // Speak the text
      final result = await _flutterTts.speak(text);
      debugPrint('TTS Result: $result for text: $text');

      return result == 1; // 1 indicates success
    } catch (e) {
      _isSpeaking = false;
      notifyListeners();
      debugPrint('Failed to speak: $e');
      return false;
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to stop speaking: $e');
    }
  }

  /// Get available languages
  Future<List<VoiceLanguage>> getAvailableLanguages() async {
    try {
      // Get available TTS languages
      final ttsLanguages = await _flutterTts.getLanguages;
      final List<VoiceLanguage> languages = [];

      // Convert available locales to VoiceLanguage objects
      for (final locale in _availableLocales) {
        languages.add(
          VoiceLanguage(
            code: locale.localeId,
            name: locale.name,
          ),
        );
      }

      // If no STT locales available, provide common languages
      if (languages.isEmpty) {
        return [
          const VoiceLanguage(code: 'en-US', name: 'English (US)'),
          const VoiceLanguage(code: 'en-GB', name: 'English (UK)'),
          const VoiceLanguage(code: 'es-ES', name: 'Spanish (Spain)'),
          const VoiceLanguage(code: 'fr-FR', name: 'French (France)'),
          const VoiceLanguage(code: 'de-DE', name: 'German (Germany)'),
          const VoiceLanguage(code: 'zh-CN', name: 'Chinese (Simplified)'),
        ];
      }

      return languages;
    } catch (e) {
      debugPrint('Failed to get available languages: $e');
      return [
        const VoiceLanguage(code: 'en-US', name: 'English (US)'),
      ];
    }
  }

  /// Check if language is available
  Future<bool> isLanguageAvailable(String languageCode) async {
    final languages = await getAvailableLanguages();
    return languages.any((lang) => lang.code == languageCode);
  }

  /// Set current language
  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
      _currentLocale = languageCode;
      debugPrint('Language set to: $languageCode');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set language: $e');
    }
  }

  /// Get current language
  String getCurrentLanguage() => _currentLocale;

  /// Process voice command
  Future<VoiceCommandResult> processVoiceCommand(String text) async {
    try {
      final command = _parseCommand(text.toLowerCase());
      return VoiceCommandResult(
        command: command,
        confidence: _confidence,
        originalText: text,
        isSuccess: true,
      );
    } catch (e) {
      return VoiceCommandResult(
        command: VoiceCommand.unknown,
        confidence: 0.0,
        originalText: text,
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  VoiceCommand _parseCommand(String text) {
    if (text.contains('health') || text.contains('check')) {
      return VoiceCommand.checkHealth;
    } else if (text.contains('maintenance') || text.contains('service')) {
      return VoiceCommand.scheduleMaintenance;
    } else if (text.contains('fuel') || text.contains('efficiency')) {
      return VoiceCommand.checkFuelEfficiency;
    } else if (text.contains('book') || text.contains('appointment')) {
      return VoiceCommand.bookService;
    } else if (text.contains('find') || text.contains('locate')) {
      return VoiceCommand.findServiceCenter;
    } else if (text.contains('navigate') || text.contains('directions')) {
      return VoiceCommand.navigate;
    } else {
      return VoiceCommand.unknown;
    }
  }

  /// Get voice settings
  VoiceSettings getSettings() {
    return VoiceSettings(
      language: _currentLocale,
      speechRate: 0.5,
      pitch: 1.0,
      volume: 1.0,
      autoListen: false,
      wakeWordEnabled: false,
    );
  }

  /// Update voice settings
  Future<void> updateSettings(VoiceSettings settings) async {
    try {
      await _flutterTts.setLanguage(settings.language);
      await _flutterTts.setSpeechRate(settings.speechRate);
      await _flutterTts.setPitch(settings.pitch);
      await _flutterTts.setVolume(settings.volume);

      _currentLocale = settings.language;
      debugPrint('Voice settings updated: ${settings.language}');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update voice settings: $e');
    }
  }

  /// Get available TTS voices for current language
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(voices as List);
    } catch (e) {
      debugPrint('Failed to get available voices: $e');
      return [];
    }
  }

  /// Set TTS voice
  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
      debugPrint('Voice set to: ${voice['name']}');
    } catch (e) {
      debugPrint('Failed to set voice: $e');
    }
  }

  /// Check if speech recognition is available
  bool get isSpeechRecognitionAvailable => _speechToText.isAvailable;

  /// Check if TTS is available
  Future<bool> get isTtsAvailable async {
    try {
      final languages = await _flutterTts.getLanguages;
      return (languages as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clear recognition history
  void clearHistory() {
    _lastRecognizedText = null;
    _confidence = 0.0;
    notifyListeners();
  }
}

/// Voice Language Model
class VoiceLanguage {
  final String code;
  final String name;

  const VoiceLanguage({required this.code, required this.name});

  @override
  String toString() => '$name ($code)';
}

/// Voice Command Result
class VoiceCommandResult {
  final VoiceCommand command;
  final double confidence;
  final String originalText;
  final bool isSuccess;
  final String? error;

  const VoiceCommandResult({
    required this.command,
    required this.confidence,
    required this.originalText,
    required this.isSuccess,
    this.error,
  });
}

/// Voice Commands Enum
enum VoiceCommand {
  checkHealth,
  scheduleMaintenance,
  checkFuelEfficiency,
  bookService,
  findServiceCenter,
  navigate,
  unknown,
}

/// Voice Settings Model
class VoiceSettings {
  final String language;
  final double speechRate;
  final double pitch;
  final double volume;
  final bool autoListen;
  final bool wakeWordEnabled;

  const VoiceSettings({
    required this.language,
    required this.speechRate,
    required this.pitch,
    required this.volume,
    required this.autoListen,
    required this.wakeWordEnabled,
  });

  VoiceSettings copyWith({
    String? language,
    double? speechRate,
    double? pitch,
    double? volume,
    bool? autoListen,
    bool? wakeWordEnabled,
  }) {
    return VoiceSettings(
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      autoListen: autoListen ?? this.autoListen,
      wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
    );
  }
}

