import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyMusicVolume = 'music_volume';
  static const _keySfxVolume = 'sfx_volume';
  static const _keyVibration = 'vibration';

  // Gamitin natin nullable, hindi late
  static SharedPreferences? _prefs;

  static bool get isReady => _prefs != null;

  /// Tawagan sa main() bago runApp
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===== MUSIC VOLUME =====
  static double get musicVolume {
    return _prefs?.getDouble(_keyMusicVolume) ?? 0.7;
  }

  static Future<void> setMusicVolume(double val) async {
    await _prefs?.setDouble(_keyMusicVolume, val);
  }

  // ===== SFX VOLUME =====
  static double get sfxVolume {
    return _prefs?.getDouble(_keySfxVolume) ?? 0.8;
  }

  static Future<void> setSfxVolume(double val) async {
    await _prefs?.setDouble(_keySfxVolume, val);
  }

  // ===== VIBRATION =====
  static bool get vibration {
    return _prefs?.getBool(_keyVibration) ?? true;
  }

  static Future<void> setVibration(bool val) async {
    await _prefs?.setBool(_keyVibration, val);
  }

  // ===== RESET ALL =====
  static Future<void> resetAll() async {
    await _prefs?.setDouble(_keyMusicVolume, 0.7);
    await _prefs?.setDouble(_keySfxVolume, 0.8);
    await _prefs?.setBool(_keyVibration, true);
  }
}
