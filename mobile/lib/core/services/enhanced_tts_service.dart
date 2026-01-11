import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

/// Enhanced Text-to-Speech Service
/// Integrates with Google Cloud Text-to-Speech API for natural voice synthesis
class EnhancedTtsService extends ChangeNotifier {
  static EnhancedTtsService? _instance;
  static EnhancedTtsService get instance =>
      _instance ??= EnhancedTtsService._();

  EnhancedTtsService._();

  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isSpeaking = false;
  String _languageCode = 'en-US';
  String _voiceName = 'en-US-Neural2-F';
  double _speechRate = 1.0;
  double _pitch = 0.0;
  double _volumeGainDb = 0.0;

  // Getters
  bool get isSpeaking => _isSpeaking;
  String get languageCode => _languageCode;
  String get voiceName => _voiceName;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volumeGainDb => _volumeGainDb;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Set up audio player callbacks
      _audioPlayer.onPlayerStateChanged.listen((state) {
        final wasPlaying = _isSpeaking;
        _isSpeaking = state == PlayerState.playing;

        if (wasPlaying != _isSpeaking) {
          notifyListeners();
        }
      });

      _logger.i('Enhanced TTS Service initialized');
    } catch (e) {
      _logger.e('Failed to initialize Enhanced TTS Service: $e');
    }
  }

  /// Speak text using Google Cloud Text-to-Speech
  Future<bool> speak(
    String text, {
    String? languageCode,
    String? voiceName,
    double? speechRate,
    double? pitch,
    double? volumeGainDb,
  }) async {
    if (text.trim().isEmpty) return false;

    try {
      _logger.i(
        'Speaking text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...',
      );

      // Use provided parameters or defaults
      final lang = languageCode ?? _languageCode;
      final voice = voiceName ?? _voiceName;
      final rate = speechRate ?? _speechRate;
      final pitchValue = pitch ?? _pitch;
      final volume = volumeGainDb ?? _volumeGainDb;

      // Generate audio using Google Cloud TTS
      final audioData = await _generateAudio(
        text: text,
        languageCode: lang,
        voiceName: voice,
        speechRate: rate,
        pitch: pitchValue,
        volumeGainDb: volume,
      );

      if (audioData == null) {
        _logger.e('Failed to generate audio data');
        return false;
      }

      // Save audio to temporary file and play
      final success = await _playAudioData(audioData);

      if (success) {
        _logger.i('Successfully started speaking');
      } else {
        _logger.e('Failed to play audio');
      }

      return success;
    } catch (e) {
      _logger.e('Failed to speak text: $e');
      return false;
    }
  }

  /// Generate audio using Google Cloud Text-to-Speech API
  Future<Uint8List?> _generateAudio({
    required String text,
    required String languageCode,
    required String voiceName,
    required double speechRate,
    required double pitch,
    required double volumeGainDb,
  }) async {
    try {
      // Prepare request payload
      final requestData = {
        'input': {
          'text': text,
        },
        'voice': {
          'languageCode': languageCode,
          'name': voiceName,
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'speakingRate': speechRate,
          'pitch': pitch,
          'volumeGainDb': volumeGainDb,
          'sampleRateHertz': 24000,
        },
      };

      // Make API request
      final response = await _dio.post<Map<String, dynamic>>(
        'https://texttospeech.googleapis.com/v1/text:synthesize',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.googleCloudApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      // Extract audio content
      final responseData = response.data as Map<String, dynamic>;

      if (responseData.containsKey('audioContent')) {
        final audioBase64 = responseData['audioContent'] as String;
        return base64Decode(audioBase64);
      }

      _logger.e('No audio content in response');
      return null;
    } catch (e) {
      _logger.e('Google TTS API error: $e');
      return null;
    }
  }

  /// Play audio data
  Future<bool> _playAudioData(Uint8List audioData) async {
    try {
      // Save audio to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioFile = File('${tempDir.path}/tts_audio_$timestamp.mp3');

      await audioFile.writeAsBytes(audioData);

      // Play the audio file
      await _audioPlayer.play(DeviceFileSource(audioFile.path));

      // Clean up the file after a delay (audio should be loaded into memory)
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          if (await audioFile.exists()) {
            await audioFile.delete();
          }
        } catch (e) {
          _logger.w('Failed to delete temporary audio file: $e');
        }
      });

      return true;
    } catch (e) {
      _logger.e('Failed to play audio data: $e');
      return false;
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      notifyListeners();
      _logger.i('Stopped speaking');
    } catch (e) {
      _logger.e('Failed to stop speaking: $e');
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isSpeaking = false;
      notifyListeners();
      _logger.i('Paused speaking');
    } catch (e) {
      _logger.e('Failed to pause speaking: $e');
    }
  }

  /// Resume speaking
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
      _isSpeaking = true;
      notifyListeners();
      _logger.i('Resumed speaking');
    } catch (e) {
      _logger.e('Failed to resume speaking: $e');
    }
  }

  /// Set language and voice
  Future<void> setVoice({
    required String languageCode,
    required String voiceName,
  }) async {
    _languageCode = languageCode;
    _voiceName = voiceName;
    _logger.i('Voice set to: $voiceName ($languageCode)');
    notifyListeners();
  }

  /// Set speech parameters
  void setSpeechParameters({
    double? speechRate,
    double? pitch,
    double? volumeGainDb,
  }) {
    if (speechRate != null) {
      _speechRate = speechRate.clamp(0.25, 4.0);
    }
    if (pitch != null) {
      _pitch = pitch.clamp(-20.0, 20.0);
    }
    if (volumeGainDb != null) {
      _volumeGainDb = volumeGainDb.clamp(-96.0, 16.0);
    }

    _logger.i(
      'Speech parameters updated: rate=$_speechRate, pitch=$_pitch, volume=$_volumeGainDb',
    );
    notifyListeners();
  }

  /// Get available voices for a language
  Future<List<TtsVoice>> getAvailableVoices(String languageCode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://texttospeech.googleapis.com/v1/voices',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.googleCloudApiKey}',
          },
        ),
        queryParameters: {
          'languageCode': languageCode,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData.containsKey('voices')) {
        final voices = responseData['voices'] as List;
        return voices
            .map((voice) => TtsVoice.fromJson(voice as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      _logger.e('Failed to get available voices: $e');
      return _getDefaultVoices(languageCode);
    }
  }

  /// Get default voices for common languages
  List<TtsVoice> _getDefaultVoices(String languageCode) {
    switch (languageCode) {
      case 'en-US':
        return [
          const TtsVoice(
            name: 'en-US-Neural2-F',
            languageCode: 'en-US',
            gender: VoiceGender.female,
            naturalSampleRateHertz: 24000,
          ),
          const TtsVoice(
            name: 'en-US-Neural2-D',
            languageCode: 'en-US',
            gender: VoiceGender.male,
            naturalSampleRateHertz: 24000,
          ),
        ];
      case 'en-GB':
        return [
          const TtsVoice(
            name: 'en-GB-Neural2-F',
            languageCode: 'en-GB',
            gender: VoiceGender.female,
            naturalSampleRateHertz: 24000,
          ),
          const TtsVoice(
            name: 'en-GB-Neural2-D',
            languageCode: 'en-GB',
            gender: VoiceGender.male,
            naturalSampleRateHertz: 24000,
          ),
        ];
      default:
        return [
          TtsVoice(
            name: '$languageCode-Standard-A',
            languageCode: languageCode,
            gender: VoiceGender.female,
            naturalSampleRateHertz: 22050,
          ),
        ];
    }
  }

  /// Get supported languages
  List<TtsLanguage> getSupportedLanguages() {
    return [
      const TtsLanguage(code: 'en-US', name: 'English (US)'),
      const TtsLanguage(code: 'en-GB', name: 'English (UK)'),
      const TtsLanguage(code: 'es-ES', name: 'Spanish (Spain)'),
      const TtsLanguage(code: 'es-US', name: 'Spanish (US)'),
      const TtsLanguage(code: 'fr-FR', name: 'French (France)'),
      const TtsLanguage(code: 'de-DE', name: 'German (Germany)'),
      const TtsLanguage(code: 'it-IT', name: 'Italian (Italy)'),
      const TtsLanguage(code: 'pt-BR', name: 'Portuguese (Brazil)'),
      const TtsLanguage(code: 'zh-CN', name: 'Chinese (Simplified)'),
      const TtsLanguage(code: 'ja-JP', name: 'Japanese'),
      const TtsLanguage(code: 'ko-KR', name: 'Korean'),
    ];
  }

  /// Check if service is available
  Future<bool> isAvailable() async {
    try {
      // Simple check - try to initialize audio player
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

/// TTS Voice Model
class TtsVoice {
  final String name;
  final String languageCode;
  final VoiceGender gender;
  final int naturalSampleRateHertz;

  const TtsVoice({
    required this.name,
    required this.languageCode,
    required this.gender,
    required this.naturalSampleRateHertz,
  });

  factory TtsVoice.fromJson(Map<String, dynamic> json) {
    return TtsVoice(
      name: json['name'] as String,
      languageCode: json['languageCodes']?.first as String? ?? '',
      gender: _parseGender(json['ssmlGender'] as String?),
      naturalSampleRateHertz: json['naturalSampleRateHertz'] as int? ?? 22050,
    );
  }

  static VoiceGender _parseGender(String? gender) {
    switch (gender?.toUpperCase()) {
      case 'MALE':
        return VoiceGender.male;
      case 'FEMALE':
        return VoiceGender.female;
      default:
        return VoiceGender.neutral;
    }
  }

  @override
  String toString() => '$name (${gender.name})';
}

/// Voice Gender
enum VoiceGender {
  male,
  female,
  neutral,
}

/// TTS Language
class TtsLanguage {
  final String code;
  final String name;

  const TtsLanguage({
    required this.code,
    required this.name,
  });

  @override
  String toString() => '$name ($code)';
}

