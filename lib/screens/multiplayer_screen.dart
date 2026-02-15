import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import '../services/vibration_service.dart';

class MultiplayerScreen extends StatefulWidget {
  final bool isMuted;

  const MultiplayerScreen({super.key, this.isMuted = false});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen>
    with TickerProviderStateMixin {
  // Game state
  bool _gameStarted = false;
  bool _gameCompleted = false;
  bool _previewPhase = false;
  int _previewCountdown = 5;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Timer? _previewTimer;

  // Player state
  int _currentPlayer = 1; // 1 or 2
  int _player1Score = 0;
  int _player2Score = 0;
  int _player1Moves = 0;
  int _player2Moves = 0;
  int _totalPairs = 8;

  // Audio
  late bool _isMuted;
  final AudioPlayer _bgmPlayer = AudioPlayer();
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

  // Player colors
  final Color _player1Color = const Color(0xFF00B4D8);
  final Color _player2Color = const Color(0xFFFF6B6B);

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
    _isMuted = widget.isMuted;

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

  // ──────────── SFX ────────────
  AudioPlayer _getNextSfxPlayer() {
    final player = _sfxPool[_sfxPoolIndex];
    _sfxPoolIndex = (_sfxPoolIndex + 1) % _sfxPoolSize;
    return player;
  }

  void _playSfx(String assetPath) {
    if (_isMuted) return;
    final player = _getNextSfxPlayer();
    player.stop();
    player.play(AssetSource(assetPath));
  }

  // ──────────── BGM ────────────
  Future<void> _playMenuBGM() async {
    if (_isMuted) return;
    await _bgmPlayer.stop();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(0.4);
    await _bgmPlayer.play(AssetSource('audio/game_screen.mp3'));
  }

  Future<void> _playGameBGM() async {
    await _bgmPlayer.stop();
    if (_isMuted) return;
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(0.3);
    await _bgmPlayer.play(AssetSource('audio/playing_audio.mp3'));
  }

  Future<void> _stopBGM() async {
    await _bgmPlayer.stop();
  }

  void _applyMuteState() {
    if (_isMuted) {
      _bgmPlayer.stop();
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
    _currentPlayer = 1;
    _player1Score = 0;
    _player2Score = 0;
    _player1Moves = 0;
    _player2Moves = 0;
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

  void _switchPlayer() {
    setState(() {
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
    });
  }

  void _onCardTap(int index) {
    if (_previewPhase) return;
    if (_isChecking) return;
    if (_cardFlipped[index]) return;
    if (_cardMatched[index]) return;

    _playSfx('audio/flip.mp3');

    setState(() {
      _cardFlipped[index] = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _secondFlippedIndex = index;

      // Count move for current player
      if (_currentPlayer == 1) {
        _player1Moves++;
      } else {
        _player2Moves++;
      }

      _isChecking = true;

      if (_cardEmojis[_firstFlippedIndex!] ==
          _cardEmojis[_secondFlippedIndex!]) {
        // Match found
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;

          _playSfx('audio/correct.mp3');
          VibrationService.medium();
          setState(() {
            _cardMatched[_firstFlippedIndex!] = true;
            _cardMatched[_secondFlippedIndex!] = true;

            if (_currentPlayer == 1) {
              _player1Score++;
            } else {
              _player2Score++;
            }

            _firstFlippedIndex = null;
            _secondFlippedIndex = null;
            _isChecking = false;

            // Check win
            int totalFound = _player1Score + _player2Score;
            if (totalFound == _totalPairs) {
              _gameCompleted = true;
              _timer?.cancel();
            }
          });

          // Same player keeps turn on match!
          if (_gameCompleted) {
            _stopBGM();
            _playSfx('audio/winner.mp3');
            _showCompletionDialog();
          }
        });
      } else {
        // No match — switch player
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;

          _playSfx('audio/wrong.mp3');

          setState(() {
            _cardFlipped[_firstFlippedIndex!] = false;
            _cardFlipped[_secondFlippedIndex!] = false;
            _firstFlippedIndex = null;
            _secondFlippedIndex = null;
            _isChecking = false;
          });

          _switchPlayer();
        });
      }
    }
  }

  // ──────────── RESULT ────────────
  String _getWinnerText() {
    if (_player1Score > _player2Score) return 'Player 1 Wins! 🎉';
    if (_player2Score > _player1Score) return 'Player 2 Wins! 🎉';
    VibrationService.success();
    return "It's a Tie! 🤝";
  }

  Color _getWinnerColor() {
    if (_player1Score > _player2Score) return _player1Color;
    if (_player2Score > _player1Score) return _player2Color;
    return Colors.amberAccent;
  }

