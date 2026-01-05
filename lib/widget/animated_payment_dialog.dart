import 'package:flutter/material.dart';
import 'package:morehomesapp/theme/app_color.dart';
import '../models/property_model.dart';


enum DialogType { payment, success, error, warning }

class AnimatedPaymentDialog extends StatefulWidget {
  final PropertyModel property;
  final String message;
  final DialogType type;
  final VoidCallback? onAction;
  final VoidCallback? onCancel;

  const AnimatedPaymentDialog({
    super.key,
    required this.property,
    required this.message,
    required this.type,
    this.onAction,
    this.onCancel,
  });

  @override
  _AnimatedPaymentDialogState createState() => _AnimatedPaymentDialogState();
}

class _AnimatedPaymentDialogState extends State<AnimatedPaymentDialog>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    String title;
    IconData icon;
    Color color;

    switch (widget.type) {
      case DialogType.payment:
        title = "Payment Required";
        icon = Icons.payment;
        color = AppColors.primary;
        break;
      case DialogType.success:
        title = "Success";
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case DialogType.error:
        title = "Error";
        icon = Icons.error;
        color = Colors.red;
        break;
      case DialogType.warning:
        title = "Warning";
        icon = Icons.warning;
        color = Colors.red;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: Icon(icon, color: color, size: 64),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onCancel ?? () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      widget.type == DialogType.payment
                          ? "Pay Now"
                          : widget.type == DialogType.success
                              ? "Continue"
                              : "Ok",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
