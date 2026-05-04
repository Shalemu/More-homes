import 'package:flutter/material.dart';
import 'package:morehomesapp/core/updates/update_manager.dart';
import 'package:morehomesapp/widget/top_notification.dart';
import 'package:provider/provider.dart';

import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/services/token_storage.dart';
import 'package:morehomesapp/services/auth_services.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:morehomesapp/widget/input_widget.dart';

import 'package:morehomesapp/view/home_screen.dart';
import 'package:morehomesapp/view/register_screen.dart';
import 'package:morehomesapp/view/forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _message;
  bool _isError = false;

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }


Future<void> _login() async {
  final username = _usernameController.text.trim();
  final password = _passwordController.text.trim();


  // VALIDATION

  if (username.isEmpty && password.isEmpty) {
    TopNotification.show(
      context,
      message: "Email and password are required",
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
    return;
  } else if (username.isEmpty) {
    TopNotification.show(
      context,
      message: "Email is required",
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
    return;
  } else if (password.isEmpty) {
    TopNotification.show(
      context,
      message: "Password is required",
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authService = AuthService();
    final response = await authService.login(username, password);

   
    // FORCE UPDATE CHECK (GLOBAL)
   
    UpdateManager.check(
      context,
      msg: response.msg,
    );

  
    // HANDLE API ERROR
   
    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      TopNotification.show(
        context,
        message: response.msg ?? response.detail,
        color: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return;
    }

    
    // DATA VALIDATION
 
    if (response.data == null) {
      TopNotification.show(
        context,
        message: "Login failed. Try again",
        color: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return;
    }


    // SUCCESS LOGIN
   
    final user = response.data!;
    final provider =
        Provider.of<AuthProvider>(context, listen: false);

    final accessToken = response.access ?? '';
    final refreshToken = response.refresh ?? '';

    await TokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    provider.login(user, accessToken, refreshToken);

    if (!mounted) return;

    TopNotification.show(
      context,
      message: response.msg ?? "Signed in successfully",
      color: AppColors.primary,
      icon: Icons.check_circle,
    );

  
    // NAVIGATE TO HOME
   
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    });

  } catch (e) {
    TopNotification.show(
      context,
      message: e.toString(),
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  void _goToSignUp() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RegisterScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: isSmall ? 10 : 30,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  SizedBox(height: isSmall ? 10 : 30),

                  /// LOGO
                  SizedBox(
                    height: size.height * 0.18,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'assets/logo/logo.png',
                        errorBuilder: (_, __, ___) => const Text(
                          'More Homes',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  //  MESSAGE HERE
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isError
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isError
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isError
                                ? Icons.error_outline
                                : Icons.check_circle,
                            color:
                                _isError ? Colors.red : Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isError
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 25),

                  /// CARD
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
                          decoration:
                              inputDecoration('Email', Icons.email),
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

                        const SizedBox(height: 5),

                        //FORGOT PASSWORD
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      const ForgotPasswordScreen(),
                                  transitionsBuilder:
                                      (_, animation, __, child) =>
                                          FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
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

                        const SizedBox(height: 20),

                        /// REGISTER
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

                  SizedBox(height: isSmall ? 20 : 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}