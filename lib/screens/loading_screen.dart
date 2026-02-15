import 'package:flutter/material.dart';
import 'game_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  // Logo animation (fade + scale)
  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Progress bar
  late AnimationController _progressController;

  // Title text fade
  late AnimationController _titleController;
  late Animation<double> _titleFade;

  @override
  void initState() {
    super.initState();

    // --- Logo: fade in + scale up ---
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // --- Title: fade in pagkatapos ng logo ---
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeIn));

    // --- Progress bar: simulates loading ---
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Sequence ng animations
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Step 1: Logo lumabas
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));

    // Step 2: Title lumabas
    _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3: Progress bar mag-start
    _progressController.forward();

    // Step 4: Pag tapos ng loading, go to Game Screen
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const GameScreen(),
            transitionDuration: const Duration(milliseconds: 1000),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ====== LOGO ======
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(scale: _logoScale.value, child: child),
                );
              },
              child: Image.asset(
                'assets/images/logo_memo.png', // <-- palitan ng filename mo
                width: 200,
                height: 200,
              ),
            ),

            const SizedBox(height: 30),

            // ====== TITLE ======
            FadeTransition(
              opacity: _titleFade,
              child: const Text(
                'Flip, Find , Fun!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 50),

            // ====== PROGRESS BAR ======
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Column(
                  children: [
                    // Progress bar container
                    Container(
                      width: 250,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 250 * _progressController.value,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Colors.deepPurple, Colors.purpleAccent],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Percentage text
                    Text(
                      '${(_progressController.value * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
