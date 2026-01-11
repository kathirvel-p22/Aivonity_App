import 'package:flutter/services.dart';

/// Service for managing UI sound effects
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  SoundService._internal();

  /// Play a tap sound effect
  Future<void> playTapSound() async {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silent fallback
    }
  }

  /// Play a success sound effect
  Future<void> playSuccessSound() async {
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Silent fallback
    }
  }
}

