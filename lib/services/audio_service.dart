import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playBackgroundMusic() async {
    await _player.setReleaseMode(ReleaseMode.loop); // para ulit-ulit
    await _player.setVolume(0.5); // 0.0 to 1.0
    await _player.play(AssetSource('audio/game_screen.mp3'));
  }

  static Future<void> stopMusic() async {
    await _player.stop();
  }

  static Future<void> pauseMusic() async {
    await _player.pause();
  }

  static Future<void> resumeMusic() async {
    await _player.resume();
  }

  static Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }
}
