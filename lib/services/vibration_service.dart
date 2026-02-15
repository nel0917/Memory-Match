import 'package:vibration/vibration.dart';
import 'settings_service.dart';

class VibrationService {
  /// Normal vibrate — pag nag-match, nag-tap, etc.
  static Future<void> light() async {
    if (!SettingsService.vibration) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 30);
    }
  }

  /// Medium vibrate — pag nag-match ng cards
  static Future<void> medium() async {
    if (!SettingsService.vibration) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 80);
    }
  }

  /// Strong vibrate — pag nanalo o nag-game over
  static Future<void> heavy() async {
    if (!SettingsService.vibration) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  /// Pattern vibrate — pag celebration
  static Future<void> success() async {
    if (!SettingsService.vibration) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 50, 100, 50, 100, 80]);
    }
  }
}
