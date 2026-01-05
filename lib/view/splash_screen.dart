import 'dart:async';
import 'package:flutter/material.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:morehomesapp/view/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  int _currentDot = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();

    // LOGO ANIMATION
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    // LOADING DOTS ANIMATION
    _dotTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (timer) {
        if (!mounted) return;
        setState(() {
          _currentDot = (_currentDot + 1) % 3;
        });
      },
    );

    // NAVIGATION
    Future.delayed(const Duration(seconds: 3), _goToNextScreen);
  }

  void _goToNextScreen() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    final bool isActive = _currentDot == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // LOGO (ANIMATED)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),

              const SizedBox(height: 32),

              // LOADING INDICATOR (INSTANT)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, _buildDot),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