  String _getWinnerEmoji() {
    if (_player1Score > _player2Score) return '🏆';
    if (_player2Score > _player1Score) return '🏆';
    return '🤝';
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
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A1B3D), Color(0xFF44318D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getWinnerColor().withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getWinnerColor().withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getWinnerEmoji(),
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getWinnerText(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _getWinnerColor(),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Score summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: _resultPlayerCard(
                                'Player 1',
                                _player1Score,
                                _player1Moves,
                                _player1Color,
                                _player1Score >= _player2Score,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: _resultPlayerCard(
                                'Player 2',
                                _player2Score,
                                _player2Moves,
                                _player2Color,
                                _player2Score >= _player1Score,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Time: ${_formatTime(_elapsedSeconds)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _dialogButton(
                                icon: Icons.home_rounded,
                                label: 'Menu',
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _goBackToMenu();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: _dialogButton(
                                icon: Icons.refresh_rounded,
                                label: 'Rematch',
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _startGame();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _resultPlayerCard(
    String name,
    int score,
    int moves,
    Color color,
    bool isWinner,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(isWinner ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isWinner ? 0.5 : 0.2),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'pairs',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$moves moves',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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

  // ──────────── SETTINGS ────────────
  void _showSettingsSheet() {
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
                  _settingsToggleRow(
                    icon: _isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    iconColor: _isMuted ? Colors.white38 : Colors.purpleAccent,
                    label: 'Sound',
                    value: !_isMuted,
                    onChanged: (val) {
                      setSheetState(() => _isMuted = !val);
                      setState(() => _isMuted = !val);
                      _applyMuteState();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👥', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Multiplayer',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take turns, find the most pairs!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),

              // Player preview
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _playerPreviewChip('Player 1', _player1Color),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _playerPreviewChip('Player 2', _player2Color),
                ],
              ),
              const SizedBox(height: 24),

              // Grid size selection
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

              GestureDetector(
                onTap: _showSettingsSheet,
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
      ),
    );
  }

  Widget _playerPreviewChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
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
    Color activeColor = _currentPlayer == 1 ? _player1Color : _player2Color;

    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _goBackToMenu,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
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
                      size: 18,
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
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showSettingsSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Current player indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: activeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: activeColor.withOpacity(0.5), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: activeColor, size: 20),
              const SizedBox(width: 6),
              Text(
                _previewPhase ? 'Get Ready!' : 'Player $_currentPlayer\'s Turn',
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Card grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double availableWidth = constraints.maxWidth;
                double availableHeight = constraints.maxHeight;

                int rows = _rowCount;
                int cols = _crossAxisCount;

                double spacing = 8;
                double totalHSpacing = (cols - 1) * spacing;
                double totalVSpacing = (rows - 1) * spacing;

                double maxCardWidth = (availableWidth - totalHSpacing) / cols;
                double maxCardHeight = (availableHeight - totalVSpacing) / rows;

                // Pick the smaller dimension to fit everything
                double cardWidth = maxCardWidth;
                double cardHeight = maxCardHeight;

                // Maintain a nice aspect ratio (roughly 3:4)
                double targetRatio = 0.75;
                if (cardWidth / cardHeight > targetRatio) {
                  cardWidth = cardHeight * targetRatio;
                } else {
                  cardHeight = cardWidth / targetRatio;
                }

                // Make sure we don't exceed available space
                double gridWidth = (cardWidth * cols) + totalHSpacing;
                double gridHeight = (cardHeight * rows) + totalVSpacing;

                if (gridWidth > availableWidth) {
                  double scale = availableWidth / gridWidth;
                  cardWidth *= scale;
                  cardHeight *= scale;
                  gridWidth = availableWidth;
                  gridHeight = (cardHeight * rows) + totalVSpacing;
                }

                if (gridHeight > availableHeight) {
                  double scale = availableHeight / gridHeight;
                  cardWidth *= scale;
                  cardHeight *= scale;
                  gridWidth = (cardWidth * cols) + totalHSpacing;
                  gridHeight = availableHeight;
                }

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
                          child: _buildCard(index, cardWidth),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Score bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildPlayerScoreBar(
                  'P1',
                  _player1Score,
                  _player1Moves,
                  _player1Color,
                  _currentPlayer == 1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPlayerScoreBar(
                  'P2',
                  _player2Score,
                  _player2Moves,
                  _player2Color,
                  _currentPlayer == 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerScoreBar(
    String label,
    int score,
    int moves,
    Color color,
    bool isActive,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? color.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score pairs',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '$moves moves',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index, double cardWidth) {
    bool isFlipped = _cardFlipped[index];
    bool isMatched = _cardMatched[index];
    bool showFace = isFlipped || isMatched;

    Color activeColor = _currentPlayer == 1 ? _player1Color : _player2Color;

    // Scale emoji/icon size based on card width
    double emojiSize = (cardWidth * 0.45).clamp(16.0, 32.0);
    double iconSize = (cardWidth * 0.4).clamp(14.0, 28.0);

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
                          activeColor.withOpacity(0.5),
                          activeColor.withOpacity(0.2),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMatched
                ? Colors.greenAccent.withOpacity(0.5)
                : showFace
                ? _previewPhase
                      ? Colors.orangeAccent.withOpacity(0.4)
                      : activeColor.withOpacity(0.6)
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
                        : activeColor.withOpacity(0.2),
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
                    style: TextStyle(fontSize: emojiSize),
                  )
                : Icon(
                    Icons.question_mark_rounded,
                    key: ValueKey('hidden_${index}_$showFace'),
                    color: Colors.white.withOpacity(0.3),
                    size: iconSize,
                  ),
          ),
        ),
      ),
    );
  }
}
