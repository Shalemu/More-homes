import 'package:flutter/material.dart';
import 'package:morehousesapp/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:morehousesapp/providers/auth_providers.dart';
import 'package:morehousesapp/services/auth_services.dart';
import 'package:morehousesapp/theme/app_color.dart';
import 'package:morehousesapp/theme/app_text.dart';
import 'package:morehousesapp/widget/input_widget.dart';
import '../config/app_routes.dart';
import '../theme/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() =>
      setState(() => _obscurePassword = !_obscurePassword);

  void _goToSignUp() => Navigator.of(context).pushNamed(AppRoutes.registration);

  void _goToForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset coming soon.')),
    );
  }

  void _showPopupNotification(String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showPopupNotification(
        "Please enter both username and password.",
        AppColors.accent,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final authRes = await authService.login(username, password);

      if (!mounted) return;

      if (authRes.statusCode == 200 || authRes.statusCode == 201) {
        Provider.of<AuthProvider>(context, listen: false).login(
          authRes.data as UserModel,
          authRes.access as String,
          authRes.refresh as String,
        );
        _showPopupNotification("Login successful!", AppColors.primary);
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        _showPopupNotification(
          authRes.detail ?? 'Login failed.',
          AppColors.accent,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Exception occurred: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showPopupNotification(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red.shade700,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2F3), Color(0xFFDDE2E4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LOGO
                const SizedBox(height: 60),
                Hero(
                  tag: "app_logo",
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        'assets/logo/faramas_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.home, size: 60),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                const AppText("Welcome Back!", 26, fontWeight: FontWeight.bold),
                const SizedBox(height: 8),
                const AppText(
                  "Sign in to continue",
                  16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
                const SizedBox(height: 40),

                // INPUT FIELDS
                Container(
                  padding: const EdgeInsets.all(1),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _usernameController,
                        label: "Username",
                        hintText: 'Username or Email',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 15),
                      AppTextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        label: "Password",
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),

                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _goToForgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // SIGNUP LINK
                GestureDetector(
                  onTap: _goToSignUp,
                  child: const Text.rich(
                    TextSpan(
                      text: "Don’t have an account? ",
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
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
}
