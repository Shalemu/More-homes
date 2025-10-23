import 'package:flutter/material.dart';
import 'package:morehousesapp/theme/app_color.dart';
import 'package:morehousesapp/widget/input_widget.dart';
import 'package:morehousesapp/models/user_model.dart';
import '../services/auth_services.dart';
import '../theme/app_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

  void _showSnackBar(String message, {Color color = AppColors.primary}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _register() async {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final location = lastNameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Validation
    if (email.isEmpty ||
        phone.isEmpty ||
        location.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar("Please fill in all fields.", color: AppColors.danger);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match.", color: AppColors.danger);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = UserModel(
        email: email,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        password: password,
        location: location,
        username: email,
      );

      final authService = AuthService();
      final response = await authService.register(data: user);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar("Registration successful!", color: AppColors.primary);

        // Navigate to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      else {
        _showSnackBar(response.detail, color: AppColors.danger);
      }
    } catch (e, stackTrace) {
      debugPrint('$e $stackTrace');
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 60),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Column(
                children: [
                  AppTextField(
                    controller: firstNameController,
                    hintText: "First Name",
                    label: "First Name",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: lastNameController,
                    hintText: "Last Name",
                    label: "Last Name",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: emailController,
                    hintText: "Enter your email e.g. test@gmail.com",
                    label: "Email",
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: phoneController,
                    hintText: "e.g +25576205....",
                    label: "Phone",
                    icon: Icons.phone,
                  ),

                  const SizedBox(height: 20),
                  AppTextField(
                    controller: passwordController,
                    obscureText: _isPasswordHidden,
                    label: "Password",
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.grey,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),

                  const SizedBox(height: 20),
                  AppTextField(
                    controller: confirmPasswordController,
                    obscureText: _isPasswordHidden,
                    label: "Confirm Password",
                    hintText: 'Confirm Password',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.grey,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 25),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
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
