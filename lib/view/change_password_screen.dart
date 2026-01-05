import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:morehomesapp/theme/app_color.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in. Please log in again.')),
        );
        setState(() => _isLoading = false);
        return;
      }

   
      final url = Uri.parse('http://213.199.45.65:9099/auth/user-change-password');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': _oldPasswordController.text.trim(),
          'password': _newPasswordController.text.trim(),
          'confirm_password': _confirmPasswordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['detail'] == 'Password changed successfully') {
        showAnimatedDialog(
          context,
          type: DialogType.success,
          message: 'Your password has been updated successfully!',
          onAction: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      } else {
        showAnimatedDialog(
          context,
          type: DialogType.error,
          message: data['detail'] ?? 'Something went wrong. Please try again.',
        );
      }
    } catch (e) {
      showAnimatedDialog(
        context,
        type: DialogType.error,
        message: 'Error: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth > 600 ? 450 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Logo
                  SizedBox(
                    height: 120,
                    child: Image.asset(
                      'assets/logo/faramas_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'More Homes',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    'Change Your Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 25),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildPasswordField(
                          label: 'Old Password',
                          controller: _oldPasswordController,
                          obscure: _obscureOld,
                          onToggle: () =>
                              setState(() => _obscureOld = !_obscureOld),
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: 18),
                        _buildPasswordField(
                          label: 'New Password',
                          controller: _newPasswordController,
                          obscure: _obscureNew,
                          onToggle: () =>
                              setState(() => _obscureNew = !_obscureNew),
                          icon: Icons.lock,
                        ),
                        const SizedBox(height: 18),
                        _buildPasswordField(
                          label: 'Confirm Password',
                          controller: _confirmPasswordController,
                          obscure: _obscureConfirm,
                          onToggle: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          icon: Icons.lock_reset,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (v != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.lock_open, color: Colors.white),
                            label: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Update Password',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _changePassword,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Back to Profile',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required IconData icon,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.8),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: validator ??
          (v) {
            if (v == null || v.isEmpty) return "Please fill out this field";
            if (label == "New Password" && v.length < 6) {
              return "Password must be at least 6 characters";
            }
            return null;
          },
    );
  }
}

enum DialogType { success, error }

void showAnimatedDialog(
  BuildContext context, {
  required DialogType type,
  required String message,
  VoidCallback? onAction,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AnimatedDialog(
      message: message,
      type: type,
      onAction: onAction,
    ),
  );
}

class _AnimatedDialog extends StatelessWidget {
  final String message;
  final DialogType type;
  final VoidCallback? onAction;

  const _AnimatedDialog({
    Key? key,
    required this.message,
    required this.type,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = type == DialogType.success ? AppColors.primary : Colors.red;
    final icon = type == DialogType.success ? Icons.check_circle : Icons.error;
    final title = type == DialogType.success ? "Success" : "Error";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 70),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction ?? () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
