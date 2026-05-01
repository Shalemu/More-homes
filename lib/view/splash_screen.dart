import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:morehomesapp/theme/app_color.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/view/home_screen.dart';
import 'package:morehomesapp/view/login_screen.dart';
import 'package:morehomesapp/view/onboarding_screen.dart';
import 'package:morehomesapp/utils/app_session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  int _dotIndex = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();

  
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scale = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();


    _dotTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) {
        if (!mounted) return;
        setState(() {
          _dotIndex = (_dotIndex + 1) % 3;
        });
      },
    );

 
    Future.delayed(const Duration(seconds: 2), _navigateUser);
  }

Future<void> _navigateUser() async {
  if (!mounted) return;

  final auth = Provider.of<AuthProvider>(context, listen: false);

  // Load saved session
  await auth.loadUserFromPrefs();

  // First install
  final isFirstInstall = await AppSession.isFirstInstall();
  if (isFirstInstall) {
    await AppSession.setNotFirstInstall();
    _go(const OnboardingScreen());
    return;
  }

  // Not logged in
  if (!auth.isAuthenticated) {
    _go(const LoginScreen());
    return;
  }


  final isValid = await auth.checkAuthStatus();

  if (!isValid) {
   
    await auth.logout(); // make sure this clears token + user

    _go(const LoginScreen());
    return;
  }


  _go(const HomeScreen());
}

  void _go(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ---------------- DOT UI ----------------
  Widget _dot(int index) {
    final active = _dotIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _controller.dispose();
    super.dispose();
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
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Opacity(
                    opacity: _fade.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 180,
                  height: 180,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, _dot),
              ),
            ],
          ),
        ),
      ),
    );
  }
}