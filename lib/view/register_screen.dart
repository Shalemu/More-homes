import 'package:flutter/material.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:morehomesapp/widget/input_widget.dart';
import 'package:morehomesapp/models/user_model.dart';
import '../services/auth_services.dart';
import '../config/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

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
  final _serviceChargeController = TextEditingController();

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
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final location = _locationController.text.trim();
    final password = _passwordController.text.trim();
    final serviceCharge = _serviceChargeController.text.trim();

    String phone = _phoneController.text.replaceAll(' ', '').trim();

    if (!phone.startsWith('+255')) {
      phone = '+255${phone.replaceAll(RegExp(r'^\+?255?'), '')}';
    }

    if (!RegExp(r'^\+2557\d{8}$').hasMatch(phone)) {
      _showPopupNotification(
        'Phone number must start with +2557 and have 9 digits after +255',
        Colors.redAccent,
      );
      return;
    }

    if ([firstName, lastName, email, phone, location, password].any((e) => e.isEmpty)) {
      _showPopupNotification("Please fill in all fields.", Colors.redAccent);
      return;
    }

    if (_selectedRoleId == null) {
      _showPopupNotification("Please select a user type.", Colors.redAccent);
      return;
    }

    final selectedRole = _roles.firstWhere(
      (r) => r['id'] == _selectedRoleId,
      orElse: () => {},
    );

    if ((selectedRole['name']?.toString().toLowerCase() ?? '') == 'owner' &&
        serviceCharge.isEmpty) {
      _showPopupNotification("Please enter service charge for Owners.", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final groups = [_selectedRoleId!];

      final user = UserModel(
        uuid: '',
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        location: location,
        password: password,
        // serviceCharge: (selectedRole['name']?.toString().toLowerCase() == 'owner')
        //     ? serviceCharge
        //     : null,
        groups: groups,
      );

      final authService = AuthService();
      final response = await authService.register(data: user);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showPopupNotification("Registration successful!", AppColors.primary);
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        });
      } else {
        _showPopupNotification(
          "Registration failed: ${response.detail.isNotEmpty ? response.detail : 'Unknown error'}",
          Colors.redAccent,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Register error: $e\n$stackTrace');
      _showPopupNotification(e.toString(), Colors.redAccent);
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
                              fontSize: MediaQuery.of(context).size.width < 400 ? 24 : 34,
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

                  // Role Selection
                  _isLoadingRoles
                      ? const Center(child: CircularProgressIndicator())
                      : Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: _roles.map((role) {
                            return _UserTypeCheckbox(
                              label: role['name'].toString().toUpperCase(),
                              selected: _selectedRoleId == role['id'],
                              onTap: () => setState(() => _selectedRoleId = role['id']),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 20),

                  // Form fields
                  _buildTextField(_firstNameController, 'First Name', Icons.person),
                  _buildTextField(_lastNameController, 'Last Name', Icons.person_outline),
                  _buildTextField(_emailController, 'Email', Icons.email),
                  _buildPhoneField(),
                  _buildTextField(_locationController, 'Location', Icons.location_on),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
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
            if (digits.startsWith('255')) digits = digits.substring(3);
            if (digits.length > 9) digits = digits.substring(0, 9);

            String formatted = '';
            for (int i = 0; i < digits.length; i++) {
              formatted += digits[i];
              if (i == 2 || i == 5) formatted += ' ';
            }

            _phoneController.text = '+255 $formatted';
            _phoneController.selection = TextSelection.fromPosition(
              TextPosition(offset: _phoneController.text.length),
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
