import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class SoloPlayerScreen extends StatefulWidget {
  const SoloPlayerScreen({super.key});

  @override
  State<SoloPlayerScreen> createState() => _SoloPlayerScreenState();
}

class _SoloPlayerScreenState extends State<SoloPlayerScreen>
    with TickerProviderStateMixin {
  // Game state
  bool _gameStarted = false;
  bool _gameCompleted = false;
  bool _previewPhase = false;
  int _previewCountdown = 5;
  int _moves = 0;
  int _pairsFound = 0;
  int _totalPairs = 8;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Timer? _previewTimer;

  // Audio state
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  final AudioPlayer _bgmPlayer = AudioPlayer(); // para sa BGM

  // ──────────── SFX POOL (fix para laging tumutunog) ────────────
  static const int _sfxPoolSize = 6;
  final List<AudioPlayer> _sfxPool = [];
  int _sfxPoolIndex = 0;

  // Card state
  List<String> _cardEmojis = [];
  List<bool> _cardFlipped = [];
  List<bool> _cardMatched = [];
  int? _firstFlippedIndex;
  int? _secondFlippedIndex;
  bool _isChecking = false;

  // Animations
  late AnimationController _playButtonController;
  late Animation<double> _playButtonScale;
  late AnimationController _titleController;
  late Animation<double> _titleFade;

  final List<String> _emojiPool = [
    '🐶',
    '🐱',
    '🦊',
    '🐻',
    '🐼',
    '🐸',
    '🦁',
    '🐯',
    '🐨',
    '🐮',
    '🐷',
    '🐙',
    '🦄',
    '🐝',
    '🦋',
    '🐢',
  ];

  @override
  void initState() {
    super.initState();

    // Create SFX player pool
    for (int i = 0; i < _sfxPoolSize; i++) {
      _sfxPool.add(AudioPlayer());
    }

    _playButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _playButtonScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _playButtonController, curve: Curves.easeInOut),
    );

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _titleFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOut));

    // Start menu BGM
    _playMenuBGM();
  }

  @override
  void dispose() {
    _playButtonController.dispose();
    _titleController.dispose();
    _timer?.cancel();
    _previewTimer?.cancel();
    for (final player in _sfxPool) {
      player.dispose();
    }
    _bgmPlayer.dispose();
    super.dispose();
  }

  // ──────────── SFX POOL HELPER ────────────
  /// Kumuha ng next available AudioPlayer mula sa pool (round-robin)
  AudioPlayer _getNextSfxPlayer() {
    final player = _sfxPool[_sfxPoolIndex];
    _sfxPoolIndex = (_sfxPoolIndex + 1) % _sfxPoolSize;
    return player;
  }

  void _playSfx(String assetPath) {
    if (!_soundEnabled) return;
    final player = _getNextSfxPlayer();
    player.stop(); // itigil kung may tumutunog pa dito
    player.play(AssetSource(assetPath));
  }

  // ──────────── BGM HELPERS ────────────
  Future<void> _playMenuBGM() async {
    if (!_musicEnabled) return;
    await _bgmPlayer.stop();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(0.4);
    await _bgmPlayer.play(AssetSource('audio/game_screen.mp3'));
  }

  Future<void> _playGameBGM() async {
    if (!_musicEnabled) return;
    await _bgmPlayer.stop();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(0.3);
    await _bgmPlayer.play(AssetSource('audio/playing_audio.mp3'));
  }

  Future<void> _stopBGM() async {
    await _bgmPlayer.stop();
  }

  Future<void> _toggleMusic(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await _bgmPlayer.stop();
    } else {
      if (_gameStarted) {
        _playGameBGM();
      } else {
        _playMenuBGM();
      }
    }
  }

  // ──────────── GAME LOGIC ────────────
  void _initializeGame() {
    final random = Random();
    List<String> shuffled = List.from(_emojiPool)..shuffle(random);
    List<String> selected = shuffled.sublist(0, _totalPairs);
    _cardEmojis = [...selected, ...selected]..shuffle(random);

    _cardFlipped = List.filled(_cardEmojis.length, true);
    _cardMatched = List.filled(_cardEmojis.length, false);
    _firstFlippedIndex = null;
    _secondFlippedIndex = null;
    _isChecking = false;
    _moves = 0;
    _pairsFound = 0;
    _elapsedSeconds = 0;
    _gameCompleted = false;
  }

  void _startGame() {
    _initializeGame();
    setState(() {
      _gameStarted = true;
      _previewPhase = true;
      _previewCountdown = 5;
    });

    // Switch from menu BGM to game BGM
    _playGameBGM();

    _previewTimer?.cancel();
    _previewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _previewCountdown--;
      });
      if (_previewCountdown <= 0) {
        timer.cancel();
        _endPreviewAndStartGame();
      }
    });
  }

  void _endPreviewAndStartGame() {
    setState(() {
      _previewPhase = false;
      _cardFlipped = List.filled(_cardEmojis.length, false);
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _goBackToMenu() {
    _timer?.cancel();
    _previewTimer?.cancel();
    setState(() {
      _gameStarted = false;
      _gameCompleted = false;
    });
    _playMenuBGM();
  }

  // ──────────── SOUND EFFECT HELPERS ────────────
  void _playCardTapSound() {
    _playSfx('audio/flip.mp3');
  }

  void _playMatchCorrectSound() {
    _playSfx('audio/correct.mp3');
  }

  void _playMatchWrongSound() {
    _playSfx('audio/wrong.mp3');
  }

  void _playWinSound() {
    _playSfx('audio/winner.mp3');
  }

  void _onCardTap(int index) {
    if (_previewPhase) return;
    if (_isChecking) return;
    if (_cardFlipped[index]) return;
    if (_cardMatched[index]) return;

    _playCardTapSound();

    setState(() {
      _cardFlipped[index] = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _secondFlippedIndex = index;
      _moves++;
      _isChecking = true;

      if (_cardEmojis[_firstFlippedIndex!] ==
          _cardEmojis[_secondFlippedIndex!]) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;

          _playMatchCorrectSound();
          setState(() {
            _cardMatched[_firstFlippedIndex!] = true;
            _cardMatched[_secondFlippedIndex!] = true;
            _pairsFound++;
            _firstFlippedIndex = null;
            _secondFlippedIndex = null;
            _isChecking = false;

            if (_pairsFound == _totalPairs) {
              _gameCompleted = true;
              _timer?.cancel();
            }
          });

          if (_gameCompleted) {
            _stopBGM();
            _playWinSound();
            _showCompletionDialog();
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;

          _playMatchWrongSound();

          setState(() {
            _cardFlipped[_firstFlippedIndex!] = false;
            _cardFlipped[_secondFlippedIndex!] = false;
            _firstFlippedIndex = null;
            _secondFlippedIndex = null;
            _isChecking = false;
          });
        });
      }
    }
  }

  // ──────────── STAR RATING BY TIME ────────────
  String _getStarRating() {
    if (_elapsedSeconds <= 30) return '⭐⭐⭐';
    if (_elapsedSeconds <= 60) return '⭐⭐';
    return '⭐';
  }

  String _getStarLabel() {
    if (_elapsedSeconds <= 30) return 'Perfect!';
    if (_elapsedSeconds <= 60) return 'Great!';
    return 'Good!';
  }

  void _showCompletionDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A1B3D), Color(0xFF44318D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    const Text(
                      'You Win!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Moves: $_moves',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: ${_formatTime(_elapsedSeconds)}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getStarRating(),
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStarLabel(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dialogButton(
                          icon: Icons.home_rounded,
                          label: 'Menu',
                          onTap: () {
                            Navigator.of(context).pop();
                            _goBackToMenu();
                          },
                        ),
                        const SizedBox(width: 16),
                        _dialogButton(
                          icon: Icons.refresh_rounded,
                          label: 'Retry',
                          onTap: () {
                            Navigator.of(context).pop();
                            _startGame();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dialogButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showInGameSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A1B3D), Color(0xFF1A1A2E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '⚙️ Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sound Effects toggle
                  _settingsToggleRow(
                    icon: _soundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    iconColor: _soundEnabled
                        ? Colors.purpleAccent
                        : Colors.white38,
                    label: 'Sound Effects',
                    value: _soundEnabled,
                    onChanged: (val) {
                      setSheetState(() => _soundEnabled = val);
                      setState(() => _soundEnabled = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Music toggle
                  _settingsToggleRow(
                    icon: _musicEnabled
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                    iconColor: _musicEnabled
                        ? Colors.purpleAccent
                        : Colors.white38,
                    label: 'Background Music',
                    value: _musicEnabled,
                    onChanged: (val) {
                      setSheetState(() => _musicEnabled = val);
                      setState(() {});
                      _toggleMusic(val);
                    },
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _settingsToggleRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.purpleAccent,
            activeTrackColor: Colors.purpleAccent.withOpacity(0.4),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  int get _crossAxisCount => 4;

  int get _rowCount => (_totalPairs * 2 / _crossAxisCount).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(child: _gameStarted ? _buildGameUI() : _buildMenuUI()),
    );
  }

  // ──────────────── MENU UI ────────────────
  Widget _buildMenuUI() {
    return FadeTransition(
      opacity: _titleFade,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_memo.png', // <-- palitan ng filename mo
              width: 200,
              height: 200,
            ),
            const Text(
              'Solo Mode',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Match all the pairs!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _menuGridChip('4x3', 6),
                const SizedBox(width: 10),
                _menuGridChip('4x4', 8),
                const SizedBox(width: 10),
                _menuGridChip('4x5', 10),
              ],
            ),
            const SizedBox(height: 32),
            ScaleTransition(
              scale: _playButtonScale,
              child: GestureDetector(
                onTap: _startGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.purpleAccent],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Text(
                    'PLAY',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings button sa menu
            GestureDetector(
              onTap: _showInGameSettingsSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white38),
              label: const Text(
                'Back',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuGridChip(String label, int pairs) {
    bool selected = _totalPairs == pairs;
    return GestureDetector(
      onTap: () {
        setState(() {
          _totalPairs = pairs;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.purpleAccent
                : Colors.white.withOpacity(0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ──────────────── GAME UI ────────────────
  Widget _buildGameUI() {
    int totalCards = _totalPairs * 2;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _goBackToMenu,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white70,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _previewPhase
                      ? Colors.orangeAccent.withOpacity(0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: _previewPhase
                      ? Border.all(color: Colors.orangeAccent.withOpacity(0.5))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _previewPhase
                          ? Icons.visibility_rounded
                          : Icons.timer_outlined,
                      color: _previewPhase
                          ? Colors.orangeAccent
                          : Colors.purpleAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _previewPhase
                          ? 'Memorize! $_previewCountdown'
                          : _formatTime(_elapsedSeconds),
                      style: TextStyle(
                        color: _previewPhase
                            ? Colors.orangeAccent
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showInGameSettingsSheet,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double availableWidth = constraints.maxWidth - 32;
              double availableHeight = constraints.maxHeight - 16;

              int rows = _rowCount;
              int cols = _crossAxisCount;

              double spacing = 10;
              double totalHSpacing = (cols - 1) * spacing;
              double totalVSpacing = (rows - 1) * spacing;

              double cardWidth = (availableWidth - totalHSpacing) / cols;
              double cardHeight = (availableHeight - totalVSpacing) / rows;

              if (cardWidth / cardHeight > 0.85) {
                cardWidth = cardHeight * 0.85;
              } else if (cardHeight > cardWidth / 0.6) {
                cardHeight = cardWidth / 0.6;
              }

              double gridWidth = (cardWidth * cols) + totalHSpacing;
              double gridHeight = (cardHeight * rows) + totalVSpacing;

              return Center(
                child: SizedBox(
                  width: gridWidth,
                  height: gridHeight,
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(totalCards, (index) {
                      return SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _buildCard(index),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                icon: Icons.touch_app_rounded,
                label: 'Moves',
                value: '$_moves',
                color: Colors.orangeAccent,
              ),
              _buildStatCard(
                icon: Icons.favorite_rounded,
                label: 'Pairs',
                value: '$_pairsFound / $_totalPairs',
                color: Colors.pinkAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    bool isFlipped = _cardFlipped[index];
    bool isMatched = _cardMatched[index];
    bool showFace = isFlipped || isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: showFace
              ? LinearGradient(
                  colors: isMatched
                      ? [
                          Colors.green.withOpacity(0.4),
                          Colors.greenAccent.withOpacity(0.2),
                        ]
                      : _previewPhase
                      ? [
                          Colors.orange.withOpacity(0.3),
                          Colors.deepOrange.withOpacity(0.15),
                        ]
                      : [
                          Colors.deepPurple.withOpacity(0.6),
                          Colors.purpleAccent.withOpacity(0.3),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMatched
                ? Colors.greenAccent.withOpacity(0.5)
                : showFace
                ? _previewPhase
                      ? Colors.orangeAccent.withOpacity(0.4)
                      : Colors.purpleAccent.withOpacity(0.6)
                : Colors.white.withOpacity(0.15),
            width: showFace ? 2 : 1,
          ),
          boxShadow: showFace
              ? [
                  BoxShadow(
                    color: isMatched
                        ? Colors.greenAccent.withOpacity(0.2)
                        : _previewPhase
                        ? Colors.orangeAccent.withOpacity(0.15)
                        : Colors.purpleAccent.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: showFace
                ? Text(
                    _cardEmojis[index],
                    key: ValueKey('emoji_${index}_$showFace'),
                    style: const TextStyle(fontSize: 30),
                  )
                : Icon(
                    Icons.question_mark_rounded,
                    key: ValueKey('hidden_${index}_$showFace'),
                    color: Colors.white.withOpacity(0.3),
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }
}
