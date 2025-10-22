import 'package:flutter/material.dart';
import 'package:morehousesapp/theme/app_color.dart';
import 'package:morehousesapp/widget/input_widget.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isPasswordHidden = true;

  void _register() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 100),
            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 60),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: emailController,
                    decoration: inputDecoration("Email", Icons.email),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: phoneController,
                    decoration: inputDecoration("Phone", Icons.phone),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: _isPasswordHidden,
                    decoration: inputDecoration("Password", Icons.lock),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: _isPasswordHidden,
                    decoration:
                        inputDecoration("Confirm Password", Icons.lock),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Sign Up",
                      style:
                          TextStyle(fontSize: 18, color: AppColors.textLight),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Back to Login",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
