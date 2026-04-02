import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:morehomesapp/theme/app_color.dart';

class AppDialog {
  static void redirectToInvoice(
    BuildContext context, {
    String message = "You already have an active subscription.",
    required VoidCallback onViewInvoice,
  }) {
    _showSheet(
      context,
      icon: Icons.receipt_long,
      iconColor: AppColors.primary,
      title: "Active Subscription",
      message: message,
      confirmText: "View Invoice",
      onConfirm: onViewInvoice,
    
    );
  }

  static void unlock(
    BuildContext context, {
    required bool isInvoice,
    required VoidCallback onConfirm,
  }) {
    HapticFeedback.lightImpact();

    _showSheet(
      context,
      icon: Icons.lock_outline,
      iconColor: AppColors.primary,
      title: isInvoice ? "Complete Payment" : "Unlock Contact",
      message: isInvoice
          ? "Select a plan to generate your invoice."
          : "Subscribe to a plan to view contact details.",
      confirmText: "Select Plan",
      onConfirm: onConfirm,
    );
  }


static void payment(
  BuildContext context, {
  required String invoiceId,
  required Function(String phone) onPay,
}) {
  final TextEditingController phoneController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom, 
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView( 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Icon(
                    Icons.phone_android,
                    size: 40,
                    color: AppColors.primary,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Enter Phone Number",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "We will send a payment request to your mobile number.",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "2557XXXXXXXX",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () {
                        final phone = phoneController.text.trim();

                        if (phone.isEmpty) return;

                        Navigator.pop(context);
                        onPay(phone);
                      },
                      child: const Text(
                        "Pay Now",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

static void loading(BuildContext context, {String message = "Processing payment..."}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}




  static void loginRequired(
    BuildContext context, {
    required VoidCallback onLogin,
  }) {
    _showSheet(
      context,
      icon: Icons.person_outline,
      iconColor: AppColors.primary,
      title: "Login Required",
      message: "Please login to continue.",
      confirmText: "Login",
      onConfirm: onLogin,
    );
  }

  static void success(
  BuildContext context, {
  String title = "Payment Initiated",
  required String message,
}) {
  _showSheet(
    context,
    icon: Icons.check_circle,
    iconColor: Colors.green,
    title: title,
    message: message,
    confirmText: "Great",
    hideCancel: true,
    onConfirm: () {},
  );
}

static void error(
  BuildContext context, {
  String message = "Something went wrong",
}) {
  _showSheet(
    context,
    icon: Icons.error_outline,
    iconColor: Colors.red,
    title: "Payment Failed",
    message: message,
    confirmText: "Try Again",
    hideCancel: true,
    onConfirm: () {},
  );
}

  
  static void warning(BuildContext context, {required String message}) {
    _showSheet(
      context,
      icon: Icons.warning_amber_outlined,
      iconColor: AppColors.accent,
      title: "Attention",
      message: message,
      confirmText: "OK",
      hideCancel: true,
      onConfirm: () {},
    );
  }

  static void _showSheet(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
    bool hideCancel = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return TweenAnimationBuilder(
          duration: const Duration(milliseconds: 250),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 40 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  /// Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 26, color: iconColor),
                  ),

                  const SizedBox(height: 16),

                  /// Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (!hideCancel) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Not now",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
