import 'package:flutter/material.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:morehomesapp/widget/input_widget.dart';
import 'package:morehomesapp/models/user_model.dart';
import 'package:morehomesapp/widget/top_notification.dart';
import '../services/auth_services.dart';
import '../config/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+255 ');
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoadingRoles = true;
  List<Map<String, dynamic>> _roles = [];
  int? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    debugPrint("Fetching roles...");
    try {
      final roles = await AuthService().getRoles();
      debugPrint("Fetched roles: $roles");
      setState(() {
        _roles = roles;
        _isLoadingRoles = false;
      });
    } catch (e) {
      debugPrint("Failed to load roles: $e");
      setState(() {
        _isLoadingRoles = false;
        _roles = [];
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void validatePhone(String digits, BuildContext context) {
  if (digits.length < 9) return;

  if (digits.length == 9) {
    TopNotification.show(
      context,
      message: "Valid phone number",
      color: Colors.green,
      icon: Icons.check_circle,
    );
  } else {
    TopNotification.show(
      context,
      message: "Invalid phone number",
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
  }
}
  Future<void> _register() async {
  final firstName = _firstNameController.text.trim();
  final lastName = _lastNameController.text.trim();
  final email = _emailController.text.trim();
  final location = _locationController.text.trim();
  final password = _passwordController.text.trim();

  String phone = _phoneController.text.replaceAll(' ', '').trim();

  // Normalize phone
  if (phone.startsWith('0')) {
    phone = '+255${phone.substring(1)}';
  } else if (phone.startsWith('255')) {
    phone = '+$phone';
  } else if (!phone.startsWith('+255')) {
    phone = '+255$phone';
  }

  debugPrint("Phone after formatting: $phone");

  // Validate phone
  if (!RegExp(r'^\+255\d{9}$').hasMatch(phone)) {
    TopNotification.show(
      context,
      message: "Invalid phone number format",
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
    return;
  }

  // Validate empty fields
  if ([firstName, lastName, email, phone, location, password].any((e) => e.isEmpty)) {
    TopNotification.show(
      context,
      message: "Please fill in all fields",
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
    return;
  }

  if (_selectedRoleId == null) {
    TopNotification.show(
      context,
      message: "Please select a user type",
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final user = UserModel(
      uuid: '',
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      location: location,
      password: password,
      groups: [_selectedRoleId!],
    );

    debugPrint("User object: ${user.toJson()}");

    final authService = AuthService();
    final response = await authService.register(data: user);

    if (response.statusCode == 200 || response.statusCode == 201) {
      TopNotification.show(
        context,
        message: "Registration successful",
        color: AppColors.primary,
        icon: Icons.check_circle,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
    } else {
      TopNotification.show(
        context,
        message: "Registration failed. Try again",
        color: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Register error: $e\n$stackTrace');

    TopNotification.show(
      context,
      message: "Something went wrong. Please try again",
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  String? selectedRoleName() {
    final role = _roles.firstWhere(
      (r) => r['id'] == _selectedRoleId,
      orElse: () => {},
    );
    return role['name']?.toString();
  }
    IconData _roleIcon(String role) {
    final r = role.toLowerCase();
    if (r.contains('premium') || r.contains('vip')) {
      return Icons.workspace_premium;
    }
    if (r.contains('agent') || r.contains('pro')) {
      return Icons.verified;
    }
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20 : 30,
            vertical: 25,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    height: MediaQuery.of(context).size.width * 0.45,
                    child: Image.asset(
                      'assets/logo/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'More Homes',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 400
                                  ? 24
                                  : 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 1.1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 22 : 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                           /// ROLE SECTION (PREMIUM UI)
                  _isLoadingRoles
                      ? const CircularProgressIndicator()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// TITLE + REQUIRED STAR
                            Row(
                              children: const [
                                Text(
                                  "Select Account Type",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "*",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            /// SINGLE ROW SCROLLABLE
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _roles.map((role) {
                                  final isSelected =
                                      _selectedRoleId == role['id'];
                                  final name = role['name'].toString();

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedRoleId = role['id'];
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      width: 160,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withOpacity(
                                                0.12,
                                              )
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// ICON + CHECK
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Icon(
                                                _roleIcon(name),
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : Colors.grey,
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: AppColors.primary,
                                                  size: 18,
                                                ),
                                            ],
                                          ),

                                          const SizedBox(height: 10),

                                          /// ROLE NAME (FROM BACKEND)
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 20),

                  // Form fields
                  _buildTextField(
                    _firstNameController,
                    'First Name',
                    Icons.person,
                  ),
                  _buildTextField(
                    _lastNameController,
                    'Last Name',
                    Icons.person_outline,
                  ),
                  _buildTextField(_emailController, 'Email', Icons.email),
                  _buildPhoneField(),
                  _buildTextField(
                    _locationController,
                    'Location',
                    Icons.location_on,
                  ),
                  _buildPasswordField(),

                  // Show service charge only for owners
                  // if ((selectedRoleName()?.toLowerCase() ?? '') == 'owner')
                  //   _buildTextField(
                  //     _serviceChargeController,
                  //     'Service Charge',
                  //     Icons.monetization_on,
                  //     keyboardType: TextInputType.number,
                  //   ),

                  // const SizedBox(height: 25),

                  // Submit Button
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: inputDecoration(label, icon),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus && _phoneController.text.isEmpty) {
            _phoneController.text = '+255 ';
            _phoneController.selection = TextSelection.fromPosition(
              TextPosition(offset: _phoneController.text.length),
            );
          } else if (!hasFocus &&
              (_phoneController.text.trim() == '+255' ||
                  _phoneController.text.trim() == '+255 ')) {
            _phoneController.clear();
          }
        },
        child: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.number,
          decoration: inputDecoration('Phone Number', Icons.phone),
          onChanged: (value) {
            String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

            if (digits.startsWith('255')) {
              digits = digits.substring(3);
            }

            if (digits.length > 9) {
              digits = digits.substring(0, 9);
            }

            String formatted = '';
            for (int i = 0; i < digits.length; i++) {
              formatted += digits[i];
              if (i == 2 || i == 5) formatted += ' ';
            }

            String finalText = '+255 $formatted'.trim();

            if (_phoneController.text == finalText) return;

            _phoneController.value = TextEditingValue(
              text: finalText,
              selection: TextSelection.collapsed(offset: finalText.length),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
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
    );
  }
}

class _UserTypeCheckbox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UserTypeCheckbox({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
