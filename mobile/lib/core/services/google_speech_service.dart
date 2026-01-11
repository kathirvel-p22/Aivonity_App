import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

/// Google Speech-to-Text Service
/// Integrates with Google Cloud Speech-to-Text API for enhanced voice recognition
class GoogleSpeechService extends ChangeNotifier {
  static GoogleSpeechService? _instance;
  static GoogleSpeechService get instance =>
      _instance ??= GoogleSpeechService._();

  GoogleSpeechService._();

  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _currentRecordingPath;
  String _languageCode = 'en-US';

  // Getters
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  String get languageCode => _languageCode;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Check if recording permission is granted
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _logger.w('Recording permission not granted');
        return;
      }

      _logger.i('Google Speech Service initialized');
    } catch (e) {
      _logger.e('Failed to initialize Google Speech Service: $e');
    }
  }

  /// Start recording audio for speech recognition
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    try {
      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/voice_recording_$timestamp.wav';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 128000,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      notifyListeners();

      _logger.i('Started recording audio');
      return true;
    } catch (e) {
      _logger.e('Failed to start recording: $e');
      return false;
    }
  }

  /// Stop recording and process speech-to-text
  Future<GoogleSpeechResult> stopRecordingAndProcess() async {
    if (!_isRecording || _currentRecordingPath == null) {
      return const GoogleSpeechResult(
        success: false,
        error: 'No active recording',
      );
    }

    try {
      _isRecording = false;
      _isProcessing = true;
      notifyListeners();

      // Stop recording
      await _recorder.stop();
      _logger.i('Stopped recording audio');

      // Process the audio file
      final result = await _processAudioFile(_currentRecordingPath!);

      // Clean up the temporary file
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }

      _isProcessing = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isRecording = false;
      _isProcessing = false;
      notifyListeners();

      _logger.e('Failed to process recording: $e');
      return GoogleSpeechResult(
        success: false,
        error: 'Failed to process recording: $e',
      );
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();

      // Clean up the temporary file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _isRecording = false;
      _isProcessing = false;
      notifyListeners();

      _logger.i('Recording cancelled');
    } catch (e) {
      _logger.e('Failed to cancel recording: $e');
    }
  }

  /// Process audio file with Google Speech-to-Text API
  Future<GoogleSpeechResult> _processAudioFile(String audioPath) async {
    try {
      // Read audio file as bytes
      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();
      final audioBase64 = base64Encode(audioBytes);

      // Prepare request payload
      final requestData = {
        'config': {
          'encoding': 'LINEAR16',
          'sampleRateHertz': 16000,
          'languageCode': _languageCode,
          'enableAutomaticPunctuation': true,
          'enableWordTimeOffsets': false,
          'model': 'latest_long',
          'useEnhanced': true,
        },
        'audio': {
          'content': audioBase64,
        },
      };

      // Make API request
      final response = await _dio.post<Map<String, dynamic>>(
        'https://speech.googleapis.com/v1/speech:recognize',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.googleCloudApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      // Parse response
      final responseData = response.data as Map<String, dynamic>;

      if (responseData.containsKey('results') &&
          responseData['results'] is List &&
          (responseData['results'] as List).isNotEmpty) {
        final results = responseData['results'] as List;
        final firstResult = results.first as Map<String, dynamic>;

        if (firstResult.containsKey('alternatives') &&
            firstResult['alternatives'] is List &&
            (firstResult['alternatives'] as List).isNotEmpty) {
          final alternatives = firstResult['alternatives'] as List;
          final bestAlternative = alternatives.first as Map<String, dynamic>;

          final transcript = bestAlternative['transcript'] as String? ?? '';
          final confidence =
              (bestAlternative['confidence'] as num?)?.toDouble() ?? 0.0;

          _logger.i(
            'Speech recognition successful: $transcript (confidence: $confidence)',
          );

          return GoogleSpeechResult(
            success: true,
            transcript: transcript,
            confidence: confidence,
            alternatives: alternatives
                .map(
                  (alt) => SpeechAlternative(
                    transcript: alt['transcript'] as String? ?? '',
                    confidence: (alt['confidence'] as num?)?.toDouble() ?? 0.0,
                  ),
                )
                .toList(),
          );
        }
      }

      // No speech detected
      return const GoogleSpeechResult(
        success: true,
        transcript: '',
        confidence: 0.0,
        alternatives: [],
      );
    } catch (e) {
      _logger.e('Google Speech API error: $e');
      return GoogleSpeechResult(
        success: false,
        error: 'Speech recognition failed: $e',
      );
    }
  }

  /// Set language for speech recognition
  void setLanguage(String languageCode) {
    _languageCode = languageCode;
    _logger.i('Language set to: $languageCode');
    notifyListeners();
  }

  /// Get supported languages
  List<SpeechLanguage> getSupportedLanguages() {
    return [
      const SpeechLanguage(code: 'en-US', name: 'English (US)'),
      const SpeechLanguage(code: 'en-GB', name: 'English (UK)'),
      const SpeechLanguage(code: 'es-ES', name: 'Spanish (Spain)'),
      const SpeechLanguage(code: 'es-US', name: 'Spanish (US)'),
      const SpeechLanguage(code: 'fr-FR', name: 'French (France)'),
      const SpeechLanguage(code: 'de-DE', name: 'German (Germany)'),
      const SpeechLanguage(code: 'it-IT', name: 'Italian (Italy)'),
      const SpeechLanguage(code: 'pt-BR', name: 'Portuguese (Brazil)'),
      const SpeechLanguage(code: 'zh-CN', name: 'Chinese (Simplified)'),
      const SpeechLanguage(code: 'ja-JP', name: 'Japanese'),
      const SpeechLanguage(code: 'ko-KR', name: 'Korean'),
    ];
  }

  /// Check if service is available
  Future<bool> isAvailable() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}

/// Google Speech Recognition Result
class GoogleSpeechResult {
  final bool success;
  final String transcript;
  final double confidence;
  final List<SpeechAlternative> alternatives;
  final String? error;

  const GoogleSpeechResult({
    required this.success,
    this.transcript = '',
    this.confidence = 0.0,
    this.alternatives = const [],
    this.error,
  });

  @override
  String toString() {
    return 'GoogleSpeechResult(success: $success, transcript: "$transcript", confidence: $confidence)';
  }
}

/// Speech Alternative
class SpeechAlternative {
  final String transcript;
  final double confidence;

  const SpeechAlternative({
    required this.transcript,
    required this.confidence,
  });
}

/// Speech Language
class SpeechLanguage {
  final String code;
  final String name;

  const SpeechLanguage({
    required this.code,
    required this.name,
  });

  @override
  String toString() => '$name ($code)';
}

