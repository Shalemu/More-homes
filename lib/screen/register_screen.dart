import 'package:flutter/material.dart';
import 'package:morehousesapp/theme/app_color.dart';
import 'package:morehousesapp/widget/input_widget.dart';
import 'package:morehousesapp/models/user_model.dart';
import '../services/auth_services.dart';
import '../config/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
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

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final location = _locationController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if ([email, phone, firstName, lastName, location, password, confirmPassword]
        .any((element) => element.isEmpty)) {
      _showPopupNotification("Please fill in all fields.", AppColors.accent);
      return;
    }

    if (password != confirmPassword) {
      _showPopupNotification("Passwords do not match.", AppColors.accent);
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
        _showPopupNotification("Registration successful!", AppColors.primary);
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        });
      } else {
        _showPopupNotification(response.detail, AppColors.accent);
      }
    } catch (e, stackTrace) {
      debugPrint('$e $stackTrace');
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
                'Create Account',
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
                      controller: _firstNameController,
                      decoration: inputDecoration('First Name', Icons.person),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _lastNameController,
                      decoration: inputDecoration('Last Name', Icons.person_outline),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _emailController,
                      decoration: inputDecoration('Email', Icons.email),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _phoneController,
                      decoration: inputDecoration('Phone', Icons.phone),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _locationController,
                      decoration: inputDecoration('Location', Icons.location_on),
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
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: inputDecoration('Confirm Password', Icons.lock_outline),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
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
      ),
    );
  }
}
