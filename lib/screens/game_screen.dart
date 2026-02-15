import 'package:flutter/material.dart';
import '../main.dart';
import '../services/audio_service.dart';
import 'solo_player_screen.dart';
import 'multiplayer_screen.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with RouteAware {
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    AudioService.playBackgroundMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    AudioService.stopMusic();
    super.dispose();
  }

  // Auto tigil pag may ibang screen na nag-push sa taas
  @override
  void didPushNext() {
    if (!_isMuted) {
      AudioService.pauseMusic();
    }
  }

  // Auto resume pag bumalik dito
  @override
  void didPopNext() {
    if (!_isMuted) {
      AudioService.resumeMusic();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        AudioService.pauseMusic();
      } else {
        AudioService.resumeMusic();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ===== MAIN CONTENT =====
              Column(
                children: [
                  const Spacer(flex: 2),

                  // ===== LOGO =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo_memo.png',
                          height: 120,
                          width: 120,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Memory Match!',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const Text(
                          'GAME',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            letterSpacing: 8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ===== MENU BUTTONS =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      children: [
                        _MenuButton(
                          icon: Icons.person,
                          label: 'Solo Player',
                          color: const Color(0xFF00B4D8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SoloPlayerScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _MenuButton(
                          icon: Icons.group,
                          label: 'Multiplayer',
                          color: const Color(0xFF48CAE4),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MultiplayerScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _MenuButton(
                          icon: Icons.settings,
                          label: 'Settings',
                          color: const Color(0xFF90E0EF),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              ),

              // ===== MUTE / UNMUTE BUTTON (top-right) =====
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _toggleMute,
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== REUSABLE MENU BUTTON =====
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
