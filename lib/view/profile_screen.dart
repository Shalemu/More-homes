import 'package:flutter/material.dart';
import 'package:morehomesapp/view/about_app_screen.dart';
import 'package:morehomesapp/view/change_password_screen.dart';
import 'package:morehomesapp/view/help_support_screen.dart';
import 'package:morehomesapp/view/invoice_screen%20.dart';
import 'package:morehomesapp/view/payment_history.dart';
import 'package:morehomesapp/view/privacy_policy_screen.dart';
import 'package:morehomesapp/view/subscription_payment.dart';
import 'package:provider/provider.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'my_properties_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const int GROUP_OWNER = 3;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Menu item helper with animation
    Widget _profileMenuItem({
      required IconData icon,
      required String text,
      VoidCallback? onTap,
      bool requiresLogin = false,
    }) {
      return StatefulBuilder(
        builder: (context, setState) {
          double scale = 1.0;

          return GestureDetector(
            onTapDown: (_) => setState(() => scale = 0.95),
            onTapUp: (_) => setState(() => scale = 1.0),
            onTapCancel: () => setState(() => scale = 1.0),
            onTap: () {
              if (requiresLogin && !authProvider.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please login to access this feature."),
                  ),
                );
                return;
              }

              if (onTap != null) {
                onTap();
                return;
              }

              // Special case for Subscription Payments
              if (text == "Subscription Payments") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SubscriptionScreen()),
                );
              }
            },
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(icon, color: AppColors.primary),
                ),
                title: Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        },
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/home');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
    
        body: SafeArea(
          child: user == null
              ? const Center(child: Text("No user data available"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // Profile Picture with Edit Button
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 55,
                                backgroundImage: user.profilePictureUrl != null
                                    ? NetworkImage(user.profilePictureUrl!)
                                    : const AssetImage(
                                            'assets/images/profile_placeholder.png',
                                          )
                                          as ImageProvider,
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Name & Email
                          Text(
                            "${user.firstName} ${user.lastName}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                   
                          const SizedBox(height: 20),

                          // Profile menu section
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _profileMenuItem(
                                  icon: Icons.person_outline,
                                  text: "Edit Profile",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                         
                                _profileMenuItem(
                                  icon: Icons.info_outline,
                                  text: "About App",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AboutAppScreen(),
                                      ),
                                    );
                                  },
                                ),

                                _profileMenuItem(
                                  icon: Icons.help_outline,
                                  text: "Help & Support",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const HelpSupportScreen(),
                                      ),
                                    );
                                  },
                                ),

                                _profileMenuItem(
                                  icon: Icons.lock_outline,
                                  text: "Change Password",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ChangePasswordScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _profileMenuItem(
                                  icon: Icons.privacy_tip_outlined,
                                  text: "Privacy & Policy",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PrivacyPolicyScreen(),
                                      ),
                                    );
                                  },
                                ),

                                _profileMenuItem(
                                  icon: Icons.delete_outline,
                                  text: "Delete Account",
                                ),
                                _profileMenuItem(
                                  icon: Icons.payment_outlined,
                                  text: "Subscription Payments",
                                  requiresLogin: true,
                                  onTap: () {
                                    Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubscriptionScreen(
                                         
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _profileMenuItem(
                                  icon: Icons.history,
                                  text: "Payment History",
                                  requiresLogin: true,
                                  onTap: () {
                                    Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PaymentHistoryScreen(
                                         
                                        ),
                                      ),
                                    );
                                  },
                                ),

                        
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // My Properties button (only for Owner)
                          if (user.groups.contains(GROUP_OWNER)) ...[
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(double.infinity, 55),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyPropertiesScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.home_work_outlined),
                              label: const Text(
                                "My Properties",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 30),

                          // Logout button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 55),
                            ),
                            onPressed: () {
                              authProvider.logout();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text(
                              "Sign Out",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
