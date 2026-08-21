import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D0061), Color(0xFF5B21B6), Color(0xFF7C3AED)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: IntroductionScreen(
            pages: [
              PageViewModel(
                title: "Bienvenue sur Smart Clothing Advisor",
                body:
                    "Découvrez un styliste personnel IA qui analyse vos vêtements et suggère des outfits parfaits pour chaque occasion.",
                image: _buildImage('assets/images/j1.webp', isSmall),
                decoration: _pageDecoration(isSmall),
              ),
              PageViewModel(
                title: "Garde-robe Intelligente",
                body:
                    "Uploadez des photos de vos vêtements, analysez les couleurs et motifs, et organisez-les par catégories facilement.",
                image: _buildImage('assets/images/j2.webp', isSmall),
                decoration: _pageDecoration(isSmall),
              ),
              PageViewModel(
                title: "Recommandations Personnalisées",
                body:
                    "Obtenez des outfits adaptés à la météo et à l'occasion, avec des suggestions d'achats durables et tendance.",
                image: _buildImage('assets/images/j3.webp', isSmall),
                decoration: _pageDecoration(isSmall),
              ),
            ],
            onDone: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignUpScreen()),
            ),
            onSkip: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignUpScreen()),
            ),
            showSkipButton: true,
            skip: Text(
              "Passer",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            next: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: isSmall ? 18 : 20,
            ),
            done: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 20,
                vertical: isSmall ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                "Commencer",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6D28D9),
                  fontSize: isSmall ? 14 : 15,
                ),
              ),
            ),
            dotsDecorator: DotsDecorator(
              size: const Size(8, 8),
              activeSize: const Size(22, 8),
              activeColor: Colors.white,
              color: Colors.white.withValues(alpha: 0.35),
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            globalBackgroundColor: Colors.transparent,
            curve: Curves.easeInOut,
            animationDuration: 500,
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path, bool isSmall) {
    final size = isSmall ? 200.0 : 240.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Image.asset(
            path,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom_rounded,
                      size: isSmall ? 60 : 72,
                      color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text('Smart Clothing',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: isSmall ? 12 : 14,
                          fontWeight: FontWeight.w500)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PageDecoration _pageDecoration(bool isSmall) {
    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: isSmall ? 20 : 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
      bodyTextStyle: TextStyle(
        fontSize: isSmall ? 13 : 15,
        color: Colors.white.withValues(alpha: 0.8),
        height: 1.55,
      ),
      imagePadding: EdgeInsets.only(
        top: isSmall ? 30 : 50,
        bottom: isSmall ? 20 : 30,
      ),
      bodyPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 24 : 32,
        vertical: isSmall ? 14 : 18,
      ),
      titlePadding: EdgeInsets.only(
        top: isSmall ? 14 : 18,
        bottom: isSmall ? 6 : 10,
      ),
      pageColor: Colors.transparent,
      contentMargin: EdgeInsets.zero,
      safeArea: 0,
    );
  }
}
