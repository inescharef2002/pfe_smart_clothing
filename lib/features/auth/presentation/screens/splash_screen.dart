import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slide;
  late Animation<double> _dotFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));

    _fade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.55, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.65, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _slide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic)));
    _dotFade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.65, 1.0, curve: Curves.easeIn));

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // ✅ Rafraîchit le token avant tout accès Firestore
      await user.getIdToken(true);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D0061),
                  Color(0xFF5B21B6),
                  Color(0xFF7C3AED)
                ],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: _decorCircle(200, Colors.white, 0.06),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _decorCircle(280, Colors.white, 0.05),
          ),
          Positioned(
            top: 120,
            left: -40,
            child: _decorCircle(120, Colors.white, 0.04),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Image.asset('assets/images/logo.png',
                            fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        const Text(
                          'Smart Clothing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A D V I S O R',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'Votre style, révélé par l\'IA',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 90),
                FadeTransition(
                  opacity: _dotFade,
                  child: _buildDots(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      );

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1.0),
          duration: Duration(milliseconds: 600 + i * 200),
          curve: Curves.easeInOut,
          builder: (_, v, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: v),
            ),
          ),
        );
      }),
    );
  }
}
