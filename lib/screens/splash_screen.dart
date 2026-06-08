// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl =
      AnimationController(vsync: this, duration: 4.seconds)
        ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future.delayed(3200.ms, () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: 600.ms,
        ),
      );
    });
  }

  @override
  void dispose() { _bgCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.bg,
                Color.lerp(AppTheme.bg, const Color(0xFF001428),
                    _bgCtrl.value)!,
              ],
            ),
          ),
          child: Stack(children: [
            // Floating particles
            ..._particles(size),
            // Main content
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Logo circle
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.cyanGrad,
                    boxShadow: AppTheme.cyanGlow,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 46),
                )
                    .animate()
                    .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 700.ms,
                        curve: Curves.elasticOut)
                    .fadeIn(),
                const SizedBox(height: 28),
                // App name with gradient paint
                ShaderMask(
                  shaderCallback: (r) =>
                      AppTheme.cyanGrad.createShader(r),
                  child: Text('DocuAI',
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(color: Colors.white)),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 700.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                Text('AI Document Intelligence',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: AppTheme.textSec,
                          letterSpacing: 2.5,
                          fontSize: 12,
                        ))
                    .animate()
                    .fadeIn(delay: 700.ms),
                const SizedBox(height: 56),
                // Dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 7, height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.6),
                      ),
                    )
                        .animate(
                            delay: (900 + i * 160).ms,
                            onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                            begin: const Offset(0.4, 0.4),
                            end: const Offset(1.2, 1.2),
                            duration: 550.ms,
                            curve: Curves.easeInOut),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _particles(Size size) {
    final positions = [
      [0.08, 0.12], [0.92, 0.10], [0.04, 0.55],
      [0.96, 0.45], [0.25, 0.88], [0.75, 0.85],
      [0.50, 0.04], [0.85, 0.68], [0.15, 0.70],
    ];
    return positions.asMap().entries.map((e) {
      final d = (e.key * 180).ms;
      final s = 3.0 + (e.key % 4) * 2.5;
      final isGold = e.key % 3 == 0;
      return Positioned(
        left: size.width * e.value[0],
        top: size.height * e.value[1],
        child: Container(
          width: s, height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isGold
                ? AppTheme.accent.withOpacity(0.5)
                : AppTheme.primary.withOpacity(0.4),
          ),
        )
            .animate(delay: d, onPlay: (c) => c.repeat(reverse: true))
            .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1.6, 1.6),
                duration: 2200.ms,
                curve: Curves.easeInOut)
            .fadeIn(duration: 600.ms),
      );
    }).toList();
  }
}
