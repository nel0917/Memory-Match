import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/vibration_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late double _musicVolume;
  late double _sfxVolume;
  late bool _vibration;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Load mula sa saved settings
    _musicVolume = SettingsService.musicVolume;
    _sfxVolume = SettingsService.sfxVolume;
    _vibration = SettingsService.vibration;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // ===== HEADER =====
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ===== SETTINGS CONTENT =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // ===== AUDIO SECTION =====
                        _buildSectionHeader(
                          icon: Icons.music_note_rounded,
                          title: 'Audio',
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          children: [
                            _buildSliderTile(
                              icon: Icons.library_music_rounded,
                              label: 'Music Volume',
                              value: _musicVolume,
                              activeColor: const Color(0xFF00B4D8),
                              onChanged: (val) {
                                setState(() => _musicVolume = val);
                                SettingsService.setMusicVolume(val);
                                AudioService.setVolume(val);
                              },
                            ),
                            Divider(
                              color: Colors.white.withOpacity(0.1),
                              height: 1,
                            ),
                            _buildSliderTile(
                              icon: Icons.surround_sound_rounded,
                              label: 'SFX Volume',
                              value: _sfxVolume,
                              activeColor: const Color(0xFF48CAE4),
                              onChanged: (val) {
                                setState(() => _sfxVolume = val);
                                SettingsService.setSfxVolume(val);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ===== GAMEPLAY SECTION =====
                        _buildSectionHeader(
                          icon: Icons.gamepad_rounded,
                          title: 'Gameplay',
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          children: [
                            _buildSwitchTile(
                              icon: Icons.vibration_rounded,
                              label: 'Vibration',
                              value: _vibration,
                              activeColor: const Color(0xFF90E0EF),
                              onChanged: (val) {
                                setState(() => _vibration = val);
                                SettingsService.setVibration(val);
                                // Test vibrate para maramdaman agad
                                if (val) VibrationService.medium();
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ===== ABOUT SECTION =====
                        _buildSectionHeader(
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          children: [
                            _buildInfoTile(
                              icon: Icons.videogame_asset_rounded,
                              label: 'Game',
                              value: 'Memory Match!',
                            ),
                            Divider(
                              color: Colors.white.withOpacity(0.1),
                              height: 1,
                            ),
                            _buildInfoTile(
                              icon: Icons.update_rounded,
                              label: 'Version',
                              value: '1.0.0',
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ===== RESET BUTTON =====
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _showResetDialog,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text(
                              'Reset to Defaults',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(
                                0.25,
                              ),
                              foregroundColor: Colors.redAccent.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.redAccent.withOpacity(0.4),
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00B4D8), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF90E0EF),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String label,
    required double value,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: activeColor, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: activeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: activeColor.withOpacity(0.2),
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.15),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: activeColor, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF48CAE4), size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          'Reset Settings?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset all settings to their default values.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              await SettingsService.resetAll();
              setState(() {
                _musicVolume = 0.7;
                _sfxVolume = 0.8;
                _vibration = true;
              });
              AudioService.setVolume(0.7);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
