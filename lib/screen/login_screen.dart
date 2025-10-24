import 'package:flutter/material.dart';
import 'package:morehousesapp/models/api_response_model.dart';
import 'package:morehousesapp/models/user_model.dart';
import 'package:morehousesapp/screen/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:morehousesapp/providers/auth_providers.dart';
import 'package:morehousesapp/services/auth_services.dart';
import 'package:morehousesapp/theme/app_color.dart';
import 'package:morehousesapp/widget/input_widget.dart';
import '../config/app_routes.dart';

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
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
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
                color: Colors.white,
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
      final ApiResponse<UserModel> authRes = await authService.login(
        username,
        password,
      );

      if (!mounted) return;

      if (authRes.statusCode == 200 || authRes.statusCode == 201) {
        // Save login info via provider
        final user = authRes.data!;
        Provider.of<AuthProvider>(context, listen: false).login(
          user, // UserModel
          authRes.access ?? '', // access token
          authRes.refresh ?? '', // refresh token
        );

        _showPopupNotification("Login successful!", AppColors.primary);
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        _showPopupNotification(
          authRes.detail.isNotEmpty ? authRes.detail : 'Login failed.',
          AppColors.accent,
        );
      }
    } catch (e) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              SizedBox(
                width: 140,
                height: 140,
                child: Image.asset(
                  'assets/logo/faramas_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        'More Homes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: inputDecoration(
                        'Username or Email',
                        Icons.email,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: inputDecoration(
                        'Password',
                        Icons.lock,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _goToForgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
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
                                elevation: 4,
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
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      },
                      child: Text('home', style: TextStyle(fontSize: 20)),
                    ),

                    const SizedBox(height: 30),
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
            ],
          ),
        ),
      ),
    );
  }
}
